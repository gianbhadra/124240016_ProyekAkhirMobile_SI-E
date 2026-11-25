import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import 'blockchain.dart';
import 'db_helper.dart';
import 'supabase_service.dart';

class AppUser {
  final String name, username, email;
  const AppUser(this.name, this.username, this.email);
}

/// State aplikasi. Data akun, saldo, aset, watchlist, blockchain, skor, dan
/// saran/kesan disimpan di SQLite (lihat db_helper.dart).
/// SharedPreferences menyimpan session, pengaturan biometrik, dan path foto profil.
///
/// TODO (tahap database online): sinkronkan tabel-tabel ini ke Supabase /
/// backend. Titik sambungnya ada di fungsi register, trade, saveScore, addFeedback.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const double initialBalance = 100000000;

  late SharedPreferences _p;
  Future<Database> get _db => DbHelper.instance.db;

  int? _uid;
  AppUser? user;
  double balance = initialBalance;
  Map<String, double> holdings = {};
  Set<String> watchlist = {};
  List<Block> chain = [];
  int bestScore = 0;
  bool biometricEnabled = false;
  String? profileImagePath;
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> feedbacks = [];
  bool tampered = false;
  bool syncing = false;
  String syncMessage =
      SupabaseService.enabled ? 'Belum disinkronkan' : 'Supabase belum diatur';

  bool get hasSession => user != null;
  String? get lastUser => _p.getString('last_user');

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final s = _p.getString('session');
    if (s != null && !await _load(s)) await _p.remove('session');
  }

  // ---------- Akun & keamanan ----------
  String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  /// Hash password = SHA-256 diulang 5000x dengan salt acak per pengguna.
  String _hash(String salt, String pw) {
    final d = utf8.encode('$salt$pw');
    var h = sha256.convert(d);
    for (var i = 0; i < 5000; i++) {
      h = sha256.convert([...h.bytes, ...d]);
    }
    return h.toString();
  }

  Future<void> _insertBlock(DatabaseExecutor ex, int uid, Block b) =>
      ex.insert('blockchain', {
        'user_id': uid,
        'idx': b.index,
        'data': b.data,
        'timestamp': b.timestamp,
        'prev_hash': b.prevHash,
        'nonce': b.nonce,
        'hash': b.hash,
      });

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> register(
      String name, String username, String email, String pw) async {
    final db = await _db;
    final u = username.trim().toLowerCase();
    final e = email.trim().toLowerCase();
    if ((await db.query('users',
            where: 'username = ?', whereArgs: [u], limit: 1))
        .isNotEmpty) {
      return 'Username sudah dipakai';
    }
    if ((await db.query('users', where: 'email = ?', whereArgs: [e], limit: 1))
        .isNotEmpty) {
      return 'Email sudah terdaftar';
    }
    final salt = _salt();
    final genesis = Block.genesis();
    await db.transaction((txn) async {
      final id = await txn.insert('users', {
        'username': u,
        'name': name.trim(),
        'email': e,
        'salt': salt,
        'password_hash': _hash(salt, pw),
        'balance': initialBalance,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      for (final s in ['BTC', 'ETH', 'SOL']) {
        await txn.insert('watchlist', {'user_id': id, 'symbol': s});
      }
      await _insertBlock(txn, id, genesis);
    });
    unawaited(syncUp(u));
    return null;
  }

  Future<String?> login(String id, String pw) async {
    final key = id.trim().toLowerCase();
    final db = await _db;
    final rows = await db.query('users',
        where: 'username = ? OR email = ?', whereArgs: [key, key], limit: 1);
    if (rows.isEmpty) {
      return _loginFromCloud(
          key, pw); // akun belum ada di HP ini: cari di server
    }
    final r = rows.first;
    if (_hash(r['salt'] as String, pw) != r['password_hash']) {
      return 'Password salah';
    }
    await _startSession(r['username'] as String);
    return null;
  }

  Future<bool> _startSession(String u) async {
    if (!await _load(u)) return false;
    await _p.setString('session', u);
    await _p.setString('last_user', u);
    notifyListeners();
    unawaited(syncUp());
    return true;
  }

  bool biometricEnabledFor(String username) =>
      _p.getBool('bio_$username') ?? false;

  /// Dipanggil setelah sidik jari berhasil diverifikasi di layar login.
  Future<bool> loginWithBiometricSession() async {
    final u = lastUser;
    if (u == null || !biometricEnabledFor(u)) return false;
    return _startSession(u);
  }

  Future<void> logout() async {
    await _p.remove('session');
    user = null;
    _uid = null;
    profileImagePath = null;
    notifyListeners();
  }

  // ---------- Muat data pengguna dari SQLite ----------
  Future<bool> _load(String username) async {
    final db = await _db;
    final rows = await db.query('users',
        where: 'username = ?', whereArgs: [username], limit: 1);
    if (rows.isEmpty) return false;
    final r = rows.first;
    final id = r['id'] as int;
    _uid = id;
    user = AppUser(r['name'] as String, username, r['email'] as String);
    balance = (r['balance'] as num).toDouble();
    profileImagePath = _p.getString('profile_image_$username');

    holdings = {
      for (final h
          in await db.query('holdings', where: 'user_id = ?', whereArgs: [id]))
        h['symbol'] as String: (h['qty'] as num).toDouble()
    };
    watchlist =
        (await db.query('watchlist', where: 'user_id = ?', whereArgs: [id]))
            .map((e) => e['symbol'] as String)
            .toSet();
    chain = (await db.query('blockchain',
            where: 'user_id = ?', whereArgs: [id], orderBy: 'idx ASC'))
        .map(Block.fromRow)
        .toList();
    if (chain.isEmpty) {
      final g = Block.genesis();
      await _insertBlock(db, id, g);
      chain = [g];
    }
    bestScore = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT MAX(skor) FROM skor_game WHERE user_id = ?', [id])) ??
        0;
    feedbacks = (await db.query('saran_kesan',
            where: 'user_id = ?', whereArgs: [id], orderBy: 'waktu DESC'))
        .map((e) => {
              'rating': e['rating'],
              'category': e['kategori'],
              'kesan': e['kesan'],
              'saran': e['saran'],
              'time': e['waktu'],
            })
        .toList();
    expenses = List<Map<String, dynamic>>.of(await db.query('expenses',
        where: 'user_id = ?', whereArgs: [id], orderBy: 'waktu DESC'));
    biometricEnabled = biometricEnabledFor(username);
    tampered = false;
    return true;
  }

  // ---------- Fitur ----------
  double totalValue(List<Coin> coins) {
    var total = balance;
    holdings.forEach((sym, qty) {
      final c = coins.where((c) => c.symbol == sym);
      if (c.isNotEmpty) total += qty * c.first.price;
    });
    return total;
  }

  Future<void> toggleWatch(String symbol) async {
    final db = await _db;
    if (watchlist.contains(symbol)) {
      await db.delete('watchlist',
          where: 'user_id = ? AND symbol = ?', whereArgs: [_uid, symbol]);
      watchlist.remove(symbol);
    } else {
      await db.insert('watchlist', {'user_id': _uid, 'symbol': symbol},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      watchlist.add(symbol);
    }
    notifyListeners();
  }

  Future<String?> trade(Coin c, bool buy, double rupiah) async {
    if (rupiah <= 0) return 'Masukkan nominal lebih dari 0';
    if (tampered) {
      await _load(user!.username); // pulihkan rantai sebelum transaksi baru
    }
    final qty = rupiah / c.price;
    if (buy) {
      if (rupiah > balance) return 'Saldo virtual tidak cukup';
      balance -= rupiah;
      holdings[c.symbol] = (holdings[c.symbol] ?? 0) + qty;
    } else {
      final have = holdings[c.symbol] ?? 0;
      if (qty > have + 1e-12) return 'Aset ${c.symbol} tidak cukup';
      balance += rupiah;
      holdings[c.symbol] = have - qty;
    }
    final block = Block.mine(
      index: chain.length,
      data: jsonEncode({
        'type': buy ? 'buy' : 'sell',
        'symbol': c.symbol,
        'qty': qty,
        'rupiah': rupiah
      }),
      prevHash: chain.last.hash,
    );
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('users', {'balance': balance},
          where: 'id = ?', whereArgs: [_uid]);
      await txn.insert('holdings',
          {'user_id': _uid, 'symbol': c.symbol, 'qty': holdings[c.symbol]},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _insertBlock(txn, _uid!, block);
    });
    chain.add(block);
    notifyListeners();
    unawaited(syncUp());
    return null;
  }

  Future<void> resetBalance() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('users', {'balance': initialBalance},
          where: 'id = ?', whereArgs: [_uid]);
      await txn.delete('holdings', where: 'user_id = ?', whereArgs: [_uid]);
    });
    balance = initialBalance;
    holdings = {};
    notifyListeners();
  }

  Future<void> setBiometric(bool v) async {
    await _p.setBool('bio_${user!.username}', v);
    biometricEnabled = v;
    notifyListeners();
  }

  Future<void> setProfileImagePath(String? path) async {
    final username = user!.username;
    if (path == null) {
      await _p.remove('profile_image_$username');
    } else {
      await _p.setString('profile_image_$username', path);
    }
    profileImagePath = path;
    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final db = await _db;
    final row = {
      'user_id': _uid,
      'amount': amount,
      'category': category,
      'note': note.trim(),
      'waktu': date.millisecondsSinceEpoch,
    };
    final id = await db.insert('expenses', row);
    expenses.insert(0, {'id': id, ...row});
    notifyListeners();
  }

  Future<bool> updateExpense({
    required int id,
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final db = await _db;
    final values = {
      'amount': amount,
      'category': category,
      'note': note.trim(),
      'waktu': date.millisecondsSinceEpoch,
    };
    final updated = await db.update(
      'expenses',
      values,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _uid],
    );
    if (updated == 0) return false;

    final index = expenses.indexWhere((expense) => expense['id'] == id);
    if (index >= 0) {
      expenses[index] = {...expenses[index], ...values};
      expenses.sort(
        (a, b) => (b['waktu'] as int).compareTo(a['waktu'] as int),
      );
    }
    notifyListeners();
    return true;
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db;
    await db.delete('expenses',
        where: 'id = ? AND user_id = ?', whereArgs: [id, _uid]);
    expenses = expenses.where((expense) => expense['id'] != id).toList();
    notifyListeners();
  }

  Future<void> saveScore(int score) async {
    final db = await _db;
    await db.insert('skor_game', {
      'user_id': _uid,
      'skor': score,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });
    if (score > bestScore) bestScore = score;
    notifyListeners();
    unawaited(syncUp());
  }

  Future<void> addFeedback(
      int rating, String category, String kesan, String saran) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    await db.insert('saran_kesan', {
      'user_id': _uid,
      'rating': rating,
      'kategori': category,
      'kesan': kesan,
      'saran': saran,
      'waktu': now,
    });
    feedbacks.insert(0, {
      'rating': rating,
      'category': category,
      'kesan': kesan,
      'saran': saran,
      'time': now
    });
    notifyListeners();
    unawaited(syncUp());
  }

  // ---------- Sinkronisasi ke Supabase ----------
  String _clock() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  /// Kirim semua data lokal pengguna ke Supabase (baris yang sudah ada diabaikan).
  Future<bool> syncUp([String? username]) async {
    if (!SupabaseService.enabled) return false;
    final uname = username ?? user?.username;
    if (uname == null) return false;
    syncing = true;
    notifyListeners();
    var ok = false;
    try {
      final db = await _db;
      final rows = await db.query('users',
          where: 'username = ?', whereArgs: [uname], limit: 1);
      if (rows.isNotEmpty) {
        final u = rows.first;
        final id = u['id'] as int;
        ok = await SupabaseService.upsertIgnore(
            'users',
            [
              {
                'username': uname,
                'name': u['name'],
                'email': u['email'],
                'salt': u['salt'],
                'password_hash': u['password_hash'],
              }
            ],
            'username');
        if (ok) {
          final blocks = await db.query('blockchain',
              where: 'user_id = ?', whereArgs: [id], orderBy: 'idx ASC');
          ok = await SupabaseService.upsertIgnore(
            'blockchain',
            blocks
                .map((b) => {
                      'username': uname,
                      'idx': b['idx'],
                      'data': b['data'],
                      'ts': b['timestamp'],
                      'prev_hash': b['prev_hash'],
                      'nonce': b['nonce'],
                      'hash': b['hash'],
                    })
                .toList(),
            'username,idx',
          );
        }
        if (ok) {
          final scores = await db
              .query('skor_game', where: 'user_id = ?', whereArgs: [id]);
          ok = await SupabaseService.upsertIgnore(
            'skor_game',
            scores
                .map((e) =>
                    {'username': uname, 'skor': e['skor'], 'waktu': e['waktu']})
                .toList(),
            'username,waktu',
          );
        }
        if (ok) {
          final notes = await db
              .query('saran_kesan', where: 'user_id = ?', whereArgs: [id]);
          ok = await SupabaseService.upsertIgnore(
            'saran_kesan',
            notes
                .map((e) => {
                      'username': uname,
                      'rating': e['rating'],
                      'kategori': e['kategori'],
                      'kesan': e['kesan'],
                      'saran': e['saran'],
                      'waktu': e['waktu'],
                    })
                .toList(),
            'username,waktu',
          );
        }
      }
    } catch (e) {
      ok = false;
      SupabaseService.lastError = 'kesalahan: $e';
    }
    syncing = false;
    syncMessage = ok
        ? 'Tersinkron pukul ${_clock()}'
        : 'Gagal sinkron: ${SupabaseService.lastError}';
    notifyListeners();
    return ok;
  }

  /// Login di HP baru: ambil akun dari server, cek password, lalu pulihkan data.
  Future<String?> _loginFromCloud(String key, String pw) async {
    if (!SupabaseService.enabled) return 'Akun tidak ditemukan';
    var rows = await SupabaseService.select(
        'users', {'username': 'eq.$key', 'limit': '1'});
    if (rows != null && rows.isEmpty) {
      rows = await SupabaseService.select(
          'users', {'email': 'eq.$key', 'limit': '1'});
    }
    if (rows == null) {
      return 'Akun tidak ada di HP ini dan server tidak bisa dihubungi';
    }
    if (rows.isEmpty) return 'Akun tidak ditemukan';
    final r = rows.first;
    if (_hash(r['salt'] as String, pw) != r['password_hash']) {
      return 'Password salah';
    }
    await _restoreFromCloud(r);
    await _startSession(r['username'] as String);
    return null;
  }

  Future<void> _restoreFromCloud(Map<String, dynamic> r) async {
    final db = await _db;
    final username = r['username'] as String;
    final blocks = await SupabaseService.select(
            'blockchain', {'username': 'eq.$username', 'order': 'idx.asc'}) ??
        [];
    final scores = await SupabaseService.select(
            'skor_game', {'username': 'eq.$username'}) ??
        [];
    final notes = await SupabaseService.select(
            'saran_kesan', {'username': 'eq.$username'}) ??
        [];

    // Saldo dan aset dihitung ulang dari riwayat transaksi di blockchain.
    var bal = initialBalance;
    final hold = <String, double>{};
    for (final b in blocks) {
      try {
        final d = jsonDecode(b['data'] as String) as Map<String, dynamic>;
        final rp = (d['rupiah'] as num).toDouble();
        final q = (d['qty'] as num).toDouble();
        final sym = d['symbol'] as String;
        if (d['type'] == 'buy') {
          bal -= rp;
          hold[sym] = (hold[sym] ?? 0) + q;
        } else {
          bal += rp;
          hold[sym] = (hold[sym] ?? 0) - q;
        }
      } catch (_) {} // blok genesis bukan transaksi
    }

    await db.transaction((txn) async {
      final id = await txn.insert('users', {
        'username': username,
        'name': r['name'],
        'email': r['email'],
        'salt': r['salt'],
        'password_hash': r['password_hash'],
        'balance': bal,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      for (final s in ['BTC', 'ETH', 'SOL']) {
        await txn.insert('watchlist', {'user_id': id, 'symbol': s});
      }
      for (final b in blocks) {
        await txn.insert('blockchain', {
          'user_id': id,
          'idx': b['idx'],
          'data': b['data'],
          'timestamp': b['ts'],
          'prev_hash': b['prev_hash'],
          'nonce': b['nonce'],
          'hash': b['hash'],
        });
      }
      if (blocks.isEmpty) await _insertBlock(txn, id, Block.genesis());
      for (final e in hold.entries) {
        if (e.value > 1e-12) {
          await txn.insert(
              'holdings', {'user_id': id, 'symbol': e.key, 'qty': e.value});
        }
      }
      for (final s in scores) {
        await txn.insert('skor_game',
            {'user_id': id, 'skor': s['skor'], 'waktu': s['waktu']});
      }
      for (final n in notes) {
        await txn.insert('saran_kesan', {
          'user_id': id,
          'rating': n['rating'],
          'kategori': n['kategori'],
          'kesan': n['kesan'],
          'saran': n['saran'],
          'waktu': n['waktu'],
        });
      }
    });
  }

  // ---------- Blockchain ----------
  List<bool> validity() {
    final res = <bool>[];
    for (var i = 0; i < chain.length; i++) {
      final b = chain[i];
      var ok = b.hash == b.computeHash();
      if (i > 0 && b.prevHash != chain[i - 1].hash) ok = false;
      if (res.isNotEmpty && !res.last) {
        ok = false; // blok setelah blok rusak ikut tidak valid
      }
      res.add(ok);
    }
    return res;
  }

  bool get chainValid => validity().every((v) => v);

  /// Untuk demo/pengujian: ubah data satu blok di memori TANPA menghitung ulang hash.
  /// Database tidak disentuh, jadi tombol "Pulihkan" cukup memuat ulang dari SQLite.
  void tamperChain() {
    if (chain.length < 2) return;
    chain[1].data = chain[1].data.replaceFirst('"rupiah":', '"rupiah":9');
    tampered = true;
    notifyListeners();
  }

  Future<void> restoreChain() async {
    if (user == null) return;
    await _load(user!.username);
    notifyListeners();
  }
}

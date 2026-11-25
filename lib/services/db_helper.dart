import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database lokal SQLite (file: coinwise.db di penyimpanan aplikasi).
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'coinwise.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            balance REAL NOT NULL,
            created_at INTEGER NOT NULL
          )''');
        await d.execute('''
          CREATE TABLE holdings(
            user_id INTEGER NOT NULL,
            symbol TEXT NOT NULL,
            qty REAL NOT NULL,
            PRIMARY KEY(user_id, symbol),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE watchlist(
            user_id INTEGER NOT NULL,
            symbol TEXT NOT NULL,
            PRIMARY KEY(user_id, symbol),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE blockchain(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            idx INTEGER NOT NULL,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            prev_hash TEXT NOT NULL,
            nonce INTEGER NOT NULL,
            hash TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE skor_game(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            skor INTEGER NOT NULL,
            waktu INTEGER NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE saran_kesan(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            rating INTEGER NOT NULL,
            kategori TEXT NOT NULL,
            kesan TEXT NOT NULL,
            saran TEXT NOT NULL,
            waktu INTEGER NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        // Cache API (harga kripto & kurs) agar tetap tampil saat offline.
        await d.execute('''
          CREATE TABLE cache(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated INTEGER NOT NULL
          )''');
        await d.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT NOT NULL,
            waktu INTEGER NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await d.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              note TEXT NOT NULL,
              waktu INTEGER NOT NULL,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )''');
        }
      },
    );
  }

  Future<void> putCache(String key, String value) async {
    try {
      final d = await db;
      await d.insert(
        'cache',
        {
          'key': key,
          'value': value,
          'updated': DateTime.now().millisecondsSinceEpoch
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<String?> getCache(String key) async {
    try {
      final d = await db;
      final r =
          await d.query('cache', where: 'key = ?', whereArgs: [key], limit: 1);
      return r.isEmpty ? null : r.first['value'] as String;
    } catch (_) {
      return null;
    }
  }
}

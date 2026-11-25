import 'dart:convert';
import 'package:http/http.dart' as http;

/// Web service ke Supabase lewat REST (PostgREST). TIDAK memakai Supabase Auth.
/// Isi lewat: --dart-define=SUPABASE_URL=https://xxxx.supabase.co
///            --dart-define=SUPABASE_KEY=sb_publishable_xxxx
class SupabaseService {
  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nnhxekparuoholljhlwe.supabase.co',
  );
  static const _key = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_AkognUBq-UEmxCB3jq4guw_E1Pck8GN',
  );
  static bool get enabled => _url.isNotEmpty && _key.isNotEmpty;

  /// Pesan error terakhir (untuk membantu debugging).
  static String lastError = '';

  static Map<String, String> get _headers => {
        'apikey': _key,
        'Content-Type': 'application/json',
      };

  static Uri _uri(String table, [Map<String, String>? query]) {
    final base = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
    return Uri.parse('$base/rest/v1/$table').replace(queryParameters: query);
  }

  /// Kirim banyak baris. Baris yang sudah ada diabaikan (aman dipanggil berulang).
  static Future<bool> upsertIgnore(
      String table, List<Map<String, dynamic>> rows, String conflict) async {
    if (!enabled) {
      lastError = 'Supabase belum diatur';
      return false;
    }
    if (rows.isEmpty) return true;
    try {
      final r = await http
          .post(
            _uri(table, {'on_conflict': conflict}),
            headers: {..._headers, 'Prefer': 'resolution=ignore-duplicates,return=minimal'},
            body: jsonEncode(rows),
          )
          .timeout(const Duration(seconds: 10));
      if (r.statusCode >= 200 && r.statusCode < 300) return true;
      lastError = '$table ${r.statusCode}: ${r.body}';
      return false;
    } catch (e) {
      lastError = 'tidak bisa terhubung ($table)';
      return false;
    }
  }

  /// Ambil data. Mengembalikan null jika gagal (offline / salah konfigurasi).
  static Future<List<Map<String, dynamic>>?> select(String table, Map<String, String> query) async {
    if (!enabled) {
      lastError = 'Supabase belum diatur';
      return null;
    }
    try {
      final r = await http.get(_uri(table, query), headers: _headers).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) {
        lastError = '$table ${r.statusCode}: ${r.body}';
        return null;
      }
      return (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      lastError = 'tidak bisa terhubung ($table)';
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> leaderboard() =>
      select('skor_game', {'select': 'username,skor', 'order': 'skor.desc', 'limit': '100'});
}

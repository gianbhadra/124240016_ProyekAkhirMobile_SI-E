import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Chatbot edukasi memakai Gemini API.
/// Jalankan dengan: flutter run --dart-define-from-file=secrets.json
/// Tanpa key, aplikasi memakai jawaban contoh supaya demo tetap jalan.
class AiService {
  static const _buildKey = String.fromEnvironment('GEMINI_KEY');
  static final _client = GeminiApiClient(apiKey: _buildKey);

  static bool get hasKey => _buildKey.trim().isNotEmpty;

  static Future<String> ask(String question) => _client.ask(question);
}

class GeminiApiClient {
  GeminiApiClient({
    required String apiKey,
    http.Client? client,
    Future<void> Function(Duration)? delay,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _delay = delay ?? _wait;

  static const _models = [
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
  ];

  static const _system =
      'Kamu CoinWise Tutor, asisten edukasi keuangan dan kripto untuk pelajar '
      'dan mahasiswa Indonesia. Jawab dalam bahasa Indonesia yang ringkas, '
      'pakai analogi sederhana, maksimal 120 kata. Gunakan paragraf pendek '
      'dan daftar bila membantu; pakai **tebal** hanya untuk istilah penting. '
      'Langsung jawab pertanyaan tanpa salam atau perkenalan berulang. Jangan '
      'memberi saran investasi pribadi; ingatkan bahwa ini bersifat edukasi.';

  final String _apiKey;
  final http.Client _client;
  final Future<void> Function(Duration) _delay;

  static Future<void> _wait(Duration duration) =>
      Future<void>.delayed(duration);

  Future<String> ask(String question) async {
    if (_apiKey.trim().isEmpty) {
      return 'Mode contoh (belum ada GEMINI_KEY). Blockchain adalah buku catatan '
          'digital yang disalin ke banyak komputer. Tiap halaman (blok) terkunci '
          'dengan hash ke halaman sebelumnya, jadi mengubah satu catatan akan '
          'ketahuan. Ini hanya edukasi, bukan saran investasi.';
    }
    var lastFailure = 'Model Gemini tidak mengembalikan jawaban.';
    var retryCount = 0;
    for (var modelIndex = 0; modelIndex < _models.length; modelIndex++) {
      final model = _models[modelIndex];
      try {
        final response = await _client
            .post(
              Uri.parse(
                  'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _apiKey.trim(),
              },
              body: jsonEncode({
                'systemInstruction': {
                  'parts': [
                    {'text': _system}
                  ]
                },
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': question}
                    ]
                  }
                ],
                'generationConfig': {
                  'maxOutputTokens': 500,
                },
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          lastFailure = _errorMessage(response);

          if (response.statusCode == 401 || response.statusCode == 403) {
            return 'Gemini gagal: $lastFailure. Periksa API key dan izinnya.';
          }
          if (_isTransient(response.statusCode) &&
              modelIndex < _models.length - 1) {
            await _delay(Duration(seconds: 1 << retryCount));
            retryCount++;
          }
          continue;
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = payload['candidates'] as List<dynamic>?;
        final content = candidates != null && candidates.isNotEmpty
            ? candidates.first as Map<String, dynamic>?
            : null;
        final parts = (content?['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>?;
        final text = parts
            ?.whereType<Map<String, dynamic>>()
            .where((part) => part['text'] is String)
            .map((part) => part['text'] as String)
            .join('\n')
            .trim();
        if (text != null && text.isNotEmpty) return text;
        lastFailure = 'model tidak mengembalikan teks.';
      } on TimeoutException {
        lastFailure = 'waktu koneksi habis.';
        if (modelIndex < _models.length - 1) {
          await _delay(Duration(seconds: 1 << retryCount));
          retryCount++;
        }
      } on http.ClientException catch (error) {
        lastFailure = 'masalah jaringan: $error';
      } on FormatException {
        lastFailure = 'respons API tidak terbaca.';
      } on TypeError {
        lastFailure = 'format respons API tidak sesuai.';
      }
    }
    return 'Semua model Gemini gagal dicoba '
        '(${_models.join(', ')}). Terakhir: $lastFailure';
  }

  bool _isTransient(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;

  String _errorMessage(http.Response response) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic>) {
        final error = payload['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return 'HTTP ${response.statusCode}: $message';
          }
        }
      }
    } on FormatException {
      return 'HTTP ${response.statusCode}';
    }
    return 'HTTP ${response.statusCode}';
  }
}

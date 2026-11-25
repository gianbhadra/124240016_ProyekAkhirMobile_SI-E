import 'dart:convert';
import 'package:coinwise/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('backs off across transient errors and returns the first Gemini answer',
      () async {
    final models = <String>[];
    final delays = <Duration>[];
    final client = MockClient((request) async {
      models.add(request.url.pathSegments[2]);
      if (models.length < 3) {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'This model is currently experiencing high demand.'
            }
          }),
          503,
        );
      }
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Blockchain adalah catatan transaksi bersama.'}
                ]
              }
            }
          ]
        }),
        200,
      );
    });
    final service = GeminiApiClient(
      apiKey: 'test-key',
      client: client,
      delay: (duration) async => delays.add(duration),
    );

    final answer = await service.ask('Apa itu blockchain?');
    client.close();

    expect(answer, 'Blockchain adalah catatan transaksi bersama.');
    expect(models, [
      'gemini-3.8-flash:generateContent',
      'gemini-3.6-flash:generateContent',
      'gemini-3.5-flash-lite:generateContent',
    ]);
    expect(delays, [const Duration(seconds: 1), const Duration(seconds: 2)]);
  });
}

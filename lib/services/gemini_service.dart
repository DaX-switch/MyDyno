import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _st = FlutterSecureStorage();
  static Future<String?> key() => _st.read(key: 'gemini_key');
  static Future<void> setKey(String k) => k.trim().isEmpty
      ? _st.delete(key: 'gemini_key')
      : _st.write(key: 'gemini_key', value: k.trim());

  static Future<String> ask(String prompt) async {
    final k = await key();
    if (k == null || k.isEmpty) {
      throw 'Brak klucza API Gemini – dodaj go w Ustawieniach ⚙️.';
    }

    // Sprawdzamy po kolei modele z tej samej rodziny
    final models = [
      'gemini-3.8-flash',
      'gemini-3.8-pro',
      'gemini-3.8-flash-lite',
    ];

    String lastErr = '';

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$k',
        );

        final res = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ]
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          return (j['candidates'][0]['content']['parts'][0]['text'] as String).trim();
        }

        // Jeśli 503 lub 429, przeskakujemy od razu do następnego modelu
        if (res.statusCode == 503 || res.statusCode == 429) {
          lastErr = 'Model $model przeciążony (503).';
          continue;
        }

        final errJson = jsonDecode(res.body);
        final msg = errJson['error']?['message'] ?? res.body;
        lastErr = 'Błąd $model: $msg';
      } catch (e) {
        lastErr = e.toString();
      }
    }

    throw 'Serwery są obecnie mocno obciążone. Spróbuj za chwilę lub włącz Billing w AI Studio.';
  }
}

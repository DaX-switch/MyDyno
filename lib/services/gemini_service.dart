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

    // Lista sprawdzonych modeli do wypróbowania w kolejności
    final candidates = [
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$k',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$k',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$k',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$k',
    ];

    String lastErr = '';

    for (final urlStr in candidates) {
      try {
        final res = await http
            .post(
              Uri.parse(urlStr),
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
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          return (j['candidates'][0]['content']['parts'][0]['text'] as String).trim();
        } else {
          lastErr = 'HTTP ${res.statusCode}: ${res.body}';
        }
      } catch (e) {
        lastErr = e.toString();
      }
    }

    throw 'Błąd Gemini: $lastErr';
  }
}

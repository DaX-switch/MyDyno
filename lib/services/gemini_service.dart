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

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$k',
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

    if (res.statusCode != 200) {
      try {
        final errJson = jsonDecode(res.body);
        final msg = errJson['error']?['message'] ?? res.body;
        throw 'Błąd Gemini (${res.statusCode}): $msg';
      } catch (_) {
        throw 'Błąd Gemini (${res.statusCode}): ${res.body}';
      }
    }

    final j = jsonDecode(res.body);
    return (j['candidates'][0]['content']['parts'][0]['text'] as String).trim();
  }
}

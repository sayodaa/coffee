import 'dart:convert';

import 'package:coffee_app/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final http.Client _client;

  GeminiService({http.Client? client})
      : _client = client ?? http.Client();

  Future<String> sendMessage(String message) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${ApiConfig.GeminiApiKey}',
    );

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ]
        }),
      );

      print('STATUS = ${response.statusCode}');
      print('BODY = ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body);

      return data['candidates'][0]['content']['parts'][0]['text'] ??
          'No response';
    } catch (e) {
      throw Exception('Gemini Error: $e');
    }
  }
}
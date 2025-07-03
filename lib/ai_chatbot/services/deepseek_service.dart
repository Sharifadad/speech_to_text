import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  static final String? _apiKey = dotenv.env['sk-73c0fc9d243447d4b0aeedbf1bd8dc90'];
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  Future<String> getResponse(String prompt) async {
    if (_apiKey == null) {
      throw Exception('API key not found. Please configure DEEPSEEK_API_KEY in your .env file.');
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to load response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with DeepSeek API: $e');
    }
  }
}
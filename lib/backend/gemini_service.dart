import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// Wrapper around Google Gemini Generative AI REST API.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generates text from a prompt.
  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
      '$_baseUrl/gemini-1.5-pro:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';

    final parts = (candidates[0]['content']['parts'] as List?) ?? [];
    return parts.map((p) => p['text'] ?? '').join();
  }

  /// Analyzes an image with a text prompt.
  Future<String> analyzeImage({
    required String prompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/gemini-1.5-pro:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini Vision API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';

    final parts = (candidates[0]['content']['parts'] as List?) ?? [];
    return parts.map((p) => p['text'] ?? '').join();
  }
}

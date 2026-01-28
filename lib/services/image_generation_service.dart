import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kresai/config/api_config.dart';

/// Image Generation Service using Gemini Imagen (Nanobanana)
class ImageGenerationService {
  final String _apiKey;

  ImageGenerationService() : _apiKey = ApiConfig.geminiApiKey;

  /// Generate a single image from text prompt
  Future<String> generateImage(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.95,
      }
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Image generation failed: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No image generated');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) {
      throw Exception('No content in response');
    }
    
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('No parts in response');
    }

    // Gemini returns inline_data with mime_type and data
    final inlineData = parts[0]['inline_data'] as Map<String, dynamic>?;
    if (inlineData != null) {
      final imageData = inlineData['data'] as String?;
      final mimeType = inlineData['mime_type'] as String?;
      if (imageData != null) {
        return 'data:$mimeType;base64,$imageData';
      }
    }

    throw Exception('No image data in response');
  }

  /// Generate multiple images in parallel for question choices
  Future<List<String>> generateImagesForChoices(List<String> choiceTexts) async {
    final futures = choiceTexts.map((text) {
      // Create child-friendly prompt
      final prompt = 'Simple, colorful, cartoon-style illustration of: $text. '
          'Suitable for children, bright colors, clear subject, white background.';
      return generateImage(prompt);
    }).toList();

    try {
      return await Future.wait(futures);
    } catch (e) {
      // If any image fails, return empty list to fallback to text-only
      print('Image generation error: $e');
      return [];
    }
  }
}

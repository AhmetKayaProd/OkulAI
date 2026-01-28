import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kresai/models/program.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/services/ai_config_store.dart';

/// AI Schedule Service - Gemini API Integration
/// Handles program parsing and daily plan generation
class AiScheduleService {
  static final AiScheduleService _instance = AiScheduleService._internal();
  factory AiScheduleService() => _instance;
  AiScheduleService._internal();

  static const String _geminiApiBase = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';
  
  final _configStore = AiConfigStore();
  DateTime? _lastApiCall;
  static const _minCallInterval = Duration(seconds: 10); // Rate limit

  /// Check if API is configured
  bool get isConfigured => _configStore.hasApiKey;

  /// Parse raw program text into structured blocks
  Future<List<ProgramBlock>> parseProgram({
    required String rawText,
    required PeriodType periodType,
    required SchoolType schoolType,
    required String templateId,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured');
    }

    // Rate limiting
    if (_lastApiCall != null && DateTime.now().difference(_lastApiCall!) < _minCallInterval) {
      throw Exception('Please wait ${_minCallInterval.inSeconds} seconds between API calls');
    }

    final apiKey = _configStore.config!.geminiApiKey!;
    
    try {
      final prompt = _buildParsePrompt(rawText, periodType, schoolType);
      final response = await _callGemini(apiKey, prompt);
      
      _lastApiCall = DateTime.now();
      
      return _parseBlocksFromResponse(response, templateId, periodType);
    } catch (e) {
      throw Exception('AI Parse Error: $e');
    }
  }

  /// Parse program from image (photo of schedule)
  Future<List<ProgramBlock>> parseProgramFromImage({
    required String base64Image,
    required PeriodType periodType,
    required SchoolType schoolType,
    required String templateId,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured');
    }

    // Rate limiting
    if (_lastApiCall != null && DateTime.now().difference(_lastApiCall!) < _minCallInterval) {
      throw Exception('Please wait ${_minCallInterval.inSeconds} seconds between API calls');
    }

    final apiKey = _configStore.config!.geminiApiKey!;
    
    try {
      final prompt = _buildImageParsePrompt(periodType, schoolType);
      final response = await _callGeminiWithImage(apiKey, prompt, base64Image);
      
      _lastApiCall = DateTime.now();
      
      return _parseBlocksFromResponse(response, templateId, periodType);
    } catch (e) {
      throw Exception('AI Image Parse Error: $e');
    }
  }

  /// Generate daily plan from program blocks
  Future<List<DailyPlanBlock>> generateDailyPlan({
    required List<ProgramBlock> blocks,
    required String dateKey,
    required SchoolType schoolType,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured');
    }

    // Rate limiting
    if (_lastApiCall != null && DateTime.now().difference(_lastApiCall!) < _minCallInterval) {
      throw Exception('Please wait ${_minCallInterval.inSeconds} seconds between API calls');
    }

    final apiKey = _configStore.config!.geminiApiKey!;
    
    try {
      final prompt = _buildDailyPlanPrompt(blocks, schoolType);
      final response = await _callGemini(apiKey, prompt);
      
      _lastApiCall = DateTime.now();
      
      return _parseDailyPlanFromResponse(response);
    } catch (e) {
      throw Exception('AI Plan Error: $e');
    }
  }

  /// Build prompt for program parsing
  String _buildParsePrompt(String rawText, PeriodType periodType, SchoolType schoolType) {
    final schoolTypeLabel = schoolType == SchoolType.primaryPrivate ? 'Özel İlkokul' : 'Kreş/Anaokulu';
    final periodLabel = periodType == PeriodType.weekly ? 'haftalık' : 'aylık';
    
    return '''
Bir $schoolTypeLabel için $periodLabel program metnini JSON formatına çevir.

Program Metni:
$rawText

Çıktı formatı (JSON):
{
  "blocks": [
    {
      "dayOfWeek": 1,  // 1-7 (Pazartesi-Pazar) - sadece haftalık için
      "dateKey": "2024-01-15",  // YYYY-MM-DD - sadece aylık için
      "startTime": "09:00",
      "endTime": "10:00",
      "label": "Matematik",
      "notes": "Toplama işlemi"
    }
  ]
}

KURALLAR:
- Sadece JSON döndür, açıklama ekleme
- Saatleri HH:mm formatında yaz
- dayOfWeek: 1=Pazartesi, 7=Pazar
- ${periodType == PeriodType.weekly ? 'dayOfWeek kullan' : 'dateKey kullan'}
- label kısa ve öz olsun
''';
  }

  /// Build prompt for daily plan generation
  String _buildDailyPlanPrompt(List<ProgramBlock> blocks, SchoolType schoolType) {
    final blocksText = blocks.map((b) => '${b.startTime}-${b.endTime}: ${b.label}').join('\n');
    
    return '''
Bugünkü program bloklarını detaylandır. Her blok için öğretmen adımları ve veli özeti oluştur.

Program:
$blocksText

Çıktı formatı (JSON):
{
  "blocks": [
    {
      "startTime": "09:00",
      "endTime": "10:00",
      "label": "Matematik",
      "teacherSteps": ["1. Sayıları tanıt", "2. Örnek göster", "3. Alıştırma yap"],
      "parentSummary": "Bugün 1-10 arası sayıları öğrendik"
    }
  ]
}

KURALLAR:
- Sadece JSON döndür
- teacherSteps: max 3-5 adım
- parentSummary: tek cümle, kısa
- label aynen kalsın
''';
  }

  /// Build prompt for image-based program parsing
  String _buildImageParsePrompt(PeriodType periodType, SchoolType schoolType) {
    final schoolTypeLabel = schoolType == SchoolType.primaryPrivate ? 'Özel İlkokul' : 'Kreş/Anaokulu';
    final periodLabel = periodType == PeriodType.weekly ? 'haftalık' : 'aylık';
    
    return '''
Bu görselde bir $schoolTypeLabel için $periodLabel ders programı var. 
Lütfen bu programı okuyup JSON formatına çevir.

Çıktı formatı (JSON):
{
  "blocks": [
    {
      "dayOfWeek": 1,  // 1-7 (Pazartesi-Pazar) - sadece haftalık için
      "dateKey": "2024-01-15",  // YYYY-MM-DD - sadece aylık için
      "startTime": "09:00",
      "endTime": "10:00",
      "label": "Matematik",
      "notes": "Toplama işlemi"
    }
  ]
}

KURALLAR:
- Görseldeki tüm ders programını oku
- Sadece JSON döndür, açıklama ekleme
- Saatleri HH:mm formatında yaz
- dayOfWeek: 1=Pazartesi, 7=Pazar
- ${periodType == PeriodType.weekly ? 'dayOfWeek kullan' : 'dateKey kullan'}
- label kısa ve öz olsun
- Eğer görselde notlar/açıklamalar varsa notes alanına ekle
''';
  }

  /// Call Gemini API
  Future<String> _callGemini(String apiKey, String prompt) async {
    final url = Uri.parse('$_geminiApiBase?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    
    if (text == null) {
      throw Exception('Invalid Gemini response');
    }

    return text;
  }

  /// Call Gemini API with image (Vision API)
  Future<String> _callGeminiWithImage(String apiKey, String prompt, String base64Image) async {
    final url = Uri.parse('$_geminiApiBase?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    
    if (text == null) {
      throw Exception('Invalid Gemini response');
    }

    return text;
  }

  /// Parse program blocks from Gemini response
  List<ProgramBlock> _parseBlocksFromResponse(String response, String templateId, PeriodType periodType) {
    try {
      // Extract JSON from response (might have markdown code blocks)
      final jsonText = _extractJson(response);
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      final blocksJson = data['blocks'] as List;

      return blocksJson.map((block) {
        final b = block as Map<String, dynamic>;
        return ProgramBlock(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}_${blocksJson.indexOf(block)}',
          templateId: templateId,
          dayOfWeek: periodType == PeriodType.weekly ? (b['dayOfWeek'] as int?) : null,
          dateKey: periodType == PeriodType.monthly ? (b['dateKey'] as String?) : null,
          startTime: b['startTime'] as String,
          endTime: b['endTime'] as String,
          label: b['label'] as String,
          notes: b['notes'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Parse daily plan blocks from Gemini response
  List<DailyPlanBlock> _parseDailyPlanFromResponse(String response) {
    try {
      final jsonText = _extractJson(response);
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      final blocksJson = data['blocks'] as List;

      return blocksJson.map((block) {
        final b = block as Map<String, dynamic>;
        return DailyPlanBlock(
          startTime: b['startTime'] as String,
          endTime: b['endTime'] as String,
          label: b['label'] as String,
          teacherSteps: (b['teacherSteps'] as List?)?.cast<String>(),
          parentSummary: b['parentSummary'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Extract JSON from response (handle markdown code blocks)
  String _extractJson(String response) {
    // Remove markdown code blocks if present
    var cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}

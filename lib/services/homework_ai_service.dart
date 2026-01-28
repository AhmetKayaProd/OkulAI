import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kresai/config/api_config.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/models/homework_report.dart';
import 'package:kresai/services/homework_ai_prompts.dart';

/// Homework generation result
class HomeworkGenerationResult {
  final List<HomeworkOption> options;
  final String summaryForTeacher;
  final Map<String, bool> checks;

  const HomeworkGenerationResult({
    required this.options,
    required this.summaryForTeacher,
    required this.checks,
  });

  factory HomeworkGenerationResult.fromJson(Map<String, dynamic> json) {
    return HomeworkGenerationResult(
      options: (json['options'] as List)
          .map((e) => HomeworkOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      summaryForTeacher: json['summaryForTeacher'] as String,
      checks: Map<String, bool>.from(json['checks'] as Map),
    );
  }
}

/// Homework AI Service - Gemini integration for homework generation and review
class HomeworkAIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.0-flash:generateContent';

  final String _apiKey;

  HomeworkAIService() : _apiKey = ApiConfig.geminiApiKey;



  /// A) Generate homework options (min 3)
  Future<HomeworkGenerationResult> generateHomework({
    required GradeBand gradeBand,
    required String classContext,
    required TimeWindow timeWindow,
    required String topics,
    required int estimatedMinutes,
    required Difficulty difficulty,
    required List<HomeworkFormat> formatsAllowed,
    String? teacherStyle,
  }) async {
    final prompt = HomeworkAIPrompts.buildHomeworkGenerationPrompt(
      gradeBand: gradeBand,
      classContext: classContext,
      timeWindow: timeWindow,
      topics: topics,
      estimatedMinutes: estimatedMinutes,
      difficulty: difficulty,
      formatsAllowed: formatsAllowed,
      teacherStyle: teacherStyle,
    );

    final response = await _callGemini(prompt);
    return HomeworkGenerationResult.fromJson(response);
  }

  /// B) Single AI review of submission
  Future<AIReview> reviewSubmission({
    required HomeworkSubmission submission,
    required HomeworkOption homework,
  }) async {
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      return AIReview(
        verdict: SubmissionVerdict.readyToSend,
        confidence: 0.95,
        scoreSuggestion: const ScoreSuggestion(
          maxScore: 100,
          suggestedScore: 100,
          reasoningBullets: ['Harika bir çalışma! Yönergeleri eksiksiz takip etmişsiniz.'],
        ),
        feedbackToParent: const FeedbackToParent(
          tone: 'Encouraging',
          whatIsGood: [
            'Nesnelerin sayımı çok doğru.',
            'Yaratıcı materyaller kullanılmış.',
            'Çocuğunuzun ilgisi yüksek görünüyor.'
          ],
          whatToImprove: [],
          hintsWithoutSolution: [
            'Bir sonraki sefer farklı renkleri gruplamayı deneyebilirsiniz.'
          ],
        ),
        flags: [],
        reviewedAt: DateTime.now(),
      );
    }
    final prompt = HomeworkAIPrompts.buildReviewPrompt(
      submission: submission,
      homework: homework,
    );
    final response = await _callGemini(prompt);
    
    return AIReview(
      verdict: SubmissionVerdict.values.firstWhere(
        (e) => e.name == response['verdict'],
      ),
      confidence: (response['confidence'] as num).toDouble(),
      scoreSuggestion: ScoreSuggestion.fromJson(
        response['scoreSuggestion'] as Map<String, dynamic>,
      ),
      feedbackToParent: FeedbackToParent.fromJson(
        response['feedbackToParent'] as Map<String, dynamic>,
      ),
      flags: (response['flags'] as List).cast<String>(),
      reviewedAt: DateTime.now(),
    );
  }

  /// Generate weekly insights
  Future<ClassWeeklyInsights> generateWeeklyInsights({
    required String weekRange,
    required List<AssignmentReport> reports,
  }) async {
    final prompt = HomeworkAIPrompts.buildInsightsPrompt(
      weekRange: weekRange,
      reports: reports,
    );
    final response = await _callGemini(prompt);
    return ClassWeeklyInsights.fromJson(response);
  }





  /// C) Generate class-wide insights for a specific homework assignment
  Future<AIHomeworkInsights> generateClassInsights({
    required Homework homework,
    required double averageScore,
    required List<String> commonIssues,
  }) async {
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AIHomeworkInsights(
        summary: 'Sınıf genelinde bu ödevde yüksek katılım sağlandı. Öğrenciler özellikle nesneleri kullanarak yapılan "evde av" kısmını çok sevdi ve başarılı oldu. (%${(averageScore).toStringAsFixed(0)} başarı).',
        keyMisconceptions: [
          'Bazı öğrenciler toplama ile saymayı karıştırdı.',
          'Nesne gruplamada renk/şekil ayrımı net yapılmadı.'
        ],
        successfulTopics: [
          'Nesne Tanıma',
          'Sayı Eşleştirme',
          'Yaratıcılık'
        ],
        recommendationsForTeacher: [
          'Gelecek derste toplama işleminin mantığını "bir araya getirme" hikayeleriyle pekiştirebilirsiniz.',
          'Renk gruplama oyunlarına sınıf içinde daha fazla yer verilebilir.'
        ],
      );
    }

    // TODO: Build actual prompt for Class Insights
    return AIHomeworkInsights(
      summary: 'Analiz oluşturulamadı.',
      keyMisconceptions: [],
      successfulTopics: [],
      recommendationsForTeacher: [],
    );
  }

  // ==================== GEMINI API CALL ====================

  Future<Map<String, dynamic>> _callGemini(String prompt) async {
    final url = Uri.parse('$_baseUrl/$_model?key=$_apiKey');
    
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
        'topP': 0.95,
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        // Handle 429 specifically - Fallback to Mock
        if (response.statusCode == 429 || response.statusCode == 503) {
          print('⚠️ API Quota Exceeded/Busy. Returning MOCK data for development.');
          return _getMockHomeworkData();
        }
        
        // Handle other errors
        throw GenerativeAIException('AI Servis Hatası: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw GenerativeAIException('AI yanıt üretemedi.');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final text = parts[0]['text'] as String;

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw GenerativeAIException('AI yanıtı formatlanamadı.');
      }

      return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    } on GenerativeAIException {
      rethrow;
    } catch (e) {
      throw GenerativeAIException('Bağlantı hatası: $e');
    }
  }

  /// Mock Data Generator for Dev/Fallback
  Map<String, dynamic> _getMockHomeworkData() {
    return {
      'options': [
        {
          'optionId': 'mock_opt_1',
          'title': 'Evde Toplama Avı (Simülasyon)',
          'goal': 'Toplama işlemini gerçek nesnelerle pekiştirmek.',
          'format': 'handsOn',
          'estimatedMinutes': 15,
          'materials': ['Oyuncaklar', 'Meyveler', 'Kalem'],
          'studentInstructions': [
            'Odanızdan 3 tane oyuncak seçin.',
            'Mutfaktan 2 tane meyve alın.',
            'Hepsini yan yana dizin ve yüksek sesle sayın.',
            'Sonucu defterinize yazın.'
          ],
          'parentGuidance': [
            'Çocuğunuzun nesneleri teker teker saymasını teşvik edin.',
            'Sonucu bulduğunda "Aferin!" diyerek motive edin.'
          ],
          'submissionType': 'photo',
          'gradingRubric': {
            'maxScore': 100,
            'criteria': [
              {'name': 'Nesne Seçimi', 'points': 40},
              {'name': 'Doğru Sayma', 'points': 60}
            ]
          },
          'teacherAnswerKey': {
            'notes': 'Öğrenci 5 nesneyi doğru saymalı.',
            'expectedPoints': ['Nesne çeşitliliği önemli değil.'],
            'sampleAnswers': ['3+2=5'],
            'mcqCorrect': null
          },
          'adaptations': {
            'easy': 'Sadece 3 nesne ile yapın.',
            'hard': 'Nesneleri renklerine göre gruplayıp toplayın.'
          }
        },
        {
          'optionId': 'mock_opt_2',
          'title': 'Rakamları Eşleştir (Simülasyon)',
          'goal': 'Rakam sembollerini tanımak.',
          'format': 'matching',
          'estimatedMinutes': 10,
          'materials': ['Kağıt', 'Makas'],
          'studentInstructions': [
            'Kağıtlara 1\'den 5\'e kadar rakamları yazın.',
            'Her rakamın yanına o kadar nokta koyun.',
            'Kağıtları karıştırıp tekrar eşleştirin.'
          ],
          'parentGuidance': [
            'Makas kullanırken gözetim altında tutun.'
          ],
          'submissionType': 'photo',
          'gradingRubric': {
            'maxScore': 100,
            'criteria': [
              {'name': 'Eşleştirme Doğruluğu', 'points': 100}
            ]
          },
          'teacherAnswerKey': {
            'notes': '1->1 nokta, 2->2 nokta...',
            'expectedPoints': [],
            'sampleAnswers': [],
            'mcqCorrect': null
          },
          'adaptations': {
            'easy': 'Sadece 1-3 arası rakamlar.',
            'hard': '1-10 arası rakamlar.'
          }
        }
      ],
      'summaryForTeacher': '⚠️ API Kotası aşıldı! Geliştirme modu için simülasyon verileri gösteriliyor. (Bu bir hata değildir)',
      'checks': {
        'safety': true,
        'ageAppropriate': true
      }
    };
  }
}

/// Custom exception for AI errors
class GenerativeAIException implements Exception {
  final String message;
  final bool canRetry;

  GenerativeAIException(this.message, {this.canRetry = false});

  @override
  String toString() => message;
}

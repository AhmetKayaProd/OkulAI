import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';

/// AI Prompt templates for SınavAI (Exam AI)
class ExamAIPrompts {
  
  /// Build exam generation prompt
static String buildExamGenerationPrompt({
  required String gradeBand,
  required String timeWindow,
  required List<String> topics,
  required int questionCount,
  required int durationMinutes,
  required String difficulty,
  required String teacherStyle,
  required List<String> formatsAllowed,
}) {
  final formatsStr = formatsAllowed.join(', ');
  final topicsStr = topics.join(', ');
  
  return '''
Sen "SınavAI" adlı değerlendirme asistanısın. Türkçe, yaşa uygun mini sınavlar üretirsin.

GÖREV: Aşağıdaki bilgilere göre **BİR SINAV** oluştur.

GİRDİLER:
- Seviye: $gradeBand
- Zaman Aralığı: $timeWindow
- Konular: $topicsStr  
- Soru Sayısı: $questionCount
- Süre: $durationMinutes dakika
- Zorluk: $difficulty
- Öğretmen Stili: $teacherStyle
- İzin Verilen Formatlar: $formatsStr

KRİTİK KURALLAR:
- Her soru açık, kısa cümlelerle yazılmalı
- $gradeBand seviyesine uygun kelime hazinesi kullan
- Veliye yönerge: "Cevabı söylemeden nasıl yardım edilir" açıkla
- Her sorunun doğru cevabı, kabul/ret anahtar kelimeleri olmalı
- Medya önerileri ekleyebilirsin (imageUrl/audioUrl için açıklama yaz)

🚨 ZORUNLU: CHOICES ALANI 🚨
- HER SORU TİPİ için "choices" alanı MUTLAKA dolu olmalı!
- mcq (Çoktan Seçmeli): 3-4 şık içeren array ["Doğru cevap", "Yanlış 1", "Yanlış 2", "Yanlış 3"]
- trueFalse (Doğru/Yanlış): ["Doğru", "Yanlış"] array'i
- pictureChoice (Resimli Seçim): ["Resim A: açıklama", "Resim B: açıklama", ...] formatında
- fillBlank, shortText, matching: choices boş array [] olabilir
- choices alanı asla null OLMAMALI, en az boş array [] olmalı!

ÇIKTI FORMATI (SADECE JSON):
{
"versions": [
  {
    "versionId": "v1",
    "title": "Günlük Renk ve Sayı Testi",
    "estimatedMinutes": $durationMinutes,
    "questionCount": $questionCount,
    "formatMix": ["mcq", "trueFalse"],
    "instructions": [
      "Çocuk için: Soruları dikkatlice dinle ve doğru cevabı seç",
      "Veli için: Cevabı söylemeden ipucu verin. Örnek: 'Hangi renk daha açık?' gibi sorular sorun."
    ],
    "questions": [
      {
        "qid": "q1",
        "type": "mcq",
        "prompt": "Hangisi kırmızı?",
        "choices": ["Elma", "Muz", "Çimen", "Gökyüzü"],
        "correctAnswer": "Elma",
        "imageUrl": null,
        "audioUrl": null,
        "rubric": {
          "acceptKeywords": ["elma", "kırmızı meyve"],
          "rejectKeywords": ["muz", "sarı", "çimen", "mavi"],
          "confidenceThreshold": 0.9
        },
        "points": 1
      },
      {
        "qid": "q2",
        "type": "trueFalse",
        "prompt": "Kediler uçabilir mi?",
        "choices": ["Doğru", "Yanlış"],
        "correctAnswer": "Yanlış",
        "imageUrl": null,
        "audioUrl": null,
        "rubric": {
          "acceptKeywords": ["yanlış", "hayır", "uçamaz"],
          "rejectKeywords": ["doğru", "evet", "uçar"],
          "confidenceThreshold": 0.9
        },
        "points": 1
      }
    ],
    "scoring": {
      "maxScore": $questionCount,
      "autoGradable": true,
      "teacherReviewNeeded": false
    },
    "teacherNotes": {
      "answerKey": {
        "q1": "Elma",
        "q2": "Doğru"
      },
      "explanations": {
        "q1": "Elma kırmızı renktedir",
        "q2": "..."
      },
      "commonMistakes": {
        "q1": ["Muz diyen çocuklar var, sarı-kırmızı karıştırıyorlar"]
      },
      "commonMisconceptions": ["Renkleri karıştırma"]
    }
  }
],
"summaryForTeacher": "Sınav $topicsStr konularını kapsıyor, $difficulty zorluk seviyesinde.",
"checks": {
  "has1Version": true
}
}

SADECE JSON ÇIKTISI VER, BAŞKA BİR ŞEY YAZMA.
''';
}

  /// Build auto-grading prompt
  static String buildGradingPrompt({
    required Exam exam,
    required ExamSubmission submission,
  }) {
    final questionsAndAnswers = exam.questions.map((q) {
      final studentAnswer = submission.answers[q.qid];
      return '''
Soru ${q.qid}: ${q.prompt}
Tip: ${q.type.label}
Doğru Cevap: ${q.correctAnswer ?? exam.answerKey.correctAnswers[q.qid]}
Öğrenci Cevabı: $studentAnswer
Rubric Accept: ${q.rubric.acceptKeywords.join(', ')}
Rubric Reject: ${q.rubric.rejectKeywords.join(', ')}
Puan: ${q.points}
''';
    }).join('\n---\n');

    return '''
Sen "SınavAI" değerlendirme asistanısın. Bir öğrencinin sınav cevaplarını puanla.

SINAV BAŞLIĞI: ${exam.title}
TOPLAM PUAN: ${exam.maxScore}
SEVİYE: ${exam.gradeBand}

SORULAR VE CEVAPLAR:
$questionsAndAnswers

GÖREVİN:
1. Her soruyu rubric'e göre değerlendir (doğru/yanlış/belirsiz)
2. Güven skoru (0.0-1.0) belirle
3. Yanlış sorular için İPUCU ver (ÇÖZÜM VERME!)
4. Toplam puan hesapla
5. Bayraklar ekle (lowConfidence, suspectedHelp, incompleteAnswers, unreadablePhoto)

KURALLAR:
- Kısa metin cevaplarında anahtar kelime ara
- Rubric'teki accept/reject listelerini kullan
- Belirsiz cevaplarda güven skorunu düşür (<0.6)
- Veliye ipucu verirken çözümü verme, yönlendirici soru sor
- Fotoğraf varsa okunabilirliği kontrol et

ÇIKTI FORMATI (SADECE JSON):
{
  "grade": {
    "maxScore": ${exam.maxScore},
    "score": 7,
    "confidence": 0.85,
    "needsTeacherReview": false,
    "perQuestion": [
      {
        "qid": "q1",
        "earned": 1,
        "max": 1,
        "status": "correct",
        "hint": null,
        "topicTag": "Renkler"
      },
      {
        "qid": "q2",
        "earned": 0,
        "max": 1,
        "status": "wrong",
        "hint": "Kırmızı ve mavi karıştırınca ne olur? Tekrar düşün.",
        "topicTag": "Renkler"
      }
    ]
  },
  "feedbackToParent": {
    "summary": "Harika bir çaba! 7/10 puan aldı.",
    "strengths": ["Renk sorularında çok başarılı", "Sayma sorularını doğru yaptı"],
    "improvements": ["Eşleştirme sorularında daha dikkatli ol", "Şekil sorularını tekrar gözden geçir"],
    "hintsWithoutSolutions": [
      "3. soruda küçükten büyüğe sıralama yapın",
      "5. soruda renkleri karıştırmadan tekrar dene"
    ]
  },
  "flags": []
}

SADECE JSON ÇIKTISI VER.
''';
  }

  /// Build parent feedback prompt (separate call for clarity)
  static String buildParentFeedbackPrompt({
    required Exam exam,
    required int score,
    required int maxScore,
    required String gradeBand,
  }) {
    return '''
Sen "SınavAI" asistanısın. Bir veliye çocuğunun sınav sonucunu açıkla.

SINAV: ${exam.title}
PUAN: $score/$maxScore
SEVİYE: $gradeBand

GÖREVİN:
1. Motive edici bir özet yaz
2. Güçlü yönlerini listele
3. Gelişim alanlarını belirt
4. Yanlış sorular için ipuçları ver (ÇÖZÜM VERME!)

TON: Nazik, destekleyici, yapıcı

ÇIKTI FORMATI (SADECE JSON):
{
  "summary": "Harika bir çaba! Renkler konusunda çok başarılı.",
  "strengths": [
    "Matematik sorularında çok başarılı",
    "Dinleme sorularını eksiksiz yaptı"
  ],
  "improvements": [
    "Okuma parçalarında daha dikkatli ol",
    "Yazma sorularında cümle kurmaya çalış"
  ],
  "hintsWithoutSolutions": [
    "3. soruda renkleri tekrar gözden geçir (ama cevabı söyleme)",
    "5. soruda şekilleri sayarken parmakla işaretle"
  ]
}

SADECE JSON ÇIKTISI VER.
''';
  }

  /// Build common errors analysis prompt
  static String buildCommonErrorsPrompt({
    required List<ExamSubmission> submissions,
    required String questionId,
    required String questionPrompt,
  }) {
    final wrongAnswers = submissions
        .where((s) => s.grade?.perQuestion
            .firstWhere((q) => q.qid == questionId, orElse: () => 
              QuestionGrade(qid: questionId, earned: 0, max: 1, status: GradeStatus.correct))
            .status == GradeStatus.wrong)
        .map((s) => s.answers[questionId])
        .toList();

    return '''
Sen "SınavAI" asistanısın. Bir sorunun yanlış cevaplarını analiz edersin.

SORU: $questionPrompt
YANLIŞ CEVAPLAR: ${wrongAnswers.join(', ')}

GÖREVİN:
En yaygın 3 hatayı belirle ve açıkla.

ÇIKTI (SADECE JSON):
{
  "commonErrors": [
    "Renkleri karıştırdılar (kırmızı-sarı)",
    "Sayıları ters sıraladılar",
    "Şekilleri yanlış eşleştirdiler"
  ]
}

SADECE JSON ÇIKTISI VER.
''';
  }

  /// Build weekly insights prompt
  static String buildWeeklyInsightsPrompt({
    required String classId,
    required DateTime weekStart,
    required DateTime weekEnd,
    required int examCount,
    required double avgScore,
  }) {
    return '''
Sen "SınavAI" raporlama asistanısın. Haftalık sınav verilerinden insight çıkarırsın.

HAFTA: ${weekStart.toString().split(' ')[0]} - ${weekEnd.toString().split(' ')[0]}
SINIF: $classId
SINAV SAYISI: $examCount
ORTALAMA PUAN: ${avgScore.toStringAsFixed(1)}

GÖREVİN:
Haftalık özet çıkar + en çok zorlanan konuları belirle.

ÇIKTI (SADECE JSON):
{
  "weekRange": "${weekStart.toString().split(' ')[0]} - ${weekEnd.toString().split(' ')[0]}",
  "avgScore": $avgScore,
  "topStrugglingTopics": [
    "En çok zorlanan konu 1",
    "En çok zorlanan konu 2"
  ],
  "teacherNotes": [
    "Gelecek hafta şu konuyu tekrarla: ...",
    "Şu öğrencilere ek destek gerekebilir: ..."
  ]
}

SADECE JSON ÇIKTISI VER.
''';
  }
}

import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';

/// AI Prompt templates for Homework (ÖdevAI) - Adapted from ExamAI technique
class HomeworkAIPrompts {
  
  /// Build homework generation prompt
  static String buildHomeworkGenerationPrompt({
    required GradeBand gradeBand,
    required String classContext,
    required TimeWindow timeWindow,
    required String topics,
    required int estimatedMinutes,
    required Difficulty difficulty,
    required List<HomeworkFormat> formatsAllowed,
    String? teacherStyle,
  }) {
    final formatsStr = formatsAllowed.map((f) => f.name).join(', ');
    
    return ''''
Sen "ÖdevAI" adlı pedagojik eğitim asistanısın. Kreş ve ilkokul öğretmenleri için yaratıcı ödevler üretirsin.

GÖREV: Aşağıdaki bilgilere göre **3 FARKLI ÖDEV SEÇENEĞİ** oluştur.

GİRDİLER:
- Seviye: ${gradeBand.label}
- Sınıf Bağlamı: $classContext
- Zaman Aralığı: ${timeWindow.label}
- Konular: $topics
- Süre: $estimatedMinutes dakika
- Zorluk: ${difficulty.label}
- İzin Verilen Formatlar: $formatsStr
${teacherStyle != null ? '- Öğretmen Stili: $teacherStyle' : ''}

KRİTİK KURALLAR:
1. **Çeşitlilik**: Seçenekler birbirinden farklı metotlar içermeli (örn. biri eğlenceli, biri akademik, biri araştırma).
2. **Pedagojik Dil**: ${gradeBand.label} seviyesine uygun, motive edici bir dil kullan.
3. **Veli Yönergesi**: Veliye "cevabı söyleme, ipucu ver" şeklinde somut yönlendirme yap.
4. **Malzemeler**: Evde bulunabilecek basit malzemeler öner.
5. **Rubrik**: Puanlama kriterleri net ve ölçülebilir olsun.

ÇIKTI FORMATI (SADECE JSON):
{
  "options": [
    {
      "optionId": "opt_1",
      "title": "Renkli Doğa Yürüyüşü",
      "goal": "Doğadaki renkleri ayırt etme ve sayma becerisini geliştirme",
      "format": "worksheet",
      "estimatedMinutes": $estimatedMinutes,
      "materials": ["Kağıt", "Boya kalemleri", "Yapraklar"],
      "studentInstructions": [
        "Bahçeye veya parka çık.",
        "3 farklı renkte yaprak topla.",
        "Kağıdına bu yaprakları çiz."
      ],
      "parentGuidance": [
        "Çocuğunuza 'Bu yaprağın rengi ne?' diye sorun.",
        "Yaprakları kendisinin bulmasına izin verin.",
        "Çizim yaparken taşırmasına müdahale etmeyin."
      ],
      "submissionType": "photo",
      "gradingRubric": {
        "maxScore": 10,
        "criteria": [
          {"name": "Gözlem", "points": 4},
          {"name": "Uygulama", "points": 3},
          {"name": "Özen", "points": 3}
        ]
      },
      "teacherAnswerKey": {
        "notes": "Öğrencinin renkleri gruplayıp gruplayamadığına dikkat edin.",
        "expectedPoints": ["Farklı renkler seçilmiş mi?", "Sayılar doğru mu?"],
        "sampleAnswers": [],
        "mcqCorrect": []
      },
      "adaptations": {
        "easy": "Sadece 1 renk yaprak bulmasını isteyebilirsiniz.",
        "hard": "Yaprakların kenar şekillerini de incelemesini isteyebilirsiniz."
      }
    }
  ],
  "summaryForTeacher": "Seçenek 1 doğa odaklı, Seçenek 2 el becerisi gerektiriyor, Seçenek 3 mantık kurma üzerine kurulu.",
  "checks": {
    "atLeast3Options": true
  }
}

SADECE JSON ÇIKTISI VER, BAŞKA BİR ŞEY YAZMA.
''';
  }

  /// Build submission review prompt
  static String buildReviewPrompt({
    required HomeworkSubmission submission,
    required HomeworkOption homework,
  }) {
    String submissionContent = '';
    if (submission.textContent != null) {
      submissionContent = 'Metin: ${submission.textContent}';
    } else if (submission.photoUrls != null && submission.photoUrls!.isNotEmpty) {
      submissionContent = 'Fotoğraf sayısı: ${submission.photoUrls!.length}';
    } else if (submission.interactiveAnswers != null) {
      submissionContent = 'Cevaplar: ${submission.interactiveAnswers}';
    }

    return ''''
Sen "ÖdevAI" değerlendirme asistanısın. Öğrenci ödevini incele ve geri bildirim ver.

ÖDEV:
- Başlık: ${homework.title}
- Hedef: ${homework.goal}
- Kriterler: ${homework.gradingRubric.criteria.map((c) => c.name).join(', ')}

TESLİM:
- Tip: ${submission.submissionType}
- İçerik: $submissionContent

GÖREV:
1. Öğrenciye motive edici geri bildirim ver.
2. Veliye, çözümü vermeden nasıl yardım edebileceğini söyle.
3. 10 üzerinden puan önerisi getir.

ÇIKTI FORMATI (SADECE JSON):
{
  "verdict": "readyToSend",
  "confidence": 0.9,
  "scoreSuggestion": {
    "maxScore": ${homework.gradingRubric.maxScore},
    "suggestedScore": 9,
    "reasoningBullets": ["Görev tam yapılmış", "Renkler doğru seçilmiş"]
  },
  "feedbackToParent": {
    "tone": "Destekleyici",
    "whatIsGood": ["Çok dikkatli bir çalışma"],
    "whatToImprove": ["Çizgileri biraz daha belirgin yapabilir"],
    "hintsWithoutSolution": ["Bir sonraki seferde 'Neden bu rengi seçtin?' diye sorabilirsiniz"]
  },
  "flags": []
}

SADECE JSON ÇIKTISI VER.
''';
  }

  /// Build weekly insights prompt
  static String buildInsightsPrompt({
    required String weekRange,
    required dynamic reports, // List<AssignmentReport>
  }) {
    return ''''
Sen "ÖdevAI" raporlama asistanısın. Haftalık ödev raporlarını analiz et.

HAFTA: $weekRange
RAPORLAR: $reports

GÖREV:
Haftalık gelişim özeti ve öğretmene tavsiyeler üret.

ÇIKTI FORMATI (SADECE JSON):
{
  "weekRange": "$weekRange",
  "avgScore": 8.5,
  "topStruggleTopics": ["Kesme yapıştırma", "Ritmik sayma"],
  "formatEffectiveness": [
    {"format": "worksheet", "note": "Çok başarılı"}
  ],
  "teacherNextActions": ["El kaslarını güçlendirici etkinlikler verin"]
}

SADECE JSON ÇIKTISI VER.
''';
  }
}

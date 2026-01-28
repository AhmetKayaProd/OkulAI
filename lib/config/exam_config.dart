/// Configuration constants for SınavAI (Exam AI) system
class ExamConfig {
  // === Limits ===
  
  /// Maximum number of exams a teacher can publish per day per class
  static const int maxDailyExamPerClass = 1;
  
  /// Maximum number of exams per week per class
  static const int maxWeeklyExamPerClass = 5;
  
  // === Question Counts by Grade ===
  
  /// Default question count for each grade band
  static const Map<String, int> defaultQuestionCount = {
    'kres': 10, // Mikro sınavlar (kreş)
    'anaokulu': 10,
    'ilkokul': 15,
  };
  
  // === Duration Limits ===
  
  /// Minimum exam duration in minutes
  static const int minDurationMinutes = 5;
  
  /// Maximum exam duration in minutes
  static const int maxDurationMinutes = 60;
  
  // === Grading ===
  
  /// Confidence threshold for auto-grading (0.0 - 1.0)
  /// If AI confidence is below this, flag for teacher review
  static const double autoGradeConfidenceThreshold = 0.6;
  
  /// Maximum number of hints per question
  static const int maxHintsPerQuestion = 3;
  
  // === Reminders ===
  
  /// Enable automatic reminders to parents
  static const bool reminderEnabled = true;
  
  /// Send reminder X days before due date
  static const int reminderBeforeDueDays = 1;
  
  // === Teacher Override ===
  
  /// Allow teachers to manually override AI grades
  static const bool teacherOverrideEnabled = true;
  
  // === Anti-Cheat (V1 Stub) ===
  
  /// Available anti-cheat levels
  static const List<String> antiCheatLevels = ['low', 'medium'];
  
  // === Score Distribution Buckets ===
  
  /// Score ranges for analytics (used in reports)
  static const Map<String, String> scoreRanges = {
    'excellent': '9-10',
    'good': '6-8',
    'average': '3-5',
    'poor': '0-2',
  };
  
  // === Teacher Styles ===
  
  /// Available teaching styles for AI generation
  static const List<String> teacherStyles = [
    'nazik', // Gentle/kind
    'oyunlaştırılmış', // Gamified
    'klasik', // Classic/traditional
  ];
  
  // === Grade Bands ===
  
  /// Available grade levels
  static const List<String> gradeBands = [
    'kres',
    'anaokulu',
    'ilkokul',
  ];
  
  // === Time Windows ===
  
  /// Available time windows for exams
  static const List<String> timeWindows = [
    'gunluk', // Daily
    'haftalik', // Weekly
    'donemlik', // Term-based
  ];
}

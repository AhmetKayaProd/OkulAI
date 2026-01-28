/// Completion statistics
class CompletionStats {
  final int done;
  final int total;

  const CompletionStats({
    required this.done,
    required this.total,
  });

  double get percentage => total > 0 ? (done / total) * 100 : 0;

  factory CompletionStats.fromJson(Map<String, dynamic> json) {
    return CompletionStats(
      done: json['done'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'done': done,
      'total': total,
    };
  }
}

/// Student needing attention
class AttentionNeeded {
  final String studentId;
  final String reason; // low score or low confidence

  const AttentionNeeded({
    required this.studentId,
    required this.reason,
  });

  factory AttentionNeeded.fromJson(Map<String, dynamic> json) {
    return AttentionNeeded(
      studentId: json['studentId'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'reason': reason,
    };
  }
}

/// Format effectiveness insight
class FormatEffectiveness {
  final String format;
  final String note;

  const FormatEffectiveness({
    required this.format,
    required this.note,
  });

  factory FormatEffectiveness.fromJson(Map<String, dynamic> json) {
    return FormatEffectiveness(
      format: json['format'] as String,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'note': note,
    };
  }
}

/// AI-generated insights for the whole class (Homework)
class AIHomeworkInsights {
  final String summary;
  final List<String> keyMisconceptions;
  final List<String> successfulTopics;
  final List<String> recommendationsForTeacher;

  const AIHomeworkInsights({
    required this.summary,
    required this.keyMisconceptions,
    required this.successfulTopics,
    required this.recommendationsForTeacher,
  });

  factory AIHomeworkInsights.fromJson(Map<String, dynamic> json) {
    return AIHomeworkInsights(
      summary: json['summary'] as String? ?? 'Henüz analiz yapılmadı.',
      keyMisconceptions: (json['keyMisconceptions'] as List?)?.cast<String>() ?? [],
      successfulTopics: (json['successfulTopics'] as List?)?.cast<String>() ?? [],
      recommendationsForTeacher: (json['recommendationsForTeacher'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyMisconceptions': keyMisconceptions,
      'successfulTopics': successfulTopics,
      'recommendationsForTeacher': recommendationsForTeacher,
    };
  }
}

/// Assignment-level report
class AssignmentReport {
  final String assignmentId;
  final CompletionStats completion;
  final double averageScore;
  final Map<String, int> scoreDistribution; // "0-2": count, "3-4": count, etc.
  final List<String> commonIssues;
  final List<AttentionNeeded> needsAttention;
  final List<String> pendingStudentIds;
  final AIHomeworkInsights? aiInsights;

  const AssignmentReport({
    required this.assignmentId,
    required this.completion,
    required this.averageScore,
    required this.scoreDistribution,
    required this.commonIssues,
    required this.needsAttention,
    required this.pendingStudentIds,
    this.aiInsights,
  });

  factory AssignmentReport.fromJson(Map<String, dynamic> json) {
    return AssignmentReport(
      assignmentId: json['assignmentId'] as String,
      completion: CompletionStats.fromJson(
        json['completion'] as Map<String, dynamic>,
      ),
      averageScore: (json['averageScore'] as num).toDouble(),
      scoreDistribution: Map<String, int>.from(json['scoreDistribution'] as Map),
      commonIssues: (json['commonIssues'] as List).cast<String>(),
      needsAttention: (json['needsAttention'] as List)
          .map((e) => AttentionNeeded.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingStudentIds: (json['pendingStudentIds'] as List).cast<String>(),
      aiInsights: json['aiInsights'] != null 
          ? AIHomeworkInsights.fromJson(json['aiInsights'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'completion': completion.toJson(),
      'averageScore': averageScore,
      'scoreDistribution': scoreDistribution,
      'commonIssues': commonIssues,
      'needsAttention': needsAttention.map((a) => a.toJson()).toList(),
      'pendingStudentIds': pendingStudentIds,
      'aiInsights': aiInsights?.toJson(),
    };
  }
}

/// Class weekly insights
class ClassWeeklyInsights {
  final String weekRange;
  final double avgScore;
  final List<String> topStruggleTopics;
  final List<FormatEffectiveness> formatEffectiveness;
  final List<String> teacherNextActions;

  const ClassWeeklyInsights({
    required this.weekRange,
    required this.avgScore,
    required this.topStruggleTopics,
    required this.formatEffectiveness,
    required this.teacherNextActions,
  });

  factory ClassWeeklyInsights.fromJson(Map<String, dynamic> json) {
    return ClassWeeklyInsights(
      weekRange: json['weekRange'] as String,
      avgScore: (json['avgScore'] as num).toDouble(),
      topStruggleTopics: (json['topStruggleTopics'] as List).cast<String>(),
      formatEffectiveness: (json['formatEffectiveness'] as List)
          .map((e) => FormatEffectiveness.fromJson(e as Map<String, dynamic>))
          .toList(),
      teacherNextActions: (json['teacherNextActions'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekRange': weekRange,
      'avgScore': avgScore,
      'topStruggleTopics': topStruggleTopics,
      'formatEffectiveness': formatEffectiveness.map((f) => f.toJson()).toList(),
      'teacherNextActions': teacherNextActions,
    };
  }
}

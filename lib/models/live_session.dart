/// Live Session Status
enum LiveSessionStatus {
  live,
  ended,
}

/// Live Session
class LiveSession {
  final String id;
  final String classId;
  final String startedByTeacherId;
  final int startedAt; // epoch milliseconds
  final int? endedAt; // epoch milliseconds, null if live
  final LiveSessionStatus status;
  final String title;
  final bool requiresConsent;

  const LiveSession({
    required this.id,
    required this.classId,
    required this.startedByTeacherId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.title,
    required this.requiresConsent,
  });

  /// JSON'dan model oluştur
  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      classId: json['classId'] as String,
      startedByTeacherId: json['startedByTeacherId'] as String,
      startedAt: json['startedAt'] as int,
      endedAt: json['endedAt'] as int?,
      status: LiveSessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      title: json['title'] as String? ?? 'Canlı Yayın',
      requiresConsent: json['requiresConsent'] as bool? ?? true,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'startedByTeacherId': startedByTeacherId,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'status': status.name,
      'title': title,
      'requiresConsent': requiresConsent,
    };
  }

  /// Kopyalama methodu
  LiveSession copyWith({
    String? id,
    String? classId,
    String? startedByTeacherId,
    int? startedAt,
    int? endedAt,
    LiveSessionStatus? status,
    String? title,
    bool? requiresConsent,
  }) {
    return LiveSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      startedByTeacherId: startedByTeacherId ?? this.startedByTeacherId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      title: title ?? this.title,
      requiresConsent: requiresConsent ?? this.requiresConsent,
    );
  }
}

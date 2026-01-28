/// Activity Event Type
enum ActivityEventType {
  teacherApproved,
  teacherRejected,
  parentApproved,
  parentRejected,
  liveStarted,
  liveEnded,
  feedPosted,
  dailyUpdated,
}

/// Actor Role
enum ActorRole {
  admin,
  teacher,
  parent,
}

/// Activity Event
class ActivityEvent {
  final String id;
  final ActivityEventType type;
  final ActorRole actorRole;
  final String actorId;
  final String? classId;
  final int createdAt; // epoch milliseconds
  final String description;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.actorRole,
    required this.actorId,
    this.classId,
    required this.createdAt,
    required this.description,
  });

  /// JSON'dan model oluştur
  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String,
      type: ActivityEventType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      actorRole: ActorRole.values.firstWhere(
        (e) => e.name == json['actorRole'],
      ),
      actorId: json['actorId'] as String,
      classId: json['classId'] as String?,
      createdAt: json['createdAt'] as int,
      description: json['description'] as String,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorRole': actorRole.name,
      'actorId': actorId,
      'classId': classId,
      'createdAt': createdAt,
      'description': description,
    };
  }
}

/// Notification Type
enum NotificationType {
  approved,
  rejected,
  announcement, // Duyuru bildirimi
}

/// Notification Item
class NotificationItem {
  final String id;
  final NotificationType type;
  final String targetRole; // 'teacher' or 'parent'
  final String targetId; // registration ID
  final bool seen;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.targetRole,
    required this.targetId,
    required this.seen,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      targetRole: json['targetRole'] as String,
      targetId: json['targetId'] as String,
      seen: json['seen'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'targetRole': targetRole,
      'targetId': targetId,
      'seen': seen,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Kopyalama methodu
  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? targetRole,
    String? targetId,
    bool? seen,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      targetRole: targetRole ?? this.targetRole,
      targetId: targetId ?? this.targetId,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

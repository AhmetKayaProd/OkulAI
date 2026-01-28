/// Feed Item Type
enum FeedItemType {
  photo,
  video,
  text,
  activity,
}

/// Visibility
enum FeedVisibility {
  approvedParentsOnly,
  allParents,
}

/// Feed Item
class FeedItem {
  final String id;
  final FeedItemType type;
  final String classId;
  final String createdByTeacherId;
  final int createdAt; // epoch milliseconds
  final FeedVisibility visibility;
  final bool requiresConsent;
  final String? mediaUrl; // local asset or file path
  final String? textContent;
  final String? title;
  final String? description;

  const FeedItem({
    required this.id,
    required this.type,
    required this.classId,
    required this.createdByTeacherId,
    required this.createdAt,
    required this.visibility,
    required this.requiresConsent,
    this.mediaUrl,
    this.textContent,
    this.title,
    this.description,
  });

  /// JSON'dan model oluştur
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      type: FeedItemType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      classId: json['classId'] as String,
      createdByTeacherId: json['createdByTeacherId'] as String,
      createdAt: json['createdAt'] as int,
      visibility: FeedVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
      ),
      requiresConsent: json['requiresConsent'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
      textContent: json['textContent'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'classId': classId,
      'createdByTeacherId': createdByTeacherId,
      'createdAt': createdAt,
      'visibility': visibility.name,
      'requiresConsent': requiresConsent,
      'mediaUrl': mediaUrl,
      'textContent': textContent,
      'title': title,
      'description': description,
    };
  }

  /// Kopyalama methodu
  FeedItem copyWith({
    String? id,
    FeedItemType? type,
    String? classId,
    String? createdByTeacherId,
    int? createdAt,
    FeedVisibility? visibility,
    bool? requiresConsent,
    String? mediaUrl,
    String? textContent,
  }) {
    return FeedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      classId: classId ?? this.classId,
      createdByTeacherId: createdByTeacherId ?? this.createdByTeacherId,
      createdAt: createdAt ?? this.createdAt,
      visibility: visibility ?? this.visibility,
      requiresConsent: requiresConsent ?? this.requiresConsent,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      textContent: textContent ?? this.textContent,
    );
  }
}

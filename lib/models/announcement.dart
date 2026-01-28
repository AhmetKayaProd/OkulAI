/// Announcement Model
/// Öğretmen duyurularını temsil eder
class Announcement {
  final String id;
  final String title;
  final String content;
  final String className; // Hangi sınıf için
  final String teacherId; // Oluşturan öğretmen
  final DateTime createdAt;
  final bool urgent; // Acil duyuru mu?

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.className,
    required this.teacherId,
    required this.createdAt,
    this.urgent = false,
  });

  /// JSON'dan model oluştur
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      className: json['className'] as String,
      teacherId: json['teacherId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      urgent: json['urgent'] as bool? ?? false,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'className': className,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'urgent': urgent,
    };
  }

  /// Kopyalama metodu
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? className,
    String? teacherId,
    DateTime? createdAt,
    bool? urgent,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      urgent: urgent ?? this.urgent,
    );
  }
}

/// School Model
class School {
  final String id;
  final String name;
  final String adminId;
  final DateTime createdAt;

  const School({
    required this.id,
    required this.name,
    required this.adminId,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      adminId: json['adminId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  School copyWith({
    String? id,
    String? name,
    String? adminId,
    DateTime? createdAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

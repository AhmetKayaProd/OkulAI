/// Class Info Model - Sınıf bilgileri
class ClassInfo {
  final String id;
  final String name;
  final String schoolId;
  final String teacherId;
  final int size;
  final DateTime createdAt;

  const ClassInfo({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.teacherId,
    required this.size,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolId: json['schoolId'] as String,
      teacherId: json['teacherId'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  ClassInfo copyWith({
    String? id,
    String? name,
    String? schoolId,
    String? teacherId,
    int? size,
    DateTime? createdAt,
  }) {
    return ClassInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

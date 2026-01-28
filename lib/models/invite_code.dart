/// Invite Code Types
enum InviteCodeType {
  teacher,
  parent,
}

/// Invite Code Model
class InviteCode {
  final InviteCodeType type;
  final String code;
  final String schoolId;
  final String? classId;  // null for teacher codes
  final String? className;
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;

  const InviteCode({
    required this.type,
    required this.code,
    required this.schoolId,
    this.classId,
    this.className,
    this.createdBy,
    required this.isActive,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      type: InviteCodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InviteCodeType.teacher,
      ),
      code: json['code'] as String,
      schoolId: json['schoolId'] as String,
      classId: json['classId'] as String?,
      className: json['className'] as String?,
      createdBy: json['createdBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'code': code,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  InviteCode copyWith({
    InviteCodeType? type,
    String? code,
    String? schoolId,
    String? classId,
    String? className,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return InviteCode(
      type: type ?? this.type,
      code: code ?? this.code,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

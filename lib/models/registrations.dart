/// Registration Status
enum RegistrationStatus {
  pending,
  approved,
  rejected,
}

/// Teacher Registration Model
class TeacherRegistration {
  final String id;
  final String fullName;
  final String className;
  final int classSize;
  final String codeUsed;
  final RegistrationStatus status;
  final DateTime createdAt;

  const TeacherRegistration({
    required this.id,
    required this.fullName,
    required this.className,
    required this.classSize,
    required this.codeUsed,
    required this.status,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory TeacherRegistration.fromJson(Map<String, dynamic> json) {
    return TeacherRegistration(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      className: json['className'] as String,
      classSize: json['classSize'] as int,
      codeUsed: json['codeUsed'] as String,
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'className': className,
      'classSize': classSize,
      'codeUsed': codeUsed,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  TeacherRegistration copyWith({
    String? id,
    String? fullName,
    String? className,
    int? classSize,
    String? codeUsed,
    RegistrationStatus? status,
    DateTime? createdAt,
  }) {
    return TeacherRegistration(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      className: className ?? this.className,
      classSize: classSize ?? this.classSize,
      codeUsed: codeUsed ?? this.codeUsed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Parent Registration Model
class ParentRegistration {
  final String id;
  final String parentName;
  final String studentName;
  final String className; // Veli hangi sınıfa kayıtlı
  final bool photoConsent;
  final String codeUsed;
  final RegistrationStatus status;
  final DateTime createdAt;

  const ParentRegistration({
    required this.id,
    required this.parentName,
    required this.studentName,
    required this.className,
    required this.photoConsent,
    required this.codeUsed,
    required this.status,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory ParentRegistration.fromJson(Map<String, dynamic> json) {
    return ParentRegistration(
      id: json['id'] as String,
      parentName: json['parentName'] as String,
      studentName: json['studentName'] as String,
      className: json['className'] as String? ?? 'global', // Backward compatibility
      photoConsent: json['photoConsent'] as bool? ?? false,
      codeUsed: json['codeUsed'] as String,
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentName': parentName,
      'studentName': studentName,
      'className': className,
      'photoConsent': photoConsent,
      'codeUsed': codeUsed,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  ParentRegistration copyWith({
    String? id,
    String? parentName,
    String? studentName,
    String? className,
    bool? photoConsent,
    String? codeUsed,
    RegistrationStatus? status,
    DateTime? createdAt,
  }) {
    return ParentRegistration(
      id: id ?? this.id,
      parentName: parentName ?? this.parentName,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      photoConsent: photoConsent ?? this.photoConsent,
      codeUsed: codeUsed ?? this.codeUsed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Daily Log Type
enum DailyLogType {
  meal,
  nap,
  toilet,
  activity,
  note,
}

/// Daily Log Status
enum DailyLogStatus {
  done,
  partial,
  skipped,
}

/// Daily Log Item
class DailyLogItem {
  final String id;
  final String classId;
  final String childId;
  final String dateKey; // YYYY-MM-DD format
  final DailyLogType type;
  final DailyLogStatus status;
  final String? details;
  final String createdByTeacherId;
  final int createdAt; // epoch milliseconds

  const DailyLogItem({
    required this.id,
    required this.classId,
    required this.childId,
    required this.dateKey,
    required this.type,
    required this.status,
    this.details,
    required this.createdByTeacherId,
    required this.createdAt,
  });

  /// JSON'dan model oluştur
  factory DailyLogItem.fromJson(Map<String, dynamic> json) {
    return DailyLogItem(
      id: json['id'] as String,
      classId: json['classId'] as String,
      childId: json['childId'] as String,
      dateKey: json['dateKey'] as String,
      type: DailyLogType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      status: DailyLogStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      details: json['details'] as String?,
      createdByTeacherId: json['createdByTeacherId'] as String,
      createdAt: json['createdAt'] as int,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'childId': childId,
      'dateKey': dateKey,
      'type': type.name,
      'status': status.name,
      'details': details,
      'createdByTeacherId': createdByTeacherId,
      'createdAt': createdAt,
    };
  }

  /// Kopyalama methodu
  DailyLogItem copyWith({
    String? id,
    String? classId,
    String? childId,
    String? dateKey,
    DailyLogType? type,
    DailyLogStatus? status,
    String? details,
    String? createdByTeacherId,
    int? createdAt,
  }) {
    return DailyLogItem(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      childId: childId ?? this.childId,
      dateKey: dateKey ?? this.dateKey,
      type: type ?? this.type,
      status: status ?? this.status,
      details: details ?? this.details,
      createdByTeacherId: createdByTeacherId ?? this.createdByTeacherId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Child (minimal)
class Child {
  final String id;
  final String name;
  final String classId;

  const Child({
    required this.id,
    required this.name,
    required this.classId,
  });

  /// JSON'dan model oluştur
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
    };
  }
}

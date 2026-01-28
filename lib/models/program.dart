import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Period Type
enum PeriodType {
  weekly,
  monthly,
}

/// Daily Plan Status
enum DailyPlanStatus {
  draft,
  approved,
  rejected,
}

/// Program Template
class ProgramTemplate {
  final String id;
  final String classId;
  final PeriodType periodType;
  final String rawText;
  final String createdByTeacherId;
  final int createdAt; // epoch ms
  final int lastParsedAt; // epoch ms
  final int version;

  const ProgramTemplate({
    required this.id,
    required this.classId,
    required this.periodType,
    required this.rawText,
    required this.createdByTeacherId,
    required this.createdAt,
    required this.lastParsedAt,
    required this.version,
  });

  factory ProgramTemplate.fromJson(Map<String, dynamic> json) {
    return ProgramTemplate(
      id: json['id'] as String,
      classId: json['classId'] as String,
      periodType: PeriodType.values.firstWhere((e) => e.name == json['periodType']),
      rawText: json['rawText'] as String,
      createdByTeacherId: json['createdByTeacherId'] as String,
      createdAt: json['createdAt'] as int,
      lastParsedAt: json['lastParsedAt'] as int,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'periodType': periodType.name,
      'rawText': rawText,
      'createdByTeacherId': createdByTeacherId,
      'createdAt': createdAt,
      'lastParsedAt': lastParsedAt,
      'version': version,
    };
  }

  // Firestore serialization
  factory ProgramTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgramTemplate(
      id: doc.id,
      classId: data['classId'] as String,
      periodType: PeriodType.values.firstWhere((e) => e.name == data['periodType']),
      rawText: data['rawText'] as String,
      createdByTeacherId: data['createdByTeacherId'] as String,
      createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
      lastParsedAt: (data['lastParsedAt'] as Timestamp).millisecondsSinceEpoch,
      version: data['version'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'periodType': periodType.name,
      'rawText': rawText,
      'createdByTeacherId': createdByTeacherId,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
      'lastParsedAt': Timestamp.fromMillisecondsSinceEpoch(lastParsedAt),
      'version': version,
    };
  }
}

/// Program Block
class ProgramBlock {
  final String id;
  final String templateId;
  final int? dayOfWeek; // 1-7 for weekly
  final String? dateKey; // YYYY-MM-DD for monthly
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String label;
  final String? notes;

  const ProgramBlock({
    required this.id,
    required this.templateId,
    this.dayOfWeek,
    this.dateKey,
    required this.startTime,
    required this.endTime,
    required this.label,
    this.notes,
  });

  factory ProgramBlock.fromJson(Map<String, dynamic> json) {
    return ProgramBlock(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      dayOfWeek: json['dayOfWeek'] as int?,
      dateKey: json['dateKey'] as String?,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      label: json['label'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'dayOfWeek': dayOfWeek,
      'dateKey': dateKey,
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'notes': notes,
    };
  }
}

/// Daily Plan Block
class DailyPlanBlock {
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String label;
  final List<String>? teacherSteps;
  final String? parentSummary;

  const DailyPlanBlock({
    required this.startTime,
    required this.endTime,
    required this.label,
    this.teacherSteps,
    this.parentSummary,
  });

  factory DailyPlanBlock.fromJson(Map<String, dynamic> json) {
    return DailyPlanBlock(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      label: json['label'] as String,
      teacherSteps: (json['teacherSteps'] as List?)?.cast<String>(),
      parentSummary: json['parentSummary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'teacherSteps': teacherSteps,
      'parentSummary': parentSummary,
    };
  }
}

/// Daily Plan
class DailyPlan {
  final String id;
  final String classId;
  final String dateKey; // YYYY-MM-DD
  final List<DailyPlanBlock> blocks;
  final DailyPlanStatus status;
  final int generatedFromTemplateVersion;
  final String? approvedByTeacherId;
  final int? approvedAt; // epoch ms

  const DailyPlan({
    required this.id,
    required this.classId,
    required this.dateKey,
    required this.blocks,
    required this.status,
    required this.generatedFromTemplateVersion,
    this.approvedByTeacherId,
    this.approvedAt,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id'] as String,
      classId: json['classId'] as String,
      dateKey: json['dateKey'] as String,
      blocks: (json['blocks'] as List)
          .map((e) => DailyPlanBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: DailyPlanStatus.values.firstWhere((e) => e.name == json['status']),
      generatedFromTemplateVersion: json['generatedFromTemplateVersion'] as int,
      approvedByTeacherId: json['approvedByTeacherId'] as String?,
      approvedAt: json['approvedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'dateKey': dateKey,
      'blocks': blocks.map((e) => e.toJson()).toList(),
      'status': status.name,
      'generatedFromTemplateVersion': generatedFromTemplateVersion,
      'approvedByTeacherId': approvedByTeacherId,
      'approvedAt': approvedAt,
    };
  }

  // Firestore serialization
  factory DailyPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyPlan(
      id: doc.id,
      classId: data['classId'] as String,
      dateKey: data['dateKey'] as String,
      blocks: (data['blocks'] as List)
          .map((e) => DailyPlanBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: DailyPlanStatus.values.firstWhere((e) => e.name == data['status']),
      generatedFromTemplateVersion: data['generatedFromTemplateVersion'] as int,
      approvedByTeacherId: data['approvedByTeacherId'] as String?,
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] as Timestamp).millisecondsSinceEpoch 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'dateKey': dateKey,
      'blocks': blocks.map((e) => e.toJson()).toList(),
      'status': status.name,
      'generatedFromTemplateVersion': generatedFromTemplateVersion,
      'approvedByTeacherId': approvedByTeacherId,
      'approvedAt': approvedAt != null 
          ? Timestamp.fromMillisecondsSinceEpoch(approvedAt!) 
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  DailyPlan copyWith({
    DailyPlanStatus? status,
    List<DailyPlanBlock>? blocks,
    String? approvedByTeacherId,
    int? approvedAt,
  }) {
    return DailyPlan(
      id: id,
      classId: classId,
      dateKey: dateKey,
      blocks: blocks ?? this.blocks,
      status: status ?? this.status,
      generatedFromTemplateVersion: generatedFromTemplateVersion,
      approvedByTeacherId: approvedByTeacherId ?? this.approvedByTeacherId,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

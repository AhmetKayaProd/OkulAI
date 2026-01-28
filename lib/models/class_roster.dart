/// Class Roster Item - Sınıf listesindeki öğrenci
class ClassRosterItem {
  final String studentName;
  final String parentName;
  final bool photoConsent;

  const ClassRosterItem({
    required this.studentName,
    required this.parentName,
    required this.photoConsent,
  });

  /// JSON'dan model oluştur
  factory ClassRosterItem.fromJson(Map<String, dynamic> json) {
    return ClassRosterItem(
      studentName: json['studentName'] as String,
      parentName: json['parentName'] as String,
      photoConsent: json['photoConsent'] as bool? ?? false,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'studentName': studentName,
      'parentName': parentName,
      'photoConsent': photoConsent,
    };
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/invite_code.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/models/class_roster.dart';
import 'package:kresai/models/school.dart';
import 'package:kresai/models/class_info.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/services/notification_store.dart';
import 'package:kresai/services/activity_log_store.dart';

/// Registration Store - Singleton
/// Tüm kayıt verilerini yönetir ve persist eder
class RegistrationStore {
  static final RegistrationStore _instance = RegistrationStore._internal();
  factory RegistrationStore() => _instance;
  RegistrationStore._internal();

  static const String _teacherCodeKey = 'teacher_invite_code';
  static const String _parentCodeKey = 'parent_invite_code';
  static const String _teacherRegistrationsKey = 'teacher_registrations';
  static const String _parentRegistrationsKey = 'parent_registrations';
  static const String _classRosterKey = 'class_roster';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InviteCode? _teacherCode;
  InviteCode? _parentCode;
  List<TeacherRegistration> _teacherRegistrations = [];
  List<ParentRegistration> _parentRegistrations = [];
  List<ClassRosterItem> _classRoster = [];
  bool _isLoaded = false;

  /// Getters
  InviteCode? get teacherCode => _teacherCode;
  InviteCode? get parentCode => _parentCode;
  List<TeacherRegistration> get teacherRegistrations => _teacherRegistrations;
  List<ParentRegistration> get parentRegistrations => _parentRegistrations;
  List<ClassRosterItem> get classRoster => _classRoster;
  bool get isLoaded => _isLoaded;

  /// Pending counts
  int get pendingTeachersCount =>
      _teacherRegistrations.where((r) => r.status == RegistrationStatus.pending).length;
  int get pendingParentsCount =>
      _parentRegistrations.where((r) => r.status == RegistrationStatus.pending).length;

  /// Tüm verileri yükle
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Teacher code
      final teacherCodeJson = prefs.getString(_teacherCodeKey);
      if (teacherCodeJson != null) {
        _teacherCode = InviteCode.fromJson(
          jsonDecode(teacherCodeJson) as Map<String, dynamic>,
        );
      }

      // Parent code
      final parentCodeJson = prefs.getString(_parentCodeKey);
      if (parentCodeJson != null) {
        _parentCode = InviteCode.fromJson(
          jsonDecode(parentCodeJson) as Map<String, dynamic>,
        );
      }

      // Teacher registrations
      final teacherRegsJson = prefs.getString(_teacherRegistrationsKey);
      if (teacherRegsJson != null) {
        final list = jsonDecode(teacherRegsJson) as List;
        _teacherRegistrations = list
            .map((e) => TeacherRegistration.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Parent registrations
      final parentRegsJson = prefs.getString(_parentRegistrationsKey);
      if (parentRegsJson != null) {
        final list = jsonDecode(parentRegsJson) as List;
        _parentRegistrations = list
            .map((e) => ParentRegistration.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Class roster
      final rosterJson = prefs.getString(_classRosterKey);
      if (rosterJson != null) {
        final list = jsonDecode(rosterJson) as List;
        _classRoster = list
            .map((e) => ClassRosterItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      _isLoaded = true;
      
      // 🚀 AUTO-INITIALIZE: Create test registrations if none exist
      if (_teacherRegistrations.isEmpty && _parentRegistrations.isEmpty) {
        await _initializeTestRegistrations();
      }
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// Initialize test registrations for easy testing
  Future<void> _initializeTestRegistrations() async {
    // Create approved teacher
    final teacher = TeacherRegistration(
      id: 'teacher_test_1',
      fullName: 'Test Öğretmen',
      className: 'Papatyalar Sınıfı',
      classSize: 15,
      codeUsed: 'TEST123',
      status: RegistrationStatus.approved,
      createdAt: DateTime.now(),
    );
    
    // Create approved parent
    final parent = ParentRegistration(
      id: 'parent_test_1',
      parentName: 'Test Veli',
      studentName: 'Test Çocuk',
      className: 'Papatyalar Sınıfı', // Öğretmen ile aynı sınıf
      photoConsent: true,
      codeUsed: 'TEST123',
      status: RegistrationStatus.approved,
      createdAt: DateTime.now(),
    );
    
    _teacherRegistrations = [teacher];
    _parentRegistrations = [parent];
    
    await _saveTeacherRegistrations();
    await _saveParentRegistrations();
    
    // Also create parent code for additional parents
    await _initializeParentCode();
  }

  /// Initialize parent invite code
  Future<void> _initializeParentCode() async {
    final parentCode = InviteCode(
      type: InviteCodeType.parent,
      code: 'VELI2024',
      schoolId: 'demo_school',
      classId: 'demo_class_papatyalar',
      className: 'Papatyalar Sınıfı',
      isActive: true,
      createdAt: DateTime.now(),
    );
    await saveParentCode(parentCode);
    
    // Add second parent with this code
    final parent2 = ParentRegistration(
      id: 'parent_ayse_1',
      parentName: 'Ayşe Yılmaz',
      studentName: 'Can Yılmaz',
      className: 'Papatyalar Sınıfı', // Öğretmen ile aynı sınıf
      photoConsent: true,
      codeUsed: 'VELI2024',
      status: RegistrationStatus.approved,
      createdAt: DateTime.now(),
    );
    
    _parentRegistrations.add(parent2);
    await _saveParentRegistrations();
  }

  /// Teacher code kaydet
  Future<bool> saveTeacherCode(InviteCode code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(code.toJson());
      final success = await prefs.setString(_teacherCodeKey, jsonString);
      if (success) {
        _teacherCode = code;
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Parent code kaydet
  Future<bool> saveParentCode(InviteCode code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(code.toJson());
      final success = await prefs.setString(_parentCodeKey, jsonString);
      if (success) {
        _parentCode = code;
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Teacher code sil
  Future<bool> deleteTeacherCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_teacherCodeKey);
      if (success) {
        _teacherCode = null;
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Parent code sil
  Future<bool> deleteParentCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_parentCodeKey);
      if (success) {
        _parentCode = null;
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Teacher registration ekle
  Future<bool> addTeacherRegistration(TeacherRegistration registration) async {
    try {
      _teacherRegistrations.add(registration);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _teacherRegistrations.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_teacherRegistrationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Parent registration ekle (duplicate check ile)
  Future<String?> addParentRegistration(ParentRegistration registration) async {
    try {
      // Duplicate check
      final duplicate = _parentRegistrations.any(
        (r) =>
            r.parentName.toLowerCase() == registration.parentName.toLowerCase() &&
            r.studentName.toLowerCase() == registration.studentName.toLowerCase(),
      );

      if (duplicate) {
        return 'Bu veli ve öğrenci adıyla zaten bir başvuru mevcut.';
      }

      _parentRegistrations.add(registration);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _parentRegistrations.map((e) => e.toJson()).toList(),
      );
      final success = await prefs.setString(_parentRegistrationsKey, jsonString);
      return success ? null : 'Kaydetme hatası';
    } catch (e) {
      return 'Kaydetme hatası';
    }
  }

  /// Teacher registration güncelle
  Future<bool> updateTeacherRegistration(TeacherRegistration updated) async {
    try {
      final index = _teacherRegistrations.indexWhere((r) => r.id == updated.id);
      if (index == -1) return false;

      _teacherRegistrations[index] = updated;
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _teacherRegistrations.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_teacherRegistrationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Parent registration güncelle
  Future<bool> updateParentRegistration(ParentRegistration updated) async {
    try {
      final index = _parentRegistrations.indexWhere((r) => r.id == updated.id);
      if (index == -1) return false;

      _parentRegistrations[index] = updated;
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _parentRegistrations.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_parentRegistrationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Helper to save teacher registrations
  Future<bool> _saveTeacherRegistrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _teacherRegistrations.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_teacherRegistrationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Helper to save parent registrations
  Future<bool> _saveParentRegistrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _parentRegistrations.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_parentRegistrationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Teacher başvurusunu onayla
  Future<bool> approveTeacher(String registrationId) async {
    try {
      final index = _teacherRegistrations.indexWhere((r) => r.id == registrationId);
      if (index == -1) return false;

      final teacher = _teacherRegistrations[index];
      _teacherRegistrations[index] = teacher.copyWith(
        status: RegistrationStatus.approved,
      );

      final success = await _saveTeacherRegistrations();
      
      if (success) {
        // Notification oluştur
        final notification = NotificationItem(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.approved,
          targetRole: 'teacher',
          targetId: registrationId,
          seen: false,
          createdAt: DateTime.now(),
        );
        await NotificationStore().addNotification(notification);
        
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.teacherApproved,
          actorRole: ActorRole.admin,
          actorId: 'admin',
          classId: teacher.className,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Öğretmen onaylandı: ${teacher.fullName}',
        );
        await ActivityLogStore().addEvent(event);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Teacher başvurusunu reddet + bildirim oluştur
  Future<bool> rejectTeacherRegistration(String registrationId) async {
    try {
      final index = _teacherRegistrations.indexWhere((r) => r.id == registrationId);
      if (index == -1) return false;

      final teacher = _teacherRegistrations[index];
      _teacherRegistrations[index] = teacher.copyWith(
        status: RegistrationStatus.rejected,
      );

      final success = await _saveTeacherRegistrations();
      
      if (success) {
        // Bildirim oluştur
        final notification = NotificationItem(
          id: '${registrationId}_rejected_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.rejected,
          targetRole: 'teacher',
          targetId: registrationId,
          seen: false,
          createdAt: DateTime.now(),
        );
        await NotificationStore().addNotification(notification);
        
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.teacherRejected,
          actorRole: ActorRole.admin,
          actorId: 'admin',
          classId: teacher.className,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Öğretmen reddedildi: ${teacher.fullName}',
        );
        await ActivityLogStore().addEvent(event);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Parent registration onayla + roster'a ekle + bildirim oluştur
  Future<bool> approveParentRegistration(String registrationId) async {
    try {
      final registration = _parentRegistrations.firstWhere((r) => r.id == registrationId);
      
      // Status güncelle
      final updated = registration.copyWith(status: RegistrationStatus.approved);
      final statusSuccess = await updateParentRegistration(updated);
      
      if (!statusSuccess) return false;

      // Roster'a ekle (duplicate check)
      final alreadyInRoster = _classRoster.any(
        (item) => item.studentName.toLowerCase() == registration.studentName.toLowerCase(),
      );

      if (!alreadyInRoster) {
        _classRoster.add(ClassRosterItem(
          studentName: registration.studentName,
          parentName: registration.parentName,
          photoConsent: registration.photoConsent,
        ));

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(
          _classRoster.map((e) => e.toJson()).toList(),
        );
        await prefs.setString(_classRosterKey, jsonString);
      }

      // Bildirim oluştur
      final notification = NotificationItem(
        id: '${registrationId}_approved_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.approved,
        targetRole: 'parent',
        targetId: registrationId,
        seen: false,
        createdAt: DateTime.now(),
      );
      await NotificationStore().addNotification(notification);
      
      // Activity log
      final event = ActivityEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        type: ActivityEventType.parentApproved,
        actorRole: ActorRole.teacher,
        actorId: 'teacher',
        classId: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        description: 'Veli onaylandı: ${registration.parentName}',
      );
      await ActivityLogStore().addEvent(event);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parent registration reddet + bildirim oluştur
  Future<bool> rejectParentRegistration(String registrationId) async {
    try {
      final registration = _parentRegistrations.firstWhere((r) => r.id == registrationId);
      final updated = registration.copyWith(status: RegistrationStatus.rejected);
      final success = await updateParentRegistration(updated);
      
      if (success) {
        // Bildirim oluştur
        final notification = NotificationItem(
          id: '${registrationId}_rejected_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.rejected,
          targetRole: 'parent',
          targetId: registrationId,
          seen: false,
          createdAt: DateTime.now(),
        );
        await NotificationStore().addNotification(notification);
        
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.parentRejected,
          actorRole: ActorRole.teacher,
          actorId: 'teacher',
          classId: null,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Veli reddedildi: ${registration.parentName}',
        );
        await ActivityLogStore().addEvent(event);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Teacher code doğrula
  bool validateTeacherCode(String code) {
    return _teacherCode != null &&
        _teacherCode!.isActive &&
        _teacherCode!.code == code;
  }

  /// Parent code doğrula
  bool validateParentCode(String code) {
    return _parentCode != null && _parentCode!.isActive && _parentCode!.code == code;
  }

  /// Current user'ın teacher registration'ını bul
  TeacherRegistration? getCurrentTeacherRegistration() {
    if (_teacherRegistrations.isEmpty) return null;
    // En son kayıt
    return _teacherRegistrations.last;
  }

  /// Current user'ın parent registration'ını bul
  ParentRegistration? getCurrentParentRegistration() {
    if (_parentRegistrations.isEmpty) return null;
    // En son kayıt
    return _parentRegistrations.last;
  }

  /// Pending teacher registrations
  List<TeacherRegistration> getPendingTeachers() {
    return _teacherRegistrations
        .where((r) => r.status == RegistrationStatus.pending)
        .toList();
  }

  /// Pending parent registrations
  List<ParentRegistration> getPendingParents() {
    return _parentRegistrations
        .where((r) => r.status == RegistrationStatus.pending)
        .toList();
  }

  /// Teacher registration ID ile bul
  TeacherRegistration? getTeacherRegistrationById(String id) {
    try {
      return _teacherRegistrations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Parent registration ID ile bul
  ParentRegistration? getParentRegistrationById(String id) {
    try {
      return _parentRegistrations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Parent consent güncelle
  Future<bool> updateParentConsent(bool consent) async {
    try {
      final currentParent = getCurrentParentRegistration();
      if (currentParent == null) return false;

      final updated = currentParent.copyWith(photoConsent: consent);
      return await updateParentRegistration(updated);
    } catch (e) {
      return false;
    }
  }

  // ==================== FIRESTORE METHODS ====================

  /// Generate random invite code
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new school
  Future<School?> createSchool({
    required String name,
    required String adminId,
  }) async {
    try {
      final schoolId = 'school_${DateTime.now().millisecondsSinceEpoch}';
      final school = School(
        id: schoolId,
        name: name,
        adminId: adminId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('schools')
          .doc(schoolId)
          .set(school.toJson());

      print('DEBUG RegistrationStore: Created school $schoolId in Firestore');
      return school;
    } catch (e) {
      print('DEBUG RegistrationStore: Error creating school: $e');
      return null;
    }
  }

  /// Create a new class
  Future<ClassInfo?> createClass({
    required String name,
    required String schoolId,
    required String teacherId,
    required int size,
  }) async {
    try {
      final classId = 'class_${DateTime.now().millisecondsSinceEpoch}';
      final classInfo = ClassInfo(
        id: classId,
        name: name,
        schoolId: schoolId,
        teacherId: teacherId,
        size: size,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('classes')
          .doc(classId)
          .set(classInfo.toJson());

      print('DEBUG RegistrationStore: Created class $classId in Firestore');
      return classInfo;
    } catch (e) {
      print('DEBUG RegistrationStore: Error creating class: $e');
      return null;
    }
  }

  /// Generate and save invite code
  Future<InviteCode?> generateInviteCode({
    required InviteCodeType type,
    required String schoolId,
    String? classId,
    String? className,
    String? createdBy,
  }) async {
    try {
      final code = _generateRandomCode();
      final inviteCode = InviteCode(
        type: type,
        code: code,
        schoolId: schoolId,
        classId: classId,
        className: className,
        createdBy: createdBy,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('inviteCodes')
          .doc(code)
          .set(inviteCode.toJson());

      print('DEBUG RegistrationStore: Generated invite code $code in Firestore');
      return inviteCode;
    } catch (e) {
      print('DEBUG RegistrationStore: Error generating invite code: $e');
      return null;
    }
  }

  /// Validate and get invite code
  Future<InviteCode?> validateInviteCode(String code) async {
    try {
      final doc = await _firestore
          .collection('inviteCodes')
          .doc(code)
          .get();

      if (!doc.exists) {
        print('DEBUG RegistrationStore: Invite code $code not found');
        return null;
      }

      final inviteCode = InviteCode.fromJson(doc.data()!);
      
      if (!inviteCode.isActive) {
        print('DEBUG RegistrationStore: Invite code $code is inactive');
        return null;
      }

      print('DEBUG RegistrationStore: Validated invite code $code');
      return inviteCode;
    } catch (e) {
      print('DEBUG RegistrationStore: Error validating invite code: $e');
      return null;
    }
  }

  /// Save teacher registration to Firestore
  Future<bool> saveTeacherRegistrationToFirestore(TeacherRegistration registration) async {
    try {
      await _firestore
          .collection('registrations')
          .doc('teachers')
          .collection('items')
          .doc(registration.id)
          .set(registration.toJson());

      print('DEBUG RegistrationStore: Saved teacher registration ${registration.id} to Firestore');
      return true;
    } catch (e) {
      print('DEBUG RegistrationStore: Error saving teacher registration: $e');
      return false;
    }
  }

  /// Save parent registration to Firestore
  Future<bool> saveParentRegistrationToFirestore(ParentRegistration registration) async {
    try {
      await _firestore
          .collection('registrations')
          .doc('parents')
          .collection('items')
          .doc(registration.id)
          .set(registration.toJson());

      print('DEBUG RegistrationStore: Saved parent registration ${registration.id} to Firestore');
      return true;
    } catch (e) {
      print('DEBUG RegistrationStore: Error saving parent registration: $e');
      return false;
    }
  }

  /// Load teacher registrations from Firestore
  Future<List<TeacherRegistration>> loadTeacherRegistrationsFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('registrations')
          .doc('teachers')
          .collection('items')
          .get();

      final registrations = snapshot.docs
          .map((doc) => TeacherRegistration.fromJson(doc.data()))
          .toList();

      print('DEBUG RegistrationStore: Loaded ${registrations.length} teacher registrations from Firestore');
      return registrations;
    } catch (e) {
      print('DEBUG RegistrationStore: Error loading teacher registrations: $e');
      return [];
    }
  }

  /// Load parent registrations from Firestore
  Future<List<ParentRegistration>> loadParentRegistrationsFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('registrations')
          .doc('parents')
          .collection('items')
          .get();

      final registrations = snapshot.docs
          .map((doc) => ParentRegistration.fromJson(doc.data()))
          .toList();

      print('DEBUG RegistrationStore: Loaded ${registrations.length} parent registrations from Firestore');
      return registrations;
    } catch (e) {
      print('DEBUG RegistrationStore: Error loading parent registrations: $e');
      return [];
    }
  }
}

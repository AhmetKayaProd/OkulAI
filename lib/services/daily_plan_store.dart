import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/program.dart';

/// Firestore-enabled Daily Plan Store - Singleton
/// Dual-write to SharedPreferences and Firestore for safe migration
class DailyPlanStore {
  static final DailyPlanStore _instance = DailyPlanStore._internal();
  factory DailyPlanStore() => _instance;
  DailyPlanStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support
  static const String _plansKey = 'daily_plans';

  List<DailyPlan> _plans = [];
  bool _isLoaded = false;

  /// Getters
  bool get isLoaded => _isLoaded;
  List<DailyPlan> get plans => List.unmodifiable(_plans);

  /// Load (SharedPreferences only for now)
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_plansKey);
      
      if (plansJson != null) {
        final list = jsonDecode(plansJson) as List;
        _plans = list.map((e) => DailyPlan.fromJson(e as Map<String, dynamic>)).toList();
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  // ==================== FIRESTORE METHODS ====================

  /// Watch daily plans for a class and date range (real-time updates)
  Stream<List<DailyPlan>> watchDailyPlans({
    required String classId,
    String? dateKey, // Optional: filter by specific date
  }) {
    Query query = _firestore
        .collection('schools/$_schoolId/dailyPlans')
        .where('classId', isEqualTo: classId);
    
    if (dateKey != null) {
      query = query.where('dateKey', isEqualTo: dateKey);
    }

    return query
        .orderBy('dateKey', descending: true)
        .limit(30) // Last 30 days
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => DailyPlan.fromFirestore(doc)).toList()
        );
  }

  /// Save or update daily plan to Firestore
  Future<bool> savePlanToFirestore(DailyPlan plan) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Fallback to SharedPreferences only
        return await _savePlanLocal(plan);
      }

      // Write to Firestore
      final docRef = _firestore
          .collection('schools/$_schoolId/dailyPlans')
          .doc(plan.id);
      
      await docRef.set(plan.toFirestore());

      // Also update local cache
      _plans.removeWhere((p) => p.id == plan.id);
      _plans.add(plan);
      await _savePlans();

      return true;
    } catch (e) {
      // Fallback to SharedPreferences
      return await _savePlanLocal(plan);
    }
  }

  /// Approve plan (Firestore)
  Future<bool> approvePlanInFirestore({
    required String planId,
    required String teacherId,
  }) async {
    try {
      final docRef = _firestore
          .collection('schools/$_schoolId/dailyPlans')
          .doc(planId);

      await docRef.update({
        'status': DailyPlanStatus.approved.name,
        'approvedByTeacherId': teacherId,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex != -1) {
        _plans[planIndex] = _plans[planIndex].copyWith(
          status: DailyPlanStatus.approved,
          approvedByTeacherId: teacherId,
          approvedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _savePlans();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete plan from Firestore
  Future<bool> deletePlanFromFirestore(String planId) async {
    try {
      await _firestore
          .collection('schools/$_schoolId/dailyPlans')
          .doc(planId)
          .delete();

      // Update local cache
      _plans.removeWhere((p) => p.id == planId);
      await _savePlans();

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== LEGACY METHODS (SharedPreferences) ====================

  /// Get or generate draft (legacy SharedPreferences method)
  Future<DailyPlan?> getOrGenerateDraft({
    required String classId,
    required String dateKey,
    required List<DailyPlanBlock> blocks,
    required int templateVersion,
  }) async {
    try {
      // Check existing
      final existing = _plans.where(
        (p) => p.classId == classId && p.dateKey == dateKey,
      ).firstOrNull;

      if (existing != null) {
        return existing;
      }

      // Create draft
      final draft = DailyPlan(
        id: 'plan_${classId}_${dateKey}_${DateTime.now().millisecondsSinceEpoch}',
        classId: classId,
        dateKey: dateKey,
        blocks: blocks,
        status: DailyPlanStatus.draft,
        generatedFromTemplateVersion: templateVersion,
      );

      _plans.add(draft);
      await _savePlans();

      return draft;
    } catch (e) {
      return null;
    }
  }

  /// Approve plan (legacy)
  Future<bool> approvePlan(String planId, String teacherId) async {
    try {
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) return false;

      _plans[planIndex] = _plans[planIndex].copyWith(
        status: DailyPlanStatus.approved,
        approvedByTeacherId: teacherId,
        approvedAt: DateTime.now().millisecondsSinceEpoch,
      );

      return await _savePlans();
    } catch (e) {
      return false;
    }
  }

  /// Get plans for date (legacy)
  List<DailyPlan> getPlansForDate(String classId, String dateKey) {
    return _plans.where((p) => p.classId == classId && p.dateKey == dateKey).toList();
  }

  /// Get approved plan for date (legacy)
  DailyPlan? getApprovedPlan(String classId, String dateKey) {
    try {
      return _plans.firstWhere(
        (p) => p.classId == classId && 
               p.dateKey == dateKey && 
               p.status == DailyPlanStatus.approved,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get draft plan for date (legacy)
  DailyPlan? getDraftPlan(String classId, String dateKey) {
    try {
      return _plans.firstWhere(
        (p) => p.classId == classId && 
               p.dateKey == dateKey && 
               p.status == DailyPlanStatus.draft,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update plan blocks (legacy)
  Future<bool> updatePlanBlocks(String planId, List<DailyPlanBlock> blocks) async {
    try {
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) return false;

      _plans[planIndex] = _plans[planIndex].copyWith(blocks: blocks);
      return await _savePlans();
    } catch (e) {
      return false;
    }
  }

  // Private helpers
  Future<bool> _savePlanLocal(DailyPlan plan) async {
    try {
      _plans.removeWhere((p) => p.id == plan.id);
      _plans.add(plan);
      return await _savePlans();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _savePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_plans.map((p) => p.toJson()).toList());
      return await prefs.setString(_plansKey, json);
    } catch (e) {
      return false;
    }
  }
}

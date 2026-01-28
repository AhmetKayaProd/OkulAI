import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/program.dart';

/// Firestore-enabled Program Store - Singleton
/// Dual-write to SharedPreferences and Firestore for safe migration
class ProgramStore {
  static final ProgramStore _instance = ProgramStore._internal();
  factory ProgramStore() => _instance;
  ProgramStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support
  static const String _templatesKey = 'program_templates';
  static const String _blocksKey = 'program_blocks';

  List<ProgramTemplate> _templates = [];
  List<ProgramBlock> _blocks = [];
  bool _isLoaded = false;

  /// Getters
  bool get isLoaded => _isLoaded;
  List<ProgramTemplate> get templates => List.unmodifiable(_templates);
  List<ProgramBlock> get blocks => List.unmodifiable(_blocks);

  /// Load all data (from SharedPreferences for now, will add Firestore sync)
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Templates
      final templatesJson = prefs.getString(_templatesKey);
      if (templatesJson != null) {
        final list = jsonDecode(templatesJson) as List;
        _templates = list.map((e) => ProgramTemplate.fromJson(e as Map<String, dynamic>)).toList();
      }

      // Blocks
      final blocksJson = prefs.getString(_blocksKey);
      if (blocksJson != null) {
        final list = jsonDecode(blocksJson) as List;
        _blocks = list.map((e) => ProgramBlock.fromJson(e as Map<String, dynamic>)).toList();
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  // ==================== FIRESTORE METHODS ====================

  /// Watch templates for a class (real-time updates)
  Stream<List<ProgramTemplate>> watchTemplates(String classId) {
    return _firestore
        .collection('schools/$_schoolId/templates')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => ProgramTemplate.fromFirestore(doc)).toList()
        );
  }

  /// Save template to Firestore (dual-write to SharedPreferences)
  Future<bool> saveTemplateToFirestore(ProgramTemplate template) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Fallback to SharedPreferences only
        return await saveTemplate(template);
      }

      // Write to Firestore
      final docRef = _firestore
          .collection('schools/$_schoolId/templates')
          .doc(template.id);
      
      await docRef.set(template.toFirestore());

      // Also update local cache (SharedPreferences backup)
      _templates.removeWhere((t) => t.id == template.id);
      _templates.add(template);
      await _saveTemplates();

      return true;
    } catch (e) {
      // If Firestore fails, still save to SharedPreferences
      return await saveTemplate(template);
    }
  }

  /// Delete template from Firestore
  Future<bool> deleteTemplateFromFirestore(String templateId) async {
    try {
      await _firestore
          .collection('schools/$_schoolId/templates')
          .doc(templateId)
          .delete();

      // Also update local cache
      _templates.removeWhere((t) => t.id == templateId);
      await _saveTemplates();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Watch program blocks for a template
  Stream<List<ProgramBlock>> watchBlocks(String templateId) {
    return _firestore
        .collection('schools/$_schoolId/templates/$templateId/blocks')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) {
            final data = doc.data();
            return ProgramBlock.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList()
        );
  }

  /// Save program blocks to Firestore
  Future<bool> saveBlocksToFirestore(String templateId, List<ProgramBlock> blocks) async {
    try {
      final batch = _firestore.batch();
      final blocksCollection = _firestore.collection('schools/$_schoolId/templates/$templateId/blocks');

      // Delete old blocks
      final oldBlocks = await blocksCollection.get();
      for (final doc in oldBlocks.docs) {
        batch.delete(doc.reference);
      }

      // Add new blocks
      for (final block in blocks) {
        final docRef = blocksCollection.doc(block.id);
        batch.set(docRef, block.toJson());
      }

      await batch.commit();

      // Update local cache
      _blocks.removeWhere((b) => b.templateId == templateId);
      _blocks.addAll(blocks);
      await _saveBlocks();

      return true;
    } catch (e) {
      // Fallback to SharedPreferences
      return await saveParsedBlocks(templateId, blocks);
    }
  }

  // ==================== LEGACY METHODS (SharedPreferences) ====================

  /// Save template (SharedPreferences only - legacy)
  Future<bool> saveTemplate(ProgramTemplate template) async {
    try {
      _templates.removeWhere((t) => t.classId == template.classId);
      _templates.add(template);
      return await _saveTemplates();
    } catch (e) {
      return false;
    }
  }

  /// Save parsed blocks (SharedPreferences only - legacy)
  Future<bool> saveParsedBlocks(String templateId, List<ProgramBlock> blocks) async {
    try {
      _blocks.removeWhere((b) => b.templateId == templateId);
      _blocks.addAll(blocks);
      return await _saveBlocks();
    } catch (e) {
      return false;
    }
  }

  /// Get template by class
  ProgramTemplate? getTemplate(String classId) {
    try {
      return _templates.firstWhere((t) => t.classId == classId);
    } catch (e) {
      return null;
    }
  }

  /// Get blocks for date (weekly: dayOfWeek, monthly: dateKey)
  List<ProgramBlock> getBlocksForDate(String templateId, {int? dayOfWeek, String? dateKey}) {
    if (dayOfWeek != null) {
      return _blocks.where((b) => b.templateId == templateId && b.dayOfWeek == dayOfWeek).toList();
    } else if (dateKey != null) {
      return _blocks.where((b) => b.templateId == templateId && b.dateKey == dateKey).toList();
    }
    return [];
  }

  // Private helpers
  Future<bool> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_templates.map((t) => t.toJson()).toList());
      return await prefs.setString(_templatesKey, json);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveBlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_blocks.map((b) => b.toJson()).toList());
      return await prefs.setString(_blocksKey, json);
    } catch (e) {
      return false;
    }
  }
}

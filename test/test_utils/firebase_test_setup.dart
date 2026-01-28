import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test setup utilities for Firebase mocking
class FirebaseTestSetup {
  static bool _initialized = false;

  /// Initialize Firebase for testing
  static Future<void> initialize() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up method channel mocking for Firebase
    setupFirebaseAuthMocks();
    setupFirestoreMocks();

    _initialized = true;
  }

  /// Mock Firebase Auth
  static void setupFirebaseAuthMocks() {
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Auth#signInAnonymously') {
        return {
          'user': {
            'uid': 'test_user_123',
            'email': 'test@example.com',
            'displayName': 'Test User',
          }
        };
      }
      return null;
    });
  }

  /// Mock Firestore
  static void setupFirestoreMocks() {
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      // Return empty data for queries
      if (methodCall.method == 'Query#snapshots') {
        return {'documents': []};
      }
      return null;
    });
  }

  /// Create a mock user for testing
  static User createMockUser({
    String uid = 'test_user_123',
    String email = 'test@example.com',
    String? displayName,
  }) {
    // Note: Cannot create real User instance, return mock data
    // Tests should use uid directly
    return _MockUser(uid: uid, email: email, displayName: displayName);
  }
}

/// Simple mock User class for testing
class _MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  _MockUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

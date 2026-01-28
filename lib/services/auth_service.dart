import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication Service
/// 
/// Provides centralized authentication operations including:
/// - Email/Password sign in and sign up
/// - Password reset
/// - Sign out
/// - Auth state monitoring
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Stream of auth state changes
  /// Listen to this to react to login/logout events
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Sign in with email and password
  /// 
  /// Returns UserCredential on success, null on failure
  /// Throws FirebaseAuthException with error details
  Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      // Re-throw with user-friendly message
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Giriş yapılamadı: ${e.toString()}');
    }
  }

  /// Sign in anonymously for Dev Mode
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Dev girişi yapılamadı: $e');
    }
  }

  /// Sign up with email, password, and full name
  /// 
  /// Creates a new Firebase user account and sets display name
  /// Returns UserCredential on success
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName.trim());
      
      // Reload user to get updated data
      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Hesap oluşturulamadı: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Çıkış yapılamadı: ${e.toString()}');
    }
  }

  /// Send password reset email
  /// 
  /// Sends a password reset link to the provided email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Şifre sıfırlama maili gönderilemedi: ${e.toString()}');
    }
  }

  /// Delete current user account
  /// 
  /// CAUTION: This permanently deletes the user
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Hesap silinemedi: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu email adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre. Lütfen tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz email adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda desteklenmiyor.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu: ${e.message ?? e.code}';
    }
  }
}

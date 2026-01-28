import 'dart:math';

/// Firestore Retry Helper
/// Provides retry logic with exponential backoff for Firestore operations
class FirestoreRetryHelper {
  /// Execute a Firestore operation with retry logic
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          print('❌ ERROR: $operationName failed after $maxRetries attempts: $e');
          return null;
        }
        
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: pow(2, attempt - 1).toInt());
        print('🔄 RETRY: $operationName attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    
    return null;
  }
  
  /// Execute a Firestore operation with retry logic (throws on final failure)
  static Future<T> executeWithRetryOrThrow<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    dynamic lastError;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempt++;
        
        if (attempt >= maxRetries) {
          print('❌ ERROR: $operationName failed after $maxRetries attempts: $e');
          throw Exception('$operationName failed after $maxRetries attempts: $e');
        }
        
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: pow(2, attempt - 1).toInt());
        print('🔄 RETRY: $operationName attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('$operationName failed: $lastError');
  }
}

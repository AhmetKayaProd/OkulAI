import 'dart:collection';

/// Firestore Rate Limiter
/// Prevents quota overruns by limiting write operations per collection
class FirestoreRateLimiter {
  static final FirestoreRateLimiter _instance = FirestoreRateLimiter._internal();
  factory FirestoreRateLimiter() => _instance;
  FirestoreRateLimiter._internal();

  final Map<String, Queue<DateTime>> _requestTimestamps = {};
  
  // Max 100 writes per minute per collection
  static const int maxWritesPerMinute = 100;
  static const Duration timeWindow = Duration(minutes: 1);

  /// Check if a write operation is allowed for the given collection
  Future<bool> canWrite(String collection) async {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[collection] ?? Queue<DateTime>();
    
    // Remove old timestamps outside time window
    while (timestamps.isNotEmpty && now.difference(timestamps.first) > timeWindow) {
      timestamps.removeFirst();
    }
    
    if (timestamps.length >= maxWritesPerMinute) {
      print('🚨 RATE LIMIT: $collection exceeded $maxWritesPerMinute writes/min');
      return false;
    }
    
    timestamps.add(now);
    _requestTimestamps[collection] = timestamps;
    return true;
  }

  /// Record a write operation (for monitoring)
  void recordWrite(String collection) {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[collection] ?? Queue<DateTime>();
    timestamps.add(now);
    _requestTimestamps[collection] = timestamps;
  }

  /// Get current write count for a collection in the last minute
  int getCurrentWriteCount(String collection) {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[collection] ?? Queue<DateTime>();
    
    // Remove old timestamps
    while (timestamps.isNotEmpty && now.difference(timestamps.first) > timeWindow) {
      timestamps.removeFirst();
    }
    
    return timestamps.length;
  }

  /// Reset all counters (for testing)
  void reset() {
    _requestTimestamps.clear();
  }
}

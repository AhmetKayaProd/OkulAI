/// Firebase Monitoring
/// Client-side monitoring for anomaly detection and alerting
class FirebaseMonitoring {
  static final FirebaseMonitoring _instance = FirebaseMonitoring._internal();
  factory FirebaseMonitoring() => _instance;
  FirebaseMonitoring._internal();

  int _writeCount = 0;
  int _readCount = 0;
  int _errorCount = 0;
  DateTime _lastReset = DateTime.now();
  
  static const int writeAlertThreshold = 1000; // Alert if >1000 writes/hour
  static const int errorAlertThreshold = 50; // Alert if >50 errors/hour
  
  /// Record a Firestore write operation
  void recordWrite(String collection) {
    _writeCount++;
    _checkAndReset();
    
    if (_writeCount > writeAlertThreshold) {
      _sendAlert('High write volume detected: $_writeCount writes in last hour');
    }
  }
  
  /// Record a Firestore read operation
  void recordRead(String collection) {
    _readCount++;
    _checkAndReset();
  }
  
  /// Record a Firestore error
  void recordError(String operation, dynamic error) {
    _errorCount++;
    _checkAndReset();
    
    print('⚠️ Firestore Error [$operation]: $error');
    
    if (_errorCount > errorAlertThreshold) {
      _sendAlert('High error rate detected: $_errorCount errors in last hour');
    }
  }
  
  /// Check if we need to reset counters (every hour)
  void _checkAndReset() {
    if (DateTime.now().difference(_lastReset) > Duration(hours: 1)) {
      print('📊 Firestore Stats (last hour): Writes: $_writeCount, Reads: $_readCount, Errors: $_errorCount');
      _writeCount = 0;
      _readCount = 0;
      _errorCount = 0;
      _lastReset = DateTime.now();
    }
  }
  
  /// Send alert (currently just prints, can be extended to send notifications)
  void _sendAlert(String message) {
    print('🚨 ALERT: $message');
    // TODO: Send to Firebase Cloud Messaging or email
    // TODO: Log to Firebase Analytics
  }
  
  /// Get current stats
  Map<String, int> getStats() {
    return {
      'writes': _writeCount,
      'reads': _readCount,
      'errors': _errorCount,
      'minutesSinceReset': DateTime.now().difference(_lastReset).inMinutes,
    };
  }
  
  /// Reset all counters (for testing)
  void reset() {
    _writeCount = 0;
    _readCount = 0;
    _errorCount = 0;
    _lastReset = DateTime.now();
  }
}

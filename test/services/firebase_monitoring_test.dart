import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/services/firebase_monitoring.dart';

void main() {
  group('FirebaseMonitoring Tests', () {
    late FirebaseMonitoring monitoring;

    setUp(() {
      monitoring = FirebaseMonitoring();
      monitoring.reset(); // Reset before each test
    });

    test('Should track write operations', () {
      monitoring.recordWrite('test_collection');
      monitoring.recordWrite('test_collection');
      monitoring.recordWrite('test_collection');

      final stats = monitoring.getStats();
      expect(stats['writes'], 3);
    });

    test('Should track read operations', () {
      monitoring.recordRead('test_collection');
      monitoring.recordRead('test_collection');

      final stats = monitoring.getStats();
      expect(stats['reads'], 2);
    });

    test('Should track errors', () {
      monitoring.recordError('testOperation', 'Test error 1');
      monitoring.recordError('testOperation', 'Test error 2');

      final stats = monitoring.getStats();
      expect(stats['errors'], 2);
    });

    test('Should track all operations together', () {
      monitoring.recordWrite('collection1');
      monitoring.recordWrite('collection2');
      monitoring.recordRead('collection1');
      monitoring.recordRead('collection2');
      monitoring.recordRead('collection3');
      monitoring.recordError('op1', 'error');

      final stats = monitoring.getStats();
      expect(stats['writes'], 2);
      expect(stats['reads'], 3);
      expect(stats['errors'], 1);
    });
  });
}

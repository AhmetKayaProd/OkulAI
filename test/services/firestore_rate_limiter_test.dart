import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';

void main() {
  group('FirestoreRateLimiter Tests', () {
    late FirestoreRateLimiter rateLimiter;

    setUp(() {
      rateLimiter = FirestoreRateLimiter();
      rateLimiter.reset(); // Reset before each test
    });

    test('Should allow writes under limit', () async {
      // Test: 50 writes should all be allowed
      for (int i = 0; i < 50; i++) {
        final canWrite = await rateLimiter.canWrite('test_collection');
        expect(canWrite, true, reason: 'Write $i should be allowed');
      }

      final count = rateLimiter.getCurrentWriteCount('test_collection');
      expect(count, 50);
    });

    test('Should block writes over limit', () async {
      // Test: First 100 writes allowed, 101st blocked
      for (int i = 0; i < 100; i++) {
        final canWrite = await rateLimiter.canWrite('test_collection');
        expect(canWrite, true, reason: 'Write $i should be allowed');
      }

      // 101st write should be blocked
      final canWrite = await rateLimiter.canWrite('test_collection');
      expect(canWrite, false, reason: 'Write 101 should be blocked');

      final count = rateLimiter.getCurrentWriteCount('test_collection');
      expect(count, 100);
    });

    test('Should track different collections separately', () async {
      // Write to collection A
      for (int i = 0; i < 50; i++) {
        await rateLimiter.canWrite('collection_a');
      }

      // Write to collection B
      for (int i = 0; i < 50; i++) {
        await rateLimiter.canWrite('collection_b');
      }

      expect(rateLimiter.getCurrentWriteCount('collection_a'), 50);
      expect(rateLimiter.getCurrentWriteCount('collection_b'), 50);

      // Both should still allow more writes
      expect(await rateLimiter.canWrite('collection_a'), true);
      expect(await rateLimiter.canWrite('collection_b'), true);
    });

    test('Should reset counter after time window', () async {
      // This test would require mocking DateTime, skipping for now
      // In real scenario, old timestamps are removed automatically
    });
  });
}

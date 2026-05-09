import 'package:flutter_test/flutter_test.dart';
import 'package:interceptify/interceptify.dart';

void main() {
  // Note: Interceptify uses kDebugMode internally.
  // Full integration tests require a running Flutter app + DevTools.
  // The tests below verify the public API surface compiles and
  // behaves correctly in terms of state management.

  tearDown(() {
    // Reset singleton state between tests
    if (Interceptify.isInitialized) {
      Interceptify.dispose();
    }
  });

  group('Interceptify initialization', () {
    test('isInitialized returns false before initialize()', () {
      expect(Interceptify.isInitialized, isFalse);
    });

    test('isInitialized returns true after initialize() in debug mode', () {
      // initialize() is a no-op in release mode, so this test only
      // asserts in environments where kDebugMode is true.
      Interceptify.initialize();
      // In test environment kDebugMode == true, so it should be initialized.
      expect(Interceptify.isInitialized, isTrue);
    });

    test('calling initialize() twice does not throw', () {
      expect(() {
        Interceptify.initialize();
        Interceptify.initialize(); // second call is a no-op
      }, returnsNormally);
    });
  });

  group('Interceptify dispose', () {
    test('dispose() resets isInitialized to false', () {
      Interceptify.initialize();
      expect(Interceptify.isInitialized, isTrue);

      Interceptify.dispose();
      expect(Interceptify.isInitialized, isFalse);
    });
  });

  group('Interceptify pending requests', () {
    test('getPendingRequestCount() returns 0 on startup', () {
      Interceptify.initialize();
      expect(Interceptify.getPendingRequestCount(), 0);
    });
  });

  group('Interceptify rules', () {
    test('getRules() returns empty list initially', () {
      Interceptify.initialize();
      expect(Interceptify.getRules(), isEmpty);
    });

    test('clearRules() does not throw when list is already empty', () {
      Interceptify.initialize();
      expect(() => Interceptify.clearRules(), returnsNormally);
    });
  });

  group('Interceptify HTTP client', () {
    test('httpClient() returns a non-null client after initialization', () {
      Interceptify.initialize();
      final client = Interceptify.httpClient();
      expect(client, isNotNull);
      client.close();
    });
  });
}

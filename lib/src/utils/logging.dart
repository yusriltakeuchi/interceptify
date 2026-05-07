import 'dart:developer' as developer;

/// Simple logging utility for debugging the interceptify interceptor
class InterceptifyLogger {
  InterceptifyLogger._();

  /// Enable or disable logging
  static bool _debugMode = true;

  /// Set debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// Log an informational message
  static void info(String message) {
    if (_debugMode) {
      developer.Timeline.instantSync(
        '[Interceptify] $message',
        arguments: {'level': 'info'},
      );
      print('[Interceptify] INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (_debugMode) {
      developer.Timeline.instantSync(
        '[Interceptify] $message',
        arguments: {'level': 'warning'},
      );
      print('[Interceptify] WARNING: $message');
    }
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_debugMode) {
      developer.Timeline.instantSync(
        '[Interceptify] $message',
        arguments: {'level': 'error'},
      );
      print('[Interceptify] ERROR: $message');
      if (error != null) {
        print('[Interceptify] Exception: $error');
      }
      if (stackTrace != null) {
        print('[Interceptify] Stack trace: $stackTrace');
      }
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (_debugMode) {
      print('[Interceptify] DEBUG: $message');
    }
  }
}

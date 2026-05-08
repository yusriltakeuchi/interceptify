import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

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
      debugPrint('[Interceptify] INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (_debugMode) {
      developer.Timeline.instantSync(
        '[Interceptify] $message',
        arguments: {'level': 'warning'},
      );
      debugPrint('[Interceptify] WARNING: $message');
    }
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_debugMode) {
      developer.Timeline.instantSync(
        '[Interceptify] $message',
        arguments: {'level': 'error'},
      );
      debugPrint('[Interceptify] ERROR: $message');
      if (error != null) {
        debugPrint('[Interceptify] Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('[Interceptify] Stack trace: $stackTrace');
      }
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (_debugMode) {
      debugPrint('[Interceptify] DEBUG: $message');
    }
  }
}

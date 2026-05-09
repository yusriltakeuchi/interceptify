import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'src/bridge/devtools_bridge.dart';
import 'src/interceptor/interceptify_dio_interceptor.dart';
import 'src/interceptor/interceptify_http_client.dart';
import 'src/interceptor/interceptify_graphql_link.dart';
import 'src/manager/pending_request_manager.dart';
import 'src/rules/intercept_rule.dart';
import 'src/rules/rule_manager.dart';
import 'src/utils/logging.dart';

// Re-export for convenience
export 'src/interceptor/interceptify_http_client.dart';
export 'src/interceptor/interceptify_graphql_link.dart';

/// Main API for Interceptify network interceptor
///
/// Usage:
/// ```dart
/// void main() {
///   Interceptify.initialize();
///
///   final dio = Dio();
///   dio.interceptors.add(Interceptify.dioInterceptor);
///
///   runApp(MyApp());
/// }
/// ```
class Interceptify {
  Interceptify._();

  static InterceptifyDioInterceptor? _dioInterceptor;
  static PendingRequestManager? _pendingRequestManager;
  static RuleManager? _ruleManager;
  static DevtoolsBridge? _devtoolsBridge;
  static bool _initialized = false;

  /// Initialize Interceptify
  /// Must be called once before using the interceptor
  /// Only initializes in debug mode
  static void initialize({bool debugLogging = true}) {
    if (_initialized) {
      InterceptifyLogger.warning('Interceptify already initialized');
      return;
    }

    // Only initialize in debug mode
    if (!kDebugMode) {
      InterceptifyLogger.info('Interceptify disabled in release mode');
      return;
    }

    InterceptifyLogger.setDebugMode(debugLogging);
    InterceptifyLogger.info('Initializing Interceptify');

    // Create singleton instances
    _pendingRequestManager = PendingRequestManager();
    _ruleManager = RuleManager();
    _devtoolsBridge = DevtoolsBridge(
      pendingRequestManager: _pendingRequestManager!,
      ruleManager: _ruleManager!,
    );
    _dioInterceptor = InterceptifyDioInterceptor(
      pendingRequestManager: _pendingRequestManager!,
      ruleManager: _ruleManager!,
      devtoolsBridge: _devtoolsBridge!,
    );

    // Initialize DevTools bridge (registers VM extensions)
    _devtoolsBridge!.initialize();

    _initialized = true;
    InterceptifyLogger.info('Interceptify initialized successfully');
  }

  /// Register a Dio instance to support "Retry" from DevTools.
  /// If you want to use the Retry feature, call this for each Dio instance.
  static void registerDioInstance(Dio dio) {
    _devtoolsBridge?.registerDioInstance(dio);
  }

  /// Get the Dio interceptor instance
  /// Must call initialize() first
  static InterceptifyDioInterceptor get dioInterceptor {
    if (_dioInterceptor == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return _dioInterceptor!;
  }

  /// Create an HTTP client that captures all requests/responses to DevTools.
  ///
  /// Wraps the given [inner] client (defaults to a plain `http.Client()`).
  /// Use it exactly like a regular `http.Client`:
  ///
  /// ```dart
  /// final client = Interceptify.httpClient();
  /// final response = await client.get(Uri.parse('https://api.example.com'));
  /// ```
  static InterceptifyHttpClient httpClient({http.Client? inner}) {
    if (_devtoolsBridge == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return InterceptifyHttpClient(
      inner: inner ?? http.Client(),
      devtoolsBridge: _devtoolsBridge!,
    );
  }

  /// Create a GraphQL Link that captures all operations to DevTools.
  ///
  /// Pass it as the first Link in your graphql_flutter chain:
  /// ```dart
  /// final link = Interceptify.graphqlLink(
  ///   next: HttpLink('https://api.example.com/graphql'),
  ///   endpoint: 'https://api.example.com/graphql',
  /// );
  /// ```
  static InterceptifyGraphQLLink graphqlLink({
    required dynamic next,
    String endpoint = 'GraphQL',
  }) {
    if (_devtoolsBridge == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return InterceptifyGraphQLLink(
      next: next,
      bridge: _devtoolsBridge!,
      endpoint: endpoint,
    );
  }

  /// Get the pending request manager
  static PendingRequestManager get pendingRequestManager {
    if (_pendingRequestManager == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return _pendingRequestManager!;
  }

  /// Get the rule manager
  static RuleManager get ruleManager {
    if (_ruleManager == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return _ruleManager!;
  }

  /// Get the DevTools bridge
  static DevtoolsBridge get devtoolsBridge {
    if (_devtoolsBridge == null) {
      throw StateError(
        'Interceptify not initialized. Call Interceptify.initialize() first.',
      );
    }
    return _devtoolsBridge!;
  }

  /// Check if Interceptify is initialized
  static bool get isInitialized => _initialized;

  /// Add an interception rule
  static void addRule(InterceptRule rule) {
    ruleManager.addRule(rule);
    InterceptifyLogger.info(
      'Rule added: ${rule.condition.name} - ${rule.value}',
    );
  }

  /// Remove a rule by ID
  static bool removeRule(String ruleId) {
    final success = ruleManager.removeRule(ruleId);
    if (success) {
      InterceptifyLogger.info('Rule removed: $ruleId');
    }
    return success;
  }

  /// Clear all rules
  static void clearRules() {
    ruleManager.clearRules();
    InterceptifyLogger.info('All rules cleared');
  }

  /// Get all rules
  static List<InterceptRule> getRules() => ruleManager.rules;

  /// Get number of active rules
  static int getRuleCount() => ruleManager.ruleCount;

  /// Pause all requests (disable rules)
  static void disableInterception() {
    ruleManager.disableAllRules();
    InterceptifyLogger.info('Interception disabled');
  }

  /// Resume request interception
  static void enableInterception() {
    ruleManager.enableAllRules();
    InterceptifyLogger.info('Interception enabled');
  }

  /// Get number of pending requests
  static int getPendingRequestCount() => pendingRequestManager.pendingCount;

  /// Clean up all resources
  static void dispose() {
    pendingRequestManager.clearAll();
    clearRules();
    _dioInterceptor = null;
    _pendingRequestManager = null;
    _ruleManager = null;
    _devtoolsBridge = null;
    _initialized = false;
    InterceptifyLogger.info('Interceptify disposed');
  }
}

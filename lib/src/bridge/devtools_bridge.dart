import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import '../manager/pending_request_manager.dart';
import '../models/intercepted_request.dart';
import '../rules/rule_manager.dart';
import '../utils/constants.dart';
import '../utils/logging.dart';
import '../rules/intercept_rule.dart';

/// Bridge between the Dio interceptor and Flutter DevTools via VM Service extensions
class DevtoolsBridge {
  static DevtoolsBridge? _instance;
  final PendingRequestManager _pendingRequestManager;
  final RuleManager _ruleManager;
  final Set<Dio> _dioInstances = {};

  DevtoolsBridge._internal(
    this._pendingRequestManager,
    this._ruleManager,
  );

  /// Get or create singleton instance
  factory DevtoolsBridge({
    required PendingRequestManager pendingRequestManager,
    required RuleManager ruleManager,
  }) {
    _instance ??= DevtoolsBridge._internal(
      pendingRequestManager,
      ruleManager,
    );
    return _instance!;
  }

  /// Initialize the VM Service extensions
  void initialize() {
    InterceptifyLogger.info('Initializing DevTools bridge');

    _registerGetPendingRequests();
    _registerContinueRequest();
    _registerCancelRequest();
    _registerAddRule();
    _registerRemoveRule();
    _registerClearRules();
    _registerToggleInterception();
    _registerGetInterceptionStatus();
    _registerTogglePauseAll();
    _registerTogglePauseAllResponses();
    _registerContinueResponse();
    _registerRetryRequest();

    InterceptifyLogger.info('Registered VM service extensions:');
    InterceptifyLogger.info('- ext.interceptify.getPendingRequests');
    InterceptifyLogger.info('- ext.interceptify.continueRequest');
    InterceptifyLogger.info('- ext.interceptify.cancelRequest');
    InterceptifyLogger.info('- ext.interceptify.addRule');
    InterceptifyLogger.info('- ext.interceptify.removeRule');
    InterceptifyLogger.info('- ext.interceptify.clearRules');
    InterceptifyLogger.info('- ext.interceptify.toggleInterception');
    InterceptifyLogger.info('- ext.interceptify.getInterceptionStatus');
    InterceptifyLogger.info('- ext.interceptify.togglePauseAll');
    InterceptifyLogger.info('- ext.interceptify.togglePauseAllResponses');
    InterceptifyLogger.info('- ext.interceptify.continueResponse');
    InterceptifyLogger.info('- ext.interceptify.retryRequest');

    InterceptifyLogger.info('DevTools bridge initialized');
  }

  /// Register a Dio instance for retries
  void registerDioInstance(Dio dio) {
    _dioInstances.add(dio);
  }

  /// Get registered Dio instances
  Set<Dio> get dioInstances => _dioInstances;

  /// Register the getPendingRequests extension
  void _registerGetPendingRequests() {
    developer.registerExtension(
      InterceptifyConstants.getPendingRequestsExtension,
      (String method, Map<String, String> params) async {
        try {
          final pending = _pendingRequestManager.getPendingRequests();
          final data = pending.map((r) => r.toJson()).toList();
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'result': data,
              'success': true,
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in getPendingRequests', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the continueRequest extension
  void _registerContinueRequest() {
    developer.registerExtension(
      InterceptifyConstants.continueRequestExtension,
      (String method, Map<String, String> params) async {
        try {
          final requestId = params['requestId'];
          if (requestId == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'requestId parameter required',
                'success': false,
              }),
            );
          }

          // Parse modifications if provided
          Map<String, dynamic>? modifications;
          if (params.containsKey('modifications')) {
            try {
              modifications =
                  jsonDecode(params['modifications']!) as Map<String, dynamic>;
            } catch (e) {
              InterceptifyLogger.warning('Failed to parse modifications: $e');
            }
          }

          final success =
              _pendingRequestManager.continueRequest(requestId, modifications);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': success,
              'message': success
                  ? 'Request continued'
                  : 'Request not found or already continued',
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in continueRequest', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the cancelRequest extension
  void _registerCancelRequest() {
    developer.registerExtension(
      InterceptifyConstants.cancelRequestExtension,
      (String method, Map<String, String> params) async {
        try {
          final requestId = params['requestId'];
          if (requestId == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'requestId parameter required',
                'success': false,
              }),
            );
          }

          final success = _pendingRequestManager.cancelRequest(requestId);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': success,
              'message': success
                  ? 'Request canceled'
                  : 'Request not found or already continued',
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in cancelRequest', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the addRule extension
  void _registerAddRule() {
    developer.registerExtension(
      InterceptifyConstants.addRuleExtension,
      (String method, Map<String, String> params) async {
        try {
          final ruleJson = params['rule'];
          if (ruleJson == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'rule parameter required',
                'success': false,
              }),
            );
          }

          final rule =
              _parseRule(jsonDecode(ruleJson) as Map<String, dynamic>);
          _ruleManager.addRule(rule);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'rule': rule.toJson(),
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in addRule', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the removeRule extension
  void _registerRemoveRule() {
    developer.registerExtension(
      InterceptifyConstants.removeRuleExtension,
      (String method, Map<String, String> params) async {
        try {
          final ruleId = params['ruleId'];
          if (ruleId == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'ruleId parameter required',
                'success': false,
              }),
            );
          }

          final success = _ruleManager.removeRule(ruleId);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': success,
              'message': success ? 'Rule removed' : 'Rule not found',
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in removeRule', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the clearRules extension
  void _registerClearRules() {
    developer.registerExtension(
      InterceptifyConstants.clearRulesExtension,
      (String method, Map<String, String> params) async {
        try {
          _ruleManager.clearRules();

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'message': 'All rules cleared',
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in clearRules', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Post a request event to DevTools
  void postRequestEvent(InterceptedRequest request) {
    if (!developer.extensionStreamHasListener) {
      return; // No DevTools listening, skip to avoid overhead
    }

    try {
      developer.postEvent(
        InterceptifyConstants.requestEventKind,
        {
          'request': request.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      InterceptifyLogger.warning('Failed to post request event: $e');
    }
  }

  /// Post a response event to DevTools
  void postResponseEvent(
    String requestId,
    int? statusCode,
    dynamic body,
    Map<String, dynamic>? headers,
    Duration duration,
  ) {
    if (!developer.extensionStreamHasListener) {
      return; // No DevTools listening, skip to avoid overhead
    }

    try {
      developer.postEvent(
        InterceptifyConstants.responseEventKind,
        {
          'requestId': requestId,
          'statusCode': statusCode,
          'body': _serializeBody(body),
          'headers': headers,
          'duration': duration.inMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      InterceptifyLogger.warning('Failed to post response event: $e');
    }
  }

  /// Post an error event to DevTools
  void postErrorEvent(String requestId, String errorMessage, String? errorType) {
    if (!developer.extensionStreamHasListener) {
      return; // No DevTools listening, skip to avoid overhead
    }

    try {
      developer.postEvent(
        InterceptifyConstants.errorEventKind,
        {
          'requestId': requestId,
          'errorMessage': errorMessage,
          'errorType': errorType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      InterceptifyLogger.warning('Failed to post error event: $e');
    }
  }

  /// Helper to parse a rule from JSON
  InterceptRule _parseRule(Map<String, dynamic> json) {
    return InterceptRule.fromJson(json);
  }

  /// Helper method to serialize complex body types
  static dynamic _serializeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is num) return body;
    if (body is bool) return body;
    if (body is Map) return body;
    if (body is List) return body;
    // For other types, convert to string representation
    return body.toString();
  }

  /// Register the toggleInterception extension
  void _registerToggleInterception() {
    developer.registerExtension(
      InterceptifyConstants.toggleInterceptionExtension,
      (String method, Map<String, String> params) async {
        try {
          final enabled = params['enabled'] == 'true';
          _ruleManager.setEnabled(enabled);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'enabled': enabled,
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in toggleInterception', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the getInterceptionStatus extension
  void _registerGetInterceptionStatus() {
    developer.registerExtension(
      InterceptifyConstants.getInterceptionStatusExtension,
      (String method, Map<String, String> params) async {
        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            'enabled': _ruleManager.enabled,
            'success': true,
          }),
        );
      },
    );
  }

  /// Register the togglePauseAll extension
  void _registerTogglePauseAll() {
    developer.registerExtension(
      InterceptifyConstants.togglePauseAllExtension,
      (String method, Map<String, String> params) async {
        try {
          final pause = params['pause'] == 'true';
          _ruleManager.setPauseAllRequests(pause);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'pause': pause,
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in togglePauseAll', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the retryRequest extension
  void _registerRetryRequest() {
    developer.registerExtension(
      'ext.interceptify.retryRequest',
      (String method, Map<String, String> params) async {
        try {
          final requestJson = params['request'];
          if (requestJson == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'request parameter required',
                'success': false,
              }),
            );
          }

          final data = jsonDecode(requestJson) as Map<String, dynamic>;
          final retryMethod = data['method'] as String? ?? 'GET';
          final retryUrl = data['url'] as String;
          final retryHeaders = data['headers'] as Map<String, dynamic>?;
          final retryQueryParams =
              data['queryParameters'] as Map<String, dynamic>?;
          final retryBody = data['body'];

          // Get registered Dio instances
          if (_dioInstances.isEmpty) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error':
                    'No Dio instances registered for retry. Call Interceptify.registerDioInstance(dio) in your app.',
                'success': false,
              }),
            );
          }

          // Use the first registered Dio instance
          final dio = _dioInstances.first;

          // Trigger the request in the background
          // ignore: unawaited_futures
          dio.request(
            retryUrl,
            data: retryBody,
            queryParameters: retryQueryParams,
            options: Options(
              method: retryMethod,
              headers: retryHeaders,
            ),
          );

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'message': 'Retry triggered',
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in retryRequest', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the continueResponse extension
  void _registerContinueResponse() {
    developer.registerExtension(
      'ext.interceptify.continueResponse',
      (String method, Map<String, String> params) async {
        try {
          final requestId = params['requestId'];
          if (requestId == null) {
            return developer.ServiceExtensionResponse.result(
              jsonEncode({
                'error': 'requestId parameter required',
                'success': false,
              }),
            );
          }

          Map<String, dynamic>? modifications;
          if (params.containsKey('modifications')) {
            modifications =
                jsonDecode(params['modifications']!) as Map<String, dynamic>;
          }

          final success =
              _pendingRequestManager.continueResponse(requestId, modifications);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': success,
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in continueResponse', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }

  /// Register the togglePauseAllResponses extension
  void _registerTogglePauseAllResponses() {
    developer.registerExtension(
      'ext.interceptify.togglePauseAllResponses',
      (String method, Map<String, String> params) async {
        try {
          final pause = params['pause'] == 'true';
          _ruleManager.setPauseAllResponses(pause);

          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'success': true,
              'pause': pause,
            }),
          );
        } catch (e) {
          InterceptifyLogger.error('Error in togglePauseAllResponses', e);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'error': e.toString(),
              'success': false,
            }),
          );
        }
      },
    );
  }
}

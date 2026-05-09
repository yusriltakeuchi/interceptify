import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../bridge/devtools_bridge.dart';
import '../manager/pending_request_manager.dart';
import '../models/intercepted_request.dart';
import '../rules/rule_manager.dart';
import '../utils/logging.dart';
import 'request_modifier.dart';

/// Dio interceptor for capturing and intercepting network requests
/// This interceptor integrates with Flutter DevTools via VM Service extensions
class InterceptifyDioInterceptor extends QueuedInterceptor {
  final PendingRequestManager _pendingRequestManager;
  final RuleManager _ruleManager;
  final DevtoolsBridge _devtoolsBridge;

  InterceptifyDioInterceptor({
    required PendingRequestManager pendingRequestManager,
    required RuleManager ruleManager,
    required DevtoolsBridge devtoolsBridge,
  }) : _pendingRequestManager = pendingRequestManager,
       _ruleManager = ruleManager,
       _devtoolsBridge = devtoolsBridge;

  /// Called when a request is about to be sent
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only intercept in debug mode
    if (!kDebugMode) {
      return handler.next(options);
    }

    try {
      // Generate unique ID for this request
      const uuid = Uuid();
      final requestId = uuid.v4();

      // Record start time for duration calculation
      options.extra['interceptify_start_time'] = DateTime.now();
      options.extra['interceptify_request_id'] = requestId;

      // Capture request details
      final headers = Map<String, dynamic>.from(options.headers);

      // Add common headers if not present (helps with visibility in DevTools)
      if (options.contentType != null && !headers.containsKey('content-type')) {
        headers['content-type'] = options.contentType;
      }
      if (options.responseType.toString().isNotEmpty &&
          !headers.containsKey('accept')) {
        headers['accept'] = options.responseType.toString();
      }

      // Check if this request should be paused
      final shouldPause = _ruleManager.shouldPause(options);

      final interceptedRequest = InterceptedRequest(
        id: requestId,
        method: options.method,
        url: options.uri.toString(),
        headers: headers,
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        body: options.data,
        timestamp: DateTime.now(),
        paused: shouldPause,
        clientType: 'dio',
      );

      // Post request event to DevTools
      _devtoolsBridge.postRequestEvent(interceptedRequest);

      // If should be paused, wait for continuation
      if (shouldPause) {
        InterceptifyLogger.info(
          'Request matched pause rule: ${options.method} ${options.uri}',
        );

        // Mark as paused and wait for continuation
        try {
          final modifications = await _pendingRequestManager.pauseRequest(
            interceptedRequest,
            timeout: Duration(seconds: _ruleManager.timeoutSeconds),
          );

          // Apply modifications if provided
          if (modifications != null) {
            RequestModifier.applyAllModifications(options, modifications);
            InterceptifyLogger.info('Applied modifications to request');

            // Post UPDATED request event to DevTools so UI reflects changes
            final updatedRequest = interceptedRequest.copyWith(
              method: options.method,
              url: options.uri.toString(),
              headers: Map<String, dynamic>.from(options.headers),
              queryParameters: Map<String, dynamic>.from(
                options.queryParameters,
              ),
              body: options.data,
              paused: false, // Mark as no longer paused
            );
            _devtoolsBridge.postRequestEvent(updatedRequest);
          } else {
            // Even if no modifications, mark as no longer paused in DevTools
            _devtoolsBridge.postRequestEvent(
              interceptedRequest.copyWith(paused: false),
            );
          }
        } catch (e) {
          InterceptifyLogger.error('Error while request was paused', e);
          // If error occurred (e.g., cancellation), propagate it
          return handler.reject(
            DioException(
              requestOptions: options,
              error: e,
              type: DioExceptionType.unknown,
              message: 'Request was canceled',
            ),
          );
        }
      }

      return handler.next(options);
    } catch (e) {
      InterceptifyLogger.error('Error in onRequest', e);
      return handler.next(options);
    }
  }

  /// Called when a response is received
  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    // Only intercept in debug mode
    if (!kDebugMode) {
      return handler.next(response);
    }

    try {
      final requestId =
          response.requestOptions.extra['interceptify_request_id'] as String?;
      final startTime =
          response.requestOptions.extra['interceptify_start_time'] as DateTime?;

      if (requestId != null && startTime != null) {
        final duration = DateTime.now().difference(startTime);

        // Post response event to DevTools
        _devtoolsBridge.postResponseEvent(
          requestId,
          response.statusCode,
          response.data,
          response.headers.map.map(
            (key, value) =>
                MapEntry(key, value.isNotEmpty ? value.first : null),
          ),
          duration,
        );

        InterceptifyLogger.info(
          'Response received: $requestId (${response.statusCode}) - ${duration.inMilliseconds}ms',
        );

        // Check if we should pause on response
        if (_ruleManager.enabled && _ruleManager.pauseAllResponses) {
          InterceptifyLogger.info(
            'Response matched pause rule for request: $requestId',
          );

          try {
            // Post updated request event to show it's now paused on response
            _devtoolsBridge.postRequestEvent(
              InterceptedRequest(
                id: requestId,
                method: response.requestOptions.method,
                url: response.requestOptions.uri.toString(),
                headers: Map<String, dynamic>.from(
                  response.requestOptions.headers,
                ),
                queryParameters: Map<String, dynamic>.from(
                  response.requestOptions.queryParameters,
                ),
                body: response.requestOptions.data,
                timestamp: startTime,
                paused: true,
              ),
            );

            // Post initial response data to DevTools so user can edit it
            _devtoolsBridge.postResponseEvent(
              requestId,
              response.statusCode,
              response.data,
              response.headers.map.map(
                (key, value) =>
                    MapEntry(key, value.isNotEmpty ? value.first : null),
              ),
              DateTime.now().difference(startTime),
            );

            final modifications = await _pendingRequestManager.pauseResponse(
              requestId,
              response.data,
              response.headers.map.map(
                (key, value) =>
                    MapEntry(key, value.isNotEmpty ? value.first : null),
              ),
              response.statusCode ?? 200,
              timeout: Duration(seconds: _ruleManager.timeoutSeconds),
            );

            // Apply response modifications if provided
            if (modifications != null) {
              if (modifications.containsKey('statusCode')) {
                response.statusCode = modifications['statusCode'] as int?;
              }
              if (modifications.containsKey('body')) {
                response.data = modifications['body'];
              }
              InterceptifyLogger.info(
                'Applied modifications to response: $requestId',
              );
            }

            // Post UPDATED response event to DevTools
            final duration = DateTime.now().difference(startTime);
            _devtoolsBridge.postResponseEvent(
              requestId,
              response.statusCode,
              response.data,
              response.headers.map.map(
                (key, value) =>
                    MapEntry(key, value.isNotEmpty ? value.first : null),
              ),
              duration,
            );

            // Also update request status to unpaused while preserving existing data
            _devtoolsBridge.postRequestEvent(
              InterceptedRequest(
                id: requestId,
                method: response.requestOptions.method,
                url: response.requestOptions.uri.toString(),
                headers: Map<String, dynamic>.from(
                  response.requestOptions.headers,
                ),
                queryParameters: Map<String, dynamic>.from(
                  response.requestOptions.queryParameters,
                ),
                body: response.requestOptions.data,
                timestamp: startTime,
                paused: false,
              ),
            );
          } catch (e) {
            InterceptifyLogger.error('Error while response was paused', e);
          }
        }
      }
    } catch (e) {
      InterceptifyLogger.error('Error in onResponse', e);
    }

    return handler.next(response);
  }

  /// Called when an error occurs
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept in debug mode
    if (!kDebugMode) {
      return handler.next(err);
    }

    try {
      final requestId =
          err.requestOptions.extra['interceptify_request_id'] as String?;

      if (requestId != null) {
        // Post error event to DevTools
        _devtoolsBridge.postErrorEvent(
          requestId,
          err.message ?? 'Unknown error',
          err.type.name,
        );

        InterceptifyLogger.error(
          'Request error: $requestId - ${err.type.name} - ${err.message}',
        );
      }
    } catch (e) {
      InterceptifyLogger.error('Error in onError', e);
    }

    return handler.next(err);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../bridge/devtools_bridge.dart';
import '../manager/pending_request_manager.dart';
import '../models/intercepted_request.dart';
import '../rules/rule_manager.dart';
import '../utils/logging.dart';

/// HTTP client interceptor for capturing, pausing, and inspecting network
/// requests made via the `package:http` library.
///
/// Usage:
/// ```dart
/// // In main():
/// Interceptify.initialize();
///
/// // Replace http.Client() with InterceptifyHttpClient:
/// final client = Interceptify.httpClient();
///
/// // Use exactly like a normal http.Client:
/// final response = await client.get(Uri.parse('https://api.example.com/users'));
/// ```
class InterceptifyHttpClient extends http.BaseClient {
  final http.Client _inner;
  final DevtoolsBridge _devtoolsBridge;
  final PendingRequestManager _pendingRequestManager;
  final RuleManager _ruleManager;

  InterceptifyHttpClient({
    required http.Client inner,
    required DevtoolsBridge devtoolsBridge,
    required PendingRequestManager pendingRequestManager,
    required RuleManager ruleManager,
  }) : _inner = inner,
       _devtoolsBridge = devtoolsBridge,
       _pendingRequestManager = pendingRequestManager,
       _ruleManager = ruleManager;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only intercept in debug mode
    if (!kDebugMode) {
      return _inner.send(request);
    }

    const uuid = Uuid();
    final requestId = uuid.v4();
    final startTime = DateTime.now();

    // --- Capture request body ---
    dynamic requestBody;
    if (request is http.Request) {
      try {
        final bodyStr = request.body;
        if (bodyStr.isNotEmpty) {
          // Try to parse as JSON so DevTools shows interactive tree
          final trimmed = bodyStr.trimLeft();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            try {
              requestBody = jsonDecode(bodyStr);
            } catch (_) {
              requestBody = bodyStr;
            }
          } else {
            requestBody = bodyStr;
          }
        }
      } catch (_) {}
    }

    // --- Check pause rules ---
    final shouldPauseRequest = _ruleManager.enabled &&
        (_ruleManager.pauseAllRequests ||
            _ruleManager.shouldPauseHttpRequest(
              request.method,
              request.url.toString(),
            ));

    final interceptedRequest = InterceptedRequest(
      id: requestId,
      method: request.method,
      url: request.url.toString(),
      headers: Map<String, dynamic>.from(request.headers),
      queryParameters: _parseQueryParams(request.url),
      body: requestBody,
      timestamp: startTime,
      clientType: 'http',
      paused: shouldPauseRequest,
    );

    _devtoolsBridge.postRequestEvent(interceptedRequest);
    InterceptifyLogger.info(
      'HTTP request: ${request.method} ${request.url} [$requestId]',
    );

    var currentRequest = interceptedRequest;

    // --- Pause on request if needed ---
    // Capture the (possibly modified) request to send after unpausing.
    http.BaseRequest effectiveRequest = request;

    if (shouldPauseRequest) {
      InterceptifyLogger.info('HTTP request paused: $requestId');
      try {
        final modifications = await _pendingRequestManager.pauseRequest(
          currentRequest,
          timeout: Duration(seconds: _ruleManager.timeoutSeconds),
        );

        // Apply modifications from DevTools if provided
        if (modifications != null && request is http.Request) {
          effectiveRequest = _applyModifications(request, modifications);

          // Re-post the updated request to DevTools so the UI reflects changes
          if (effectiveRequest is http.Request) {
            final modReq = effectiveRequest as http.Request;
            dynamic modBody = modReq.body;
            try {
              final trimmed = modReq.body.trimLeft();
              if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
                modBody = jsonDecode(modReq.body);
              }
            } catch (_) {}

            currentRequest = currentRequest.copyWith(
              url: modReq.url.toString(),
              method: modReq.method,
              headers: Map<String, dynamic>.from(modReq.headers),
              queryParameters: _parseQueryParams(modReq.url),
              body: modBody,
              paused: false,
            );
            _devtoolsBridge.postRequestEvent(currentRequest);
          }
        } else {
          // No modifications — just mark as unpaused
          currentRequest = currentRequest.copyWith(paused: false);
          _devtoolsBridge.postRequestEvent(currentRequest);
        }
      } catch (e) {
        // Cancelled
        _devtoolsBridge.postErrorEvent(
          requestId,
          'Request cancelled by DevTools',
          'CancelledByUser',
        );
        throw Exception('HTTP request cancelled by DevTools: $e');
      }
    }

    try {
      final streamedResponse = await _inner.send(effectiveRequest);
      final duration = DateTime.now().difference(startTime);

      // Consume the body bytes so we can inspect and replay them
      final responseBytes = await streamedResponse.stream.toBytes();
      dynamic responseBody = _parseResponseBody(responseBytes);

      final responseHeaders = <String, dynamic>{
        for (final e in streamedResponse.headers.entries) e.key: e.value,
      };

      // --- Check pause on response ---
      final shouldPauseResponse = _ruleManager.enabled &&
          _ruleManager.pauseAllResponses;

      if (shouldPauseResponse) {
        // Post response data first so DevTools can display it
        _devtoolsBridge.postResponseEvent(
          requestId,
          streamedResponse.statusCode,
          responseBody,
          responseHeaders,
          duration,
        );

        // Re-post request as paused (for DevTools UI)
        // This MUST use currentRequest to preserve request modifications!
        currentRequest = currentRequest.copyWith(paused: true);
        _devtoolsBridge.postRequestEvent(currentRequest);

        InterceptifyLogger.info('HTTP response paused: $requestId');
        try {
          final modifications = await _pendingRequestManager.pauseResponse(
            requestId,
            responseBody,
            responseHeaders,
            streamedResponse.statusCode,
            timeout: Duration(seconds: _ruleManager.timeoutSeconds),
          );

          if (modifications != null) {
            if (modifications.containsKey('body')) {
              responseBody = modifications['body'];
            }
          }
        } catch (_) {}

        // Mark request as unpaused
        currentRequest = currentRequest.copyWith(paused: false);
        _devtoolsBridge.postRequestEvent(currentRequest);
      }

      _devtoolsBridge.postResponseEvent(
        requestId,
        streamedResponse.statusCode,
        responseBody,
        responseHeaders,
        duration,
      );

      InterceptifyLogger.info(
        'HTTP response: $requestId (${streamedResponse.statusCode}) - ${duration.inMilliseconds}ms',
      );

      // Rebuild the StreamedResponse from the already-consumed bytes
      final bodyToReturn = responseBody is String
          ? responseBody
          : (responseBody != null
              ? jsonEncode(responseBody)
              : '');
      final bodyBytes = utf8.encode(bodyToReturn);

      return http.StreamedResponse(
        http.ByteStream.fromBytes(bodyBytes),
        streamedResponse.statusCode,
        contentLength: bodyBytes.length,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e, st) {
      InterceptifyLogger.error('HTTP error: $requestId', e);
      _devtoolsBridge.postErrorEvent(
        requestId,
        e.toString(),
        e.runtimeType.toString(),
      );
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Parse query parameters from a Uri into a flat string map.
  Map<String, dynamic> _parseQueryParams(Uri uri) {
    return Map<String, dynamic>.from(uri.queryParameters);
  }

  /// Decode response bytes as UTF-8, then attempt JSON parse.
  /// Returns a Map/List if JSON, otherwise a String.
  dynamic _parseResponseBody(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final str = utf8.decode(bytes);
      final trimmed = str.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonDecode(str); // returns Map or List
        } catch (_) {
          return str;
        }
      }
      return str;
    } catch (_) {
      return '(binary data, ${bytes.length} bytes)';
    }
  }

  /// Rebuild an [http.Request] from DevTools modifications.
  /// Applies changes to URL (including query params), method, headers, and body.
  http.Request _applyModifications(
    http.Request original,
    Map<String, dynamic> modifications,
  ) {
    // --- URL resolution ---
    // The user may type a full URL ("https://host/posts/20") or a relative
    // path ("/posts/20"). We resolve relative paths against the original host.
    final rawUrl = modifications['url'] as String?;
    Uri uri;
    if (rawUrl == null || rawUrl.isEmpty) {
      uri = original.url;
    } else {
      final parsed = Uri.tryParse(rawUrl);
      if (parsed == null) {
        uri = original.url;
      } else if (parsed.hasScheme) {
        // Absolute URL — use as-is
        uri = parsed;
      } else {
        // Relative path — resolve against original base
        uri = original.url.resolveUri(parsed);
      }
    }

    // --- Query parameters (merge/override) ---
    final modParams =
        (modifications['queryParameters'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        <String, String>{};

    if (modParams.isNotEmpty) {
      final merged = Map<String, String>.from(uri.queryParameters)
        ..addAll(modParams);
      uri = uri.replace(queryParameters: merged);
    }

    // --- Method ---
    final method =
        (modifications['method'] as String? ?? original.method).toUpperCase();

    final newRequest = http.Request(method, uri);

    // --- Headers ---
    final modHeaders = (modifications['headers'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    newRequest.headers.addAll(
      modHeaders ?? Map<String, String>.from(original.headers),
    );

    // --- Body ---
    final modBody = modifications['body'];
    if (modBody != null) {
      if (modBody is String) {
        newRequest.body = modBody;
      } else if (modBody is Map || modBody is List) {
        newRequest.body = jsonEncode(modBody);
        newRequest.headers['content-type'] = 'application/json; charset=utf-8';
      }
    } else {
      // Preserve original body
      newRequest.bodyBytes = original.bodyBytes;
    }

    InterceptifyLogger.info(
      'Request modified: ${original.method} ${original.url} → $method $uri',
    );
    if (modBody != null) {
      InterceptifyLogger.info('Request body modified: $modBody');
    }

    return newRequest;
  }

  @override
  void close() {
    _inner.close();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../bridge/devtools_bridge.dart';
import '../models/intercepted_request.dart';
import '../utils/logging.dart';

/// HTTP client interceptor for capturing and inspecting network requests
/// made via the `package:http` library.
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

  InterceptifyHttpClient({
    required http.Client inner,
    required DevtoolsBridge devtoolsBridge,
  }) : _inner = inner,
       _devtoolsBridge = devtoolsBridge;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only intercept in debug mode
    if (!kDebugMode) {
      return _inner.send(request);
    }

    const uuid = Uuid();
    final requestId = uuid.v4();
    final startTime = DateTime.now();

    // --- Capture request ---
    String? bodyString;
    Map<String, dynamic>? bodyMap;

    if (request is http.Request) {
      try {
        bodyString = request.body;
      } catch (_) {}
    }

    final interceptedRequest = InterceptedRequest(
      id: requestId,
      method: request.method,
      url: request.url.toString(),
      headers: Map<String, dynamic>.from(request.headers),
      queryParameters: _parseQueryParams(request.url),
      body: bodyMap ?? bodyString,
      timestamp: startTime,
      clientType: 'http',
    );

    _devtoolsBridge.postRequestEvent(interceptedRequest);
    InterceptifyLogger.info(
      'HTTP request: ${request.method} ${request.url}  [$requestId]',
    );

    try {
      final streamedResponse = await _inner.send(request);
      final duration = DateTime.now().difference(startTime);

      // Convert streamed response to get the body
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = _tryDecodeBody(responseBytes);

      final responseHeaders = <String, dynamic>{
        for (final e in streamedResponse.headers.entries) e.key: e.value,
      };

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

      // Return a new StreamedResponse backed by the already-consumed bytes
      return http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        streamedResponse.statusCode,
        contentLength: responseBytes.length,
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

  /// Try to decode bytes as UTF-8 string, then parse as JSON if possible.
  dynamic _tryDecodeBody(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      // ignore: unnecessary_import
      final str = String.fromCharCodes(bytes);
      // Attempt JSON parse
      if (str.trimLeft().startsWith('{') || str.trimLeft().startsWith('[')) {
        // Return as string — DevTools will render it nicely
        return str;
      }
      return str;
    } catch (_) {
      return '(binary data, ${bytes.length} bytes)';
    }
  }

  @override
  void close() {
    _inner.close();
  }
}

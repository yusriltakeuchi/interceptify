import 'dart:async';

import '../models/intercepted_request.dart';
import '../utils/constants.dart';
import '../utils/logging.dart';

/// Manages pending (paused) requests with timeout handling
class PendingRequestManager {
  final Map<String, _PendingRequest> _pendingRequests = {};

  /// Pause a request and wait for continuation
  Future<Map<String, dynamic>?> pauseRequest(
    InterceptedRequest request, {
    Duration? timeout,
  }) {
    final completer = Completer<Map<String, dynamic>?>();
    final effectiveTimeout = timeout ?? InterceptifyConstants.requestTimeout;

    final pendingRequest = _PendingRequest(
      request: request,
      completer: completer,
      startTime: DateTime.now(),
    );

    _pendingRequests[request.id] = pendingRequest;

    InterceptifyLogger.info(
      'Request paused: ${request.method} ${request.url} (ID: ${request.id})',
    );

    // Set up timeout to auto-resume
    final timeoutTimer = Timer(effectiveTimeout, () {
      if (_pendingRequests.containsKey(request.id)) {
        InterceptifyLogger.warning(
          'Request timeout (${effectiveTimeout.inSeconds}s), auto-resuming: ${request.id}',
        );
        _pendingRequests.remove(request.id);
        if (!completer.isCompleted) {
          completer.complete(null); // Resume with no modifications
        }
      }
    });

    pendingRequest.timeoutTimer = timeoutTimer;

    return completer.future;
  }

  /// Continue a paused request with optional modifications
  bool continueRequest(String requestId, Map<String, dynamic>? modifications) {
    final pendingRequest = _pendingRequests.remove(requestId);

    if (pendingRequest == null) {
      InterceptifyLogger.warning(
        'Attempted to continue non-existent request: $requestId',
      );
      return false;
    }

    // Cancel timeout
    pendingRequest.timeoutTimer?.cancel();

    final duration = DateTime.now().difference(pendingRequest.startTime);
    InterceptifyLogger.info(
      'Request continued: $requestId (waited ${duration.inMilliseconds}ms)',
    );

    if (!pendingRequest.completer.isCompleted) {
      pendingRequest.completer.complete(modifications);
    }

    return true;
  }

  /// Cancel a paused request (will throw exception in request)
  bool cancelRequest(String requestId) {
    final pendingRequest = _pendingRequests.remove(requestId);

    if (pendingRequest == null) {
      InterceptifyLogger.warning(
        'Attempted to cancel non-existent request: $requestId',
      );
      return false;
    }

    // Cancel timeout
    pendingRequest.timeoutTimer?.cancel();

    InterceptifyLogger.info('Request canceled: $requestId');

    if (!pendingRequest.completer.isCompleted) {
      pendingRequest.completer.completeError(
        Exception('Request canceled by DevTools'),
      );
    }

    return true;
  }

  /// Get all pending requests
  List<InterceptedRequest> getPendingRequests() {
    return _pendingRequests.values.map((p) => p.request).toList();
  }

  /// Check if a request is pending
  bool isPending(String requestId) {
    return _pendingRequests.containsKey(requestId);
  }

  /// Get number of pending requests
  int get pendingCount => _pendingRequests.length;

  /// Pause a response and wait for continuation
  Future<Map<String, dynamic>?> pauseResponse(
    String requestId,
    dynamic responseData,
    Map<String, dynamic>? responseHeaders,
    int statusCode, {
    Duration? timeout,
  }) {
    final completer = Completer<Map<String, dynamic>?>();
    final effectiveTimeout = timeout ?? InterceptifyConstants.requestTimeout;

    final pendingResponse = _PendingResponse(
      requestId: requestId,
      completer: completer,
      startTime: DateTime.now(),
    );

    _pendingResponses[requestId] = pendingResponse;

    InterceptifyLogger.info('Response paused for request: $requestId');

    // Set up timeout to auto-resume
    final timeoutTimer = Timer(effectiveTimeout, () {
      if (_pendingResponses.containsKey(requestId)) {
        InterceptifyLogger.warning(
          'Response timeout (${effectiveTimeout.inSeconds}s), auto-resuming: $requestId',
        );
        _pendingResponses.remove(requestId);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    });

    pendingResponse.timeoutTimer = timeoutTimer;

    return completer.future;
  }

  /// Continue a paused response
  bool continueResponse(String requestId, Map<String, dynamic>? modifications) {
    final pendingResponse = _pendingResponses.remove(requestId);

    if (pendingResponse == null) return false;

    pendingResponse.timeoutTimer?.cancel();

    if (!pendingResponse.completer.isCompleted) {
      pendingResponse.completer.complete(modifications);
    }

    return true;
  }

  final Map<String, _PendingResponse> _pendingResponses = {};

  /// Clear all pending
  void clearAll() {
    for (final request in _pendingRequests.values) {
      request.timeoutTimer?.cancel();
      if (!request.completer.isCompleted) {
        request.completer.complete(null);
      }
    }
    _pendingRequests.clear();

    for (final response in _pendingResponses.values) {
      response.timeoutTimer?.cancel();
      if (!response.completer.isCompleted) {
        response.completer.complete(null);
      }
    }
    _pendingResponses.clear();
  }
}

class _PendingResponse {
  final String requestId;
  final Completer<Map<String, dynamic>?> completer;
  final DateTime startTime;
  Timer? timeoutTimer;

  _PendingResponse({
    required this.requestId,
    required this.completer,
    required this.startTime,
  });
}

/// Internal class to hold pending request state
class _PendingRequest {
  final InterceptedRequest request;
  final Completer<Map<String, dynamic>?> completer;
  final DateTime startTime;
  Timer? timeoutTimer;

  _PendingRequest({
    required this.request,
    required this.completer,
    required this.startTime,
  });
}

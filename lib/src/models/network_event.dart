import 'intercepted_request.dart';
import 'intercepted_response.dart';

/// Represents a network event (either request or response).
sealed class NetworkEvent {
  final DateTime timestamp;

  NetworkEvent({required this.timestamp});

  Map<String, dynamic> toJson();
}

/// Request event when an HTTP request is intercepted
class RequestEvent extends NetworkEvent {
  final InterceptedRequest request;

  RequestEvent({required this.request, required super.timestamp});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'request',
      'timestamp': timestamp.toIso8601String(),
      'request': request.toJson(),
    };
  }

  factory RequestEvent.fromJson(Map<String, dynamic> json) {
    return RequestEvent(
      request: InterceptedRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Response event when a response is received
class ResponseEvent extends NetworkEvent {
  final InterceptedResponse response;

  ResponseEvent({required this.response, required super.timestamp});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'response',
      'timestamp': timestamp.toIso8601String(),
      'response': response.toJson(),
    };
  }

  factory ResponseEvent.fromJson(Map<String, dynamic> json) {
    return ResponseEvent(
      response: InterceptedResponse.fromJson(
        json['response'] as Map<String, dynamic>,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Error event when a request fails
class ErrorEvent extends NetworkEvent {
  final String requestId;
  final String errorMessage;
  final String? errorType;

  ErrorEvent({
    required this.requestId,
    required this.errorMessage,
    this.errorType,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'error',
      'timestamp': timestamp.toIso8601String(),
      'requestId': requestId,
      'errorMessage': errorMessage,
      'errorType': errorType,
    };
  }

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(
      requestId: json['requestId'] as String,
      errorMessage: json['errorMessage'] as String,
      errorType: json['errorType'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

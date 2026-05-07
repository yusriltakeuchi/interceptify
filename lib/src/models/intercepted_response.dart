import 'package:collection/collection.dart';

/// Represents an HTTP response received after an intercepted request.
class InterceptedResponse {
  final String requestId;
  final int? statusCode;
  final dynamic body;
  final Map<String, dynamic>? headers;
  final Duration duration;
  final DateTime timestamp;

  InterceptedResponse({
    required this.requestId,
    this.statusCode,
    this.body,
    this.headers,
    required this.duration,
    required this.timestamp,
  });

  /// Convert to JSON for serialization to DevTools
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'statusCode': statusCode,
      'body': _serializeBody(body),
      'headers': headers,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON (from DevTools)
  factory InterceptedResponse.fromJson(Map<String, dynamic> json) {
    return InterceptedResponse(
      requestId: json['requestId'] as String,
      statusCode: json['statusCode'] as int?,
      body: json['body'],
      headers: json['headers'] as Map<String, dynamic>?,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with optional field overrides
  InterceptedResponse copyWith({
    String? requestId,
    int? statusCode,
    dynamic body,
    Map<String, dynamic>? headers,
    Duration? duration,
    DateTime? timestamp,
  }) {
    return InterceptedResponse(
      requestId: requestId ?? this.requestId,
      statusCode: statusCode ?? this.statusCode,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'InterceptedResponse(requestId: $requestId, statusCode: $statusCode, duration: ${duration.inMilliseconds}ms)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterceptedResponse &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          statusCode == other.statusCode &&
          body == other.body &&
          const DeepCollectionEquality().equals(headers, other.headers) &&
          duration == other.duration &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      requestId.hashCode ^
      statusCode.hashCode ^
      body.hashCode ^
      headers.hashCode ^
      duration.hashCode ^
      timestamp.hashCode;

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
}

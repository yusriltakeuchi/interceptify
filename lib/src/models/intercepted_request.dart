import 'package:collection/collection.dart';

/// Represents an HTTP request that has been intercepted by the Dio interceptor.
class InterceptedRequest {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final dynamic body;
  final DateTime timestamp;
  final bool paused;

  InterceptedRequest({
    required this.id,
    required this.method,
    required this.url,
    this.headers,
    this.queryParameters,
    this.body,
    required this.timestamp,
    this.paused = false,
  });

  /// Convert to JSON for serialization to DevTools
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'headers': headers,
      'queryParameters': queryParameters,
      'body': _serializeBody(body),
      'timestamp': timestamp.toIso8601String(),
      'paused': paused,
    };
  }

  /// Create from JSON (from DevTools)
  factory InterceptedRequest.fromJson(Map<String, dynamic> json) {
    return InterceptedRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      headers: json['headers'] as Map<String, dynamic>?,
      queryParameters: json['queryParameters'] as Map<String, dynamic>?,
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      paused: json['paused'] as bool? ?? false,
    );
  }

  /// Create a copy with optional field overrides
  InterceptedRequest copyWith({
    String? id,
    String? method,
    String? url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    DateTime? timestamp,
    bool? paused,
  }) {
    return InterceptedRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      paused: paused ?? this.paused,
    );
  }

  @override
  String toString() {
    return 'InterceptedRequest(id: $id, method: $method, url: $url, paused: $paused)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterceptedRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          method == other.method &&
          url == other.url &&
          const DeepCollectionEquality().equals(headers, other.headers) &&
          const DeepCollectionEquality()
              .equals(queryParameters, other.queryParameters) &&
          body == other.body &&
          timestamp == other.timestamp &&
          paused == other.paused;

  @override
  int get hashCode =>
      id.hashCode ^
      method.hashCode ^
      url.hashCode ^
      headers.hashCode ^
      queryParameters.hashCode ^
      body.hashCode ^
      timestamp.hashCode ^
      paused.hashCode;

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

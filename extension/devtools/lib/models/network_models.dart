/// Models for network events
class NetworkRequest {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final dynamic body;
  final DateTime timestamp;
  final bool paused;

  /// Which HTTP client produced this request: 'dio' | 'http' | 'graphql'
  final String clientType;

  NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    this.headers,
    this.queryParameters,
    this.body,
    required this.timestamp,
    this.paused = false,
    this.clientType = 'dio',
  });

  factory NetworkRequest.fromJson(Map<String, dynamic> json) {
    return NetworkRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      headers: json['headers'] as Map<String, dynamic>?,
      queryParameters: json['queryParameters'] as Map<String, dynamic>?,
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      paused: json['paused'] as bool? ?? false,
      clientType: json['clientType'] as String? ?? 'dio',
    );
  }
}

class NetworkResponse {
  final String requestId;
  final int? statusCode;
  final dynamic body;
  final Map<String, dynamic>? headers;
  final int durationMillis;
  final DateTime timestamp;

  NetworkResponse({
    required this.requestId,
    this.statusCode,
    this.body,
    this.headers,
    required this.durationMillis,
    required this.timestamp,
  });

  factory NetworkResponse.fromJson(Map<String, dynamic> json) {
    return NetworkResponse(
      requestId: json['requestId'] as String,
      statusCode: json['statusCode'] as int?,
      body: json['body'],
      headers: json['headers'] as Map<String, dynamic>?,
      durationMillis: json['duration'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class NetworkError {
  final String requestId;
  final String errorMessage;
  final String? errorType;
  final DateTime timestamp;

  NetworkError({
    required this.requestId,
    required this.errorMessage,
    this.errorType,
    required this.timestamp,
  });

  factory NetworkError.fromJson(Map<String, dynamic> json) {
    return NetworkError(
      requestId: json['requestId'] as String,
      errorMessage: json['errorMessage'] as String,
      errorType: json['errorType'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

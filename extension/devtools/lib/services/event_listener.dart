import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:vm_service/vm_service.dart';

import '../utils.dart';

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

  NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    this.headers,
    this.queryParameters,
    this.body,
    required this.timestamp,
    this.paused = false,
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

/// Listens to Interceptify events from the app
class InterceptifyEventListener {
  final ServiceManager serviceManager;
  final StreamController<NetworkRequest> _requestController =
      StreamController<NetworkRequest>.broadcast();
  final StreamController<NetworkResponse> _responseController =
      StreamController<NetworkResponse>.broadcast();
  final StreamController<NetworkError> _errorController =
      StreamController<NetworkError>.broadcast();

  StreamSubscription? _subscription;

  InterceptifyEventListener({required this.serviceManager}) {
    _setupEventListener();
  }

  /// Stream of network requests
  Stream<NetworkRequest> get requestStream => _requestController.stream;

  /// Stream of network responses
  Stream<NetworkResponse> get responseStream => _responseController.stream;

  /// Stream of network errors
  Stream<NetworkError> get errorStream => _errorController.stream;

  /// Set up the event listener
  void _setupEventListener() {
    final service = serviceManager.service;
    
    if (service == null) {
      print('⚠️ VM Service not available yet. Event listener will retry.');
      Future.delayed(const Duration(milliseconds: 500), _setupEventListener);
      return;
    }
    
    try {
      _subscription = service.onExtensionEvent.listen((event) {
        _handleExtensionEvent(event);
      });
      print('✅ Event listener started successfully');
    } catch (e) {
      print('Error setting up event listener: $e');
    }
  }

  /// Handle extension events from the app
  void _handleExtensionEvent(Event event) {
    try {
      final eventKind = event.extensionKind;
      final data = event.extensionData?.data;

      if (data == null) return;

      if (eventKind == InterceptifyConstants.requestEventKind) {
        final request = data['request'] as Map<String, dynamic>?;
        if (request != null) {
          _requestController.add(NetworkRequest.fromJson(request));
        }
      } else if (eventKind == InterceptifyConstants.responseEventKind) {
        _responseController.add(NetworkResponse.fromJson(data));
      } else if (eventKind == InterceptifyConstants.errorEventKind) {
        _errorController.add(NetworkError.fromJson(data));
      }
    } catch (e) {
      print('Error handling extension event: $e');
    }
  }

  /// Dispose the listener
  void dispose() {
    _subscription?.cancel();
    _requestController.close();
    _responseController.close();
    _errorController.close();
  }
}

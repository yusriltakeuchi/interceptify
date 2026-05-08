import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:devtools_app_shared/service.dart';
import 'package:vm_service/vm_service.dart';

import '../utils.dart';

import '../models/network_models.dart';

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
      debugPrint('⚠️ VM Service not available yet. Event listener will retry.');
      Future.delayed(const Duration(milliseconds: 500), _setupEventListener);
      return;
    }

    try {
      _subscription = service.onExtensionEvent.listen((event) {
        _handleExtensionEvent(event);
      });
      debugPrint('✅ Event listener started successfully');
    } catch (e) {
      debugPrint('Error setting up event listener: $e');
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
      debugPrint('Error handling extension event: $e');
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

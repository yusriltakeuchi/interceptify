import 'dart:convert';
import 'package:devtools_app_shared/service.dart';
import 'package:interceptify_devtools/utils.dart';
import 'package:vm_service/vm_service.dart';

/// Client for calling Interceptify VM Service extensions
class InterceptifyVMServiceClient {
  final ServiceManager serviceManager;

  InterceptifyVMServiceClient({required this.serviceManager});

  VmService get vmService => serviceManager.service!;

  /// Get all pending requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.getPendingRequestsExtension,
      );
      
      final result = response.json?['result'] as List?;
      if (result != null) {
        return List<Map<String, dynamic>>.from(
          result.cast<Map<String, dynamic>>(),
        );
      }
      return [];
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Continue a paused request with optional modifications
  Future<bool> continueRequest(
    String requestId, {
    Map<String, dynamic>? modifications,
  }) async {
    try {
      final params = {
        'requestId': requestId,
        if (modifications != null)
          'modifications': jsonEncode(modifications),
      };

      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.continueRequestExtension,
        args: params,
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error continuing request: $e');
      return false;
    }
  }

  /// Cancel a paused request
  Future<bool> cancelRequest(String requestId) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.cancelRequestExtension,
        args: {'requestId': requestId},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error canceling request: $e');
      return false;
    }
  }

  /// Add an interception rule
  Future<bool> addRule(Map<String, dynamic> rule) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.addRuleExtension,
        args: {'rule': jsonEncode(rule)},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error adding rule: $e');
      return false;
    }
  }

  /// Remove an interception rule
  Future<bool> removeRule(String ruleId) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.removeRuleExtension,
        args: {'ruleId': ruleId},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error removing rule: $e');
      return false;
    }
  }

  /// Clear all rules
  Future<bool> clearRules() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.clearRulesExtension,
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error clearing rules: $e');
      return false;
    }
  }

  /// Toggle interception globally
  Future<bool> toggleInterception(bool enabled) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.toggleInterceptionExtension,
        args: {'enabled': enabled.toString()},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error toggling interception: $e');
      return false;
    }
  }

  /// Get interception status
  Future<bool> getInterceptionStatus() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.getInterceptionStatusExtension,
      );

      return response.json?['enabled'] == true;
    } catch (e) {
      print('Error getting interception status: $e');
      return true; // Default to enabled
    }
  }

  /// Toggle pause all requests
  Future<bool> togglePauseAll(bool pause) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.togglePauseAllExtension,
        args: {'pause': pause.toString()},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error toggling pause all: $e');
      return false;
    }
  }

  /// Toggle pause all responses
  Future<bool> togglePauseAllResponses(bool pause) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.interceptify.togglePauseAllResponses',
        args: {'pause': pause.toString()},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error toggling pause all responses: $e');
      return false;
    }
  }

  /// Continue a paused response
  Future<bool> continueResponse(String requestId,
      {Map<String, dynamic>? modifications}) async {
    try {
      final params = {
        'requestId': requestId,
        if (modifications != null) 'modifications': jsonEncode(modifications),
      };

      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.interceptify.continueResponse',
        args: params,
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error continuing response: $e');
      return false;
    }
  }

  /// Retry a request
  Future<bool> retryRequest(Map<String, dynamic> request) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.interceptify.retryRequest',
        args: {'request': jsonEncode(request)},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error retrying request: $e');
      return false;
    }
  }

  /// Get interception timeout
  Future<int> getTimeout() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.getTimeoutExtension,
      );
      
      return response.json?['timeout'] as int? ?? 30;
    } catch (e) {
      print('Error getting timeout: $e');
      return 30;
    }
  }

  /// Set interception timeout
  Future<bool> setTimeout(int seconds) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        InterceptifyConstants.setTimeoutExtension,
        args: {'timeout': seconds.toString()},
      );

      return response.json?['success'] == true;
    } catch (e) {
      print('Error setting timeout: $e');
      return false;
    }
  }
}

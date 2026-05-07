/// Constants used by the DevTools extension
class InterceptifyConstants {
  InterceptifyConstants._();

  /// Base extension name for VM Service extensions
  static const String extensionName = 'ext.interceptify';

  /// Extension for getting pending requests
  static const String getPendingRequestsExtension =
      'ext.interceptify.getPendingRequests';

  /// Extension for continuing a paused request
  static const String continueRequestExtension =
      'ext.interceptify.continueRequest';

  /// Extension for canceling a paused request
  static const String cancelRequestExtension = 'ext.interceptify.cancelRequest';

  /// Extension for adding a rule
  static const String addRuleExtension = 'ext.interceptify.addRule';

  /// Extension for removing a rule
  static const String removeRuleExtension = 'ext.interceptify.removeRule';

  /// Extension for clearing all rules
  static const String clearRulesExtension = 'ext.interceptify.clearRules';

  /// Event kind for request events
  static const String requestEventKind = 'ext.interceptify.requestEvent';

  /// Event kind for response events
  static const String responseEventKind = 'ext.interceptify.responseEvent';

  /// Event kind for error events
  static const String errorEventKind = 'ext.interceptify.errorEvent';

  /// Extension for toggling interception
  static const String toggleInterceptionExtension =
      'ext.interceptify.toggleInterception';

  /// Extension for getting interception status
  static const String getInterceptionStatusExtension =
      'ext.interceptify.getInterceptionStatus';

  /// Extension for toggling pause all requests
  static const String togglePauseAllExtension =
      'ext.interceptify.togglePauseAll';

  /// Extension for getting timeout setting
  static const String getTimeoutExtension = 'ext.interceptify.getTimeout';

  /// Extension for setting timeout setting
  static const String setTimeoutExtension = 'ext.interceptify.setTimeout';
}

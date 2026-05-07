/// Constants used throughout the interceptify package
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

  /// Event kind for request events posted to DevTools
  static const String requestEventKind = 'ext.interceptify.requestEvent';

  /// Event kind for response events posted to DevTools
  static const String responseEventKind = 'ext.interceptify.responseEvent';

  /// Event kind for error events posted to DevTools
  static const String errorEventKind = 'ext.interceptify.errorEvent';

  /// Extension for toggling interception globally
  static const String toggleInterceptionExtension =
      'ext.interceptify.toggleInterception';

  /// Extension for getting interception status
  static const String getInterceptionStatusExtension =
      'ext.interceptify.getInterceptionStatus';

  /// Extension for toggling pause all requests
  static const String togglePauseAllExtension =
      'ext.interceptify.togglePauseAll';

  /// Default timeout for paused requests (30 seconds)
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum body size to capture (1MB) - currently not enforced but available for future
  static const int maxBodySize = 1024 * 1024;

  /// Stream name for extension events
  static const String extensionStreamName = 'Extension';
}

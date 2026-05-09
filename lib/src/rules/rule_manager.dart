import 'package:dio/dio.dart';

import 'intercept_rule.dart';

/// Manages a collection of interception rules
class RuleManager {
  final List<InterceptRule> _rules = [];
  bool _enabled = true;
  bool _pauseAllRequests = false;
  bool _pauseAllResponses = false;
  int _timeoutSeconds = 30;

  /// Whether interception is enabled globally
  bool get enabled => _enabled;

  /// Whether all requests should be paused regardless of rules
  bool get pauseAllRequests => _pauseAllRequests;

  /// Whether all responses should be paused
  bool get pauseAllResponses => _pauseAllResponses;

  /// Timeout in seconds for paused requests/responses
  int get timeoutSeconds => _timeoutSeconds;

  /// Set timeout in seconds
  void setTimeoutSeconds(int seconds) {
    _timeoutSeconds = seconds;
  }

  /// Set global enabled state
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set pause all requests state
  void setPauseAllRequests(bool pause) {
    _pauseAllRequests = pause;
  }

  /// Set pause all responses state
  void setPauseAllResponses(bool pause) {
    _pauseAllResponses = pause;
  }

  /// Get all rules (defensive copy)
  List<InterceptRule> get rules => List.unmodifiable(_rules);

  /// Add a new rule
  void addRule(InterceptRule rule) {
    _rules.add(rule);
  }

  /// Remove a rule by ID
  bool removeRule(String ruleId) {
    final initialLength = _rules.length;
    _rules.removeWhere((rule) => rule.id == ruleId);
    return _rules.length < initialLength;
  }

  /// Remove a rule by reference
  bool removeRuleByInstance(InterceptRule rule) {
    return _rules.remove(rule);
  }

  /// Clear all rules
  void clearRules() {
    _rules.clear();
  }

  /// Get rule by ID
  InterceptRule? getRule(String ruleId) {
    try {
      return _rules.firstWhere((rule) => rule.id == ruleId);
    } catch (e) {
      return null;
    }
  }

  /// Update a rule
  bool updateRule(String ruleId, InterceptRule updatedRule) {
    final index = _rules.indexWhere((rule) => rule.id == ruleId);
    if (index >= 0) {
      _rules[index] = updatedRule;
      return true;
    }
    return false;
  }

  /// Check if any enabled rule matches the given request options
  bool shouldPause(RequestOptions requestOptions) {
    if (!_enabled) return false;
    if (_pauseAllRequests) return true;
    return _rules.any((rule) => rule.matches(requestOptions));
  }

  /// Check if a generic HTTP request (non-Dio) should be paused.
  /// Used by [InterceptifyHttpClient] and [InterceptifyGraphQLLink].
  bool shouldPauseHttpRequest(String method, String url) {
    if (!_enabled) return false;
    if (_pauseAllRequests) return true;
    return _rules.any((rule) => rule.matchesHttp(method, url));
  }

  /// Get all matching rules for the given request options
  List<InterceptRule> getMatchingRules(RequestOptions requestOptions) {
    return _rules.where((rule) => rule.matches(requestOptions)).toList();
  }

  /// Toggle a rule's enabled state
  void toggleRule(String ruleId) {
    final rule = getRule(ruleId);
    if (rule != null) {
      updateRule(ruleId, rule.copyWith(enabled: !rule.enabled));
    }
  }

  /// Enable all rules
  void enableAllRules() {
    for (int i = 0; i < _rules.length; i++) {
      _rules[i].enabled = true;
    }
  }

  /// Disable all rules
  void disableAllRules() {
    for (int i = 0; i < _rules.length; i++) {
      _rules[i].enabled = false;
    }
  }

  /// Get number of rules
  int get ruleCount => _rules.length;

  /// Get number of enabled rules
  int get enabledRuleCount => _rules.where((rule) => rule.enabled).length;

  /// Convert all rules to JSON
  List<Map<String, dynamic>> toJson() => _rules.map((r) => r.toJson()).toList();

  /// Load rules from JSON
  void loadFromJson(List<Map<String, dynamic>> json) {
    _rules.clear();
    for (final ruleJson in json) {
      _rules.add(InterceptRule.fromJson(ruleJson));
    }
  }
}

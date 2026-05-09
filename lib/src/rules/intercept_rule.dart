import 'package:dio/dio.dart';

/// Enum for different rule condition types
enum RuleCondition {
  /// Pause all requests
  always,

  /// Pause requests matching a URL substring
  urlContains,

  /// Pause requests matching an HTTP method
  methodEquals,
}

/// Represents an interception rule that determines when requests should be paused
class InterceptRule {
  /// Unique identifier for the rule
  final String id;

  /// Type of condition for this rule
  final RuleCondition condition;

  /// Value to match against (e.g., URL substring, HTTP method)
  final String? value;

  /// Whether this rule is currently enabled
  bool enabled;

  /// When the rule was created
  final DateTime createdAt;

  InterceptRule({
    required this.id,
    required this.condition,
    this.value,
    this.enabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if a request matches this rule
  bool matches(RequestOptions requestOptions) {
    if (!enabled) return false;

    switch (condition) {
      case RuleCondition.always:
        return true;

      case RuleCondition.urlContains:
        if (value == null) return false;
        return requestOptions.uri.toString().contains(value!);

      case RuleCondition.methodEquals:
        if (value == null) return false;
        return requestOptions.method.toUpperCase() == value!.toUpperCase();
    }
  }

  /// Check if a generic HTTP request (without Dio's RequestOptions) matches.
  /// Used by [InterceptifyHttpClient].
  bool matchesHttp(String method, String url) {
    if (!enabled) return false;

    switch (condition) {
      case RuleCondition.always:
        return true;
      case RuleCondition.urlContains:
        if (value == null) return false;
        return url.contains(value!);
      case RuleCondition.methodEquals:
        if (value == null) return false;
        return method.toUpperCase() == value!.toUpperCase();
    }
  }

  /// Convert to JSON for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition': condition.name,
      'value': value,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory InterceptRule.fromJson(Map<String, dynamic> json) {
    return InterceptRule(
      id: json['id'] as String,
      condition: RuleCondition.values.byName(
        json['condition'] as String? ?? 'always',
      ),
      value: json['value'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Create a copy with optional overrides
  InterceptRule copyWith({
    String? id,
    RuleCondition? condition,
    String? value,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return InterceptRule(
      id: id ?? this.id,
      condition: condition ?? this.condition,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'InterceptRule(id: $id, condition: ${condition.name}, value: $value, enabled: $enabled)';
}

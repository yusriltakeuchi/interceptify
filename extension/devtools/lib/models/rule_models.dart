import 'package:flutter/material.dart';

enum RuleCondition { always, urlContains, methodEquals }

extension RuleConditionExt on RuleCondition {
  String get displayName {
    switch (this) {
      case RuleCondition.always:
        return 'Pause All';
      case RuleCondition.urlContains:
        return 'URL Contains';
      case RuleCondition.methodEquals:
        return 'Method Equals';
    }
  }

  IconData get icon {
    switch (this) {
      case RuleCondition.always:
        return Icons.all_inclusive;
      case RuleCondition.urlContains:
        return Icons.link;
      case RuleCondition.methodEquals:
        return Icons.http;
    }
  }
}

class InterceptionRule {
  final String id;
  final String condition;
  final String? value;
  final bool enabled;
  final DateTime createdAt;

  InterceptionRule({
    required this.id,
    required this.condition,
    this.value,
    this.enabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InterceptionRule.fromJson(Map<String, dynamic> json) {
    return InterceptionRule(
      id: json['id'] as String,
      condition: json['condition'] as String? ?? 'always',
      value: json['value'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition': condition,
      'value': value,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

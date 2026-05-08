import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/vm_service_client.dart';

import '../models/rule_models.dart';

class RuleEditorView extends StatefulWidget {
  final InterceptifyVMServiceClient vmServiceClient;

  const RuleEditorView({super.key, required this.vmServiceClient});

  @override
  State<RuleEditorView> createState() => InterceptionRuleEditorViewState();
}

class InterceptionRuleEditorViewState extends State<RuleEditorView> {
  final List<InterceptionRule> _rules = [];
  RuleCondition _selectedCondition = RuleCondition.always;
  final _valueController = TextEditingController();
  final _timeoutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTimeout();
  }

  Future<void> _fetchTimeout() async {
    final timeout = await widget.vmServiceClient.getTimeout();
    if (mounted) {
      setState(() {
        _timeoutController.text = timeout.toString();
      });
    }
  }

  Future<void> _updateTimeout() async {
    final timeout = int.tryParse(_timeoutController.text);
    if (timeout != null && timeout > 0) {
      final success = await widget.vmServiceClient.setTimeout(timeout);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timeout updated successfully')),
        );
      }
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  Future<void> _addRule() async {
    if (_selectedCondition == RuleCondition.urlContains ||
        _selectedCondition == RuleCondition.methodEquals) {
      if (_valueController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a value')));
        return;
      }
    }

    setState(() => _isLoading = true);
    final rule = InterceptionRule(
      id: const Uuid().v4(),
      condition: _selectedCondition.name,
      value: _valueController.text.isNotEmpty ? _valueController.text : null,
      enabled: true,
    );

    final success = await widget.vmServiceClient.addRule(rule.toJson());

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() {
          _rules.add(rule);
          _valueController.clear();
          _selectedCondition = RuleCondition.always;
        });
      }
    }
  }

  Future<void> _removeRule(String ruleId) async {
    final success = await widget.vmServiceClient.removeRule(ruleId);
    if (success && mounted) {
      setState(() {
        _rules.removeWhere((r) => r.id == ruleId);
      });
    }
  }

  Future<void> _clearRules() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Rules?'),
        content: const Text('This will remove all active interception rules.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.vmServiceClient.clearRules();
      if (success && mounted) {
        setState(() => _rules.clear());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 350, child: _buildAddRuleSection()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildRulesListSection()),
              ],
            );
          }
          return Column(
            children: [
              _buildAddRuleSection(),
              const Divider(height: 1),
              Expanded(child: _buildRulesListSection()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddRuleSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('NEW RULE', Icons.add_circle_outline),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Condition',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RuleCondition>(
                        value: _selectedCondition,
                        isExpanded: true,
                        items: RuleCondition.values.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Row(
                              children: [
                                Icon(condition.icon, size: 18),
                                const SizedBox(width: 12),
                                Text(condition.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCondition = value);
                          }
                        },
                      ),
                    ),
                  ),
                  if (_selectedCondition == RuleCondition.urlContains ||
                      _selectedCondition == RuleCondition.methodEquals) ...[
                    const SizedBox(height: 16),
                    Text(
                      _selectedCondition == RuleCondition.urlContains
                          ? 'URL Snippet'
                          : 'HTTP Method',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        hintText:
                            _selectedCondition == RuleCondition.urlContains
                            ? 'e.g. /users'
                            : 'e.g. POST',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addRule,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Create Rule',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(),
          const SizedBox(height: 24),
          const Text(
            'Rules are used to automatically pause requests that match specific criteria.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SETTINGS', Icons.settings),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interception Timeout (seconds)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timeoutController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 30',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _updateTimeout,
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Auto-resume request/response if no action taken within this time.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesListSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              _buildSectionHeader('ACTIVE RULES', Icons.list),
              const Spacer(),
              if (_rules.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearRules,
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),
        Expanded(
          child: _rules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    final condition = RuleCondition.values.byName(
                      rule.condition,
                    );
                    return _buildRuleCard(rule, condition);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(InterceptionRule rule, RuleCondition condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            condition.icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          condition.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: rule.value != null
            ? Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).disabledColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rule.value!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeRule(rule.id),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rule_folder_outlined,
            size: 64,
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No interception rules active',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }
}

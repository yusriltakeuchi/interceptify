import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../services/event_listener.dart';
import '../services/vm_service_client.dart';
import 'request_detail_view.dart';
import 'request_list_view.dart';
import 'rule_editor_view.dart';

enum _ViewTab { requests, rules }

/// Main screen for the Interceptify DevTools extension
class InterceptifyExtensionScreen extends StatefulWidget {
  const InterceptifyExtensionScreen({Key? key}) : super(key: key);

  @override
  State<InterceptifyExtensionScreen> createState() =>
      _InterceptifyExtensionScreenState();
}

class _InterceptifyExtensionScreenState
    extends State<InterceptifyExtensionScreen> {
  InterceptifyVMServiceClient? _vmServiceClient;
  InterceptifyEventListener? _eventListener;
  
  // Persisted state across tabs
  final List<NetworkRequest> _requests = [];
  final Map<String, NetworkResponse> _responses = {};
  final Map<String, NetworkError> _errors = {};
  NetworkRequest? _selectedRequest;
  bool _interceptionEnabled = true;
  bool _pauseAllEnabled = false;
  bool _pauseAllResponsesEnabled = false;

  _ViewTab _selectedTab = _ViewTab.requests;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final vmService = await serviceManager.onServiceAvailable;
      
      if (!mounted) return;

      if (vmService == null) {
        Future.delayed(const Duration(milliseconds: 1000), _initializeServices);
        return;
      }
      
      _vmServiceClient = InterceptifyVMServiceClient(serviceManager: serviceManager);
      _eventListener = InterceptifyEventListener(serviceManager: serviceManager);
      
      _setupListeners();

      // Fetch initial status
      final status = await _vmServiceClient?.getInterceptionStatus() ?? true;
      
      setState(() {
        _interceptionEnabled = status;
        _isInitialized = true;
      });
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 1000), _initializeServices);
    }
  }

  void _setupListeners() {
    _eventListener?.requestStream.listen((request) {
      if (!mounted) return;
      setState(() {
        final index = _requests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _requests[index] = request;
          if (_selectedRequest?.id == request.id) {
            _selectedRequest = request;
          }
        } else {
          _requests.insert(0, request);
          if (_requests.length > 200) {
            _requests.removeAt(_requests.length - 1);
          }
        }
      });
    });

    _eventListener?.responseStream.listen((response) {
      if (!mounted) return;
      setState(() {
        _responses[response.requestId] = response;
      });
    });

    _eventListener?.errorStream.listen((error) {
      if (!mounted) return;
      setState(() {
        _errors[error.requestId] = error;
      });
    });
  }

  @override
  void dispose() {
    _eventListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _vmServiceClient == null || _eventListener == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Interceptify'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, size: 20),
            const SizedBox(width: 8),
            const Text('Interceptify', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).canvasColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
        actions: [
          _buildActionSwitch(
            label: _interceptionEnabled ? 'Intercepting' : 'Bypass',
            value: _interceptionEnabled,
            activeColor: Colors.green,
            onChanged: (v) async {
              if (await _vmServiceClient?.toggleInterception(v) ?? false) {
                setState(() {
                  _interceptionEnabled = v;
                  if (!v) {
                    _pauseAllEnabled = false;
                    _pauseAllResponsesEnabled = false;
                  }
                });
              }
            },
          ),
          if (_interceptionEnabled) ...[
            _buildActionSwitch(
              label: 'Pause Req',
              value: _pauseAllEnabled,
              activeColor: Colors.orange,
              onChanged: (v) async {
                if (await _vmServiceClient?.togglePauseAll(v) ?? false) {
                  setState(() => _pauseAllEnabled = v);
                }
              },
            ),
            _buildActionSwitch(
              label: 'Pause Res',
              value: _pauseAllResponsesEnabled,
              activeColor: Colors.deepOrange,
              onChanged: (v) async {
                if (await _vmServiceClient?.togglePauseAllResponses(v) ?? false) {
                  setState(() => _pauseAllResponsesEnabled = v);
                }
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: Row(
              children: [
                // Navigation Sidebar
                _buildSidebar(),
                const VerticalDivider(width: 1),
                // Main Content
                Expanded(
                  child: _selectedTab == _ViewTab.requests
                      ? _buildRequestsView()
                      : RuleEditorView(vmServiceClient: _vmServiceClient!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          _buildSidebarItem(
            icon: Icons.network_check,
            label: 'Requests',
            tab: _ViewTab.requests,
          ),
          _buildSidebarItem(
            icon: Icons.rule,
            label: 'Rules',
            tab: _ViewTab.rules,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required _ViewTab tab,
  }) {
    final isSelected = _selectedTab == tab;
    return Material(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSwitch({
    required String label,
    required bool value,
    required Color activeColor,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              activeTrackColor: activeColor.withOpacity(0.4),
              activeColor: activeColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final pendingCount = _requests.where((r) => r.paused).length;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          _buildSummaryItem(Icons.swap_vert, '${_requests.length} total'),
          const SizedBox(width: 16),
          _buildSummaryItem(Icons.pause_circle_outline, '$pendingCount pending',
              color: pendingCount > 0 ? Colors.orange : null),
          const SizedBox(width: 16),
          _buildSummaryItem(Icons.error_outline, '${_errors.length} errors',
              color: _errors.isNotEmpty ? Colors.red : null),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _requests.clear();
                _responses.clear();
                _errors.clear();
                _selectedRequest = null;
              });
            },
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text('Clear all', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildRequestsView() {
    return Row(
      children: [
        // List
        SizedBox(
          width: 350,
          child: RequestListView(
            requests: _requests,
            responses: _responses,
            errors: _errors,
            selectedRequest: _selectedRequest,
            onRequestSelected: (request) => setState(() => _selectedRequest = request),
          ),
        ),
        const VerticalDivider(width: 1),
        // Detail
        Expanded(
          child: _selectedRequest == null
              ? _buildEmptyState()
              : RequestDetailView(
                  key: ValueKey(_selectedRequest!.id),
                  request: _selectedRequest!,
                  response: _responses[_selectedRequest!.id],
                  error: _errors[_selectedRequest!.id],
                  vmServiceClient: _vmServiceClient!,
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
          Icon(Icons.network_check, size: 64, color: Theme.of(context).disabledColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Select a request to view details',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }
}

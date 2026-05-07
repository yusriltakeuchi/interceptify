import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/event_listener.dart';
import '../services/vm_service_client.dart';

/// Widget displaying detailed information about a selected request
class RequestDetailView extends StatefulWidget {
  final NetworkRequest request;
  final NetworkResponse? response;
  final NetworkError? error;
  final InterceptifyVMServiceClient vmServiceClient;

  const RequestDetailView({
    Key? key,
    required this.request,
    this.response,
    this.error,
    required this.vmServiceClient,
  }) : super(key: key);

  @override
  State<RequestDetailView> createState() => _RequestDetailViewState();
}

class _RequestDetailViewState extends State<RequestDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _editedHeaders;
  late Map<String, dynamic> _editedQueryParams;
  late dynamic _editedBody;
  late String _editedUrl;
  late String _editedMethod;
  bool _isEditing = false;
  
  // For response editing
  int? _editedStatusCode;
  dynamic _editedResponseBody;
  bool _isEditingResponse = false;

  final _bodyController = TextEditingController();
  final _responseBodyController = TextEditingController();
  final _statusCodeController = TextEditingController();
  final _urlController = TextEditingController();
  
  // Map to store controllers for dynamic fields (headers/params)
  final Map<String, TextEditingController> _headerControllers = {};
  final Map<String, TextEditingController> _queryControllers = {};

  void _initializeResponseEditing() {
    _editedStatusCode = widget.response?.statusCode;
    _editedResponseBody = widget.response?.body;
    _responseBodyController.text = _formatValue(_editedResponseBody);
    _statusCodeController.text = _editedStatusCode?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeEditableFields();
  }

  void _initializeEditableFields() {
    _editedHeaders = Map.from(widget.request.headers ?? {});
    _editedQueryParams = Map.from(widget.request.queryParameters ?? {});
    _editedBody = widget.request.body;
    _editedUrl = widget.request.url;
    _editedMethod = widget.request.method;
    
    _bodyController.text = _formatValue(_editedBody);
    _urlController.text = _editedUrl;
    
    // Refresh dynamic controllers
    _headerControllers.clear();
    _editedHeaders.forEach((k, v) {
      _headerControllers[k] = TextEditingController(text: v.toString());
    });
    
    _queryControllers.clear();
    _editedQueryParams.forEach((k, v) {
      _queryControllers[k] = TextEditingController(text: v.toString());
    });
    
    _initializeResponseEditing();
  }

  @override
  void didUpdateWidget(RequestDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id || 
        (oldWidget.request.paused != widget.request.paused && widget.request.paused) ||
        oldWidget.response != widget.response) {
      _initializeEditableFields();
      _isEditing = false;
      _isEditingResponse = false;
      
      if (oldWidget.response == null && widget.response != null && widget.request.paused) {
        _tabController.animateTo(2); // Switch to Response tab
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bodyController.dispose();
    _responseBodyController.dispose();
    _statusCodeController.dispose();
    _urlController.dispose();
    for (var c in _headerControllers.values) {
      c.dispose();
    }
    for (var c in _queryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _continueRequest() async {
    final modifications = {
      'headers': _editedHeaders,
      'queryParameters': _editedQueryParams,
      'body': _editedBody,
      'url': _editedUrl,
      'method': _editedMethod,
    };

    final success = await widget.vmServiceClient
        .continueRequest(widget.request.id, modifications: modifications);

    if (success) {
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to continue request')),
      );
    }
  }

  Future<void> _continueResponse() async {
    final modifications = {
      if (_editedStatusCode != null) 'statusCode': _editedStatusCode,
      'body': _editedResponseBody,
    };

    final success = await widget.vmServiceClient
        .continueResponse(widget.request.id, modifications: modifications);

    if (success) {
      setState(() => _isEditingResponse = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to continue response')),
      );
    }
  }

  Future<void> _retryRequest() async {
    final requestData = {
      'method': widget.request.method,
      'url': widget.request.url,
      'headers': widget.request.headers,
      'queryParameters': widget.request.queryParameters,
      'body': widget.request.body,
    };

    final success = await widget.vmServiceClient.retryRequest(requestData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retry triggered')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to trigger retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHeadersTab(),
                _buildBodyTab(),
                _buildResponseTab(),
              ],
            ),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMethodBadge(_isEditing ? _editedMethod : widget.request.method),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _urlController,
                        onChanged: (v) => _editedUrl = v,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                        style: const TextStyle(fontSize: 14),
                      )
                    : Text(
                        widget.request.url,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (!_isEditing && (widget.response != null || widget.error != null))
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Retry Request',
                  onPressed: _retryRequest,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Theme.of(context).disabledColor),
              const SizedBox(width: 4),
              Text(
                widget.request.timestamp.toLocal().toString().split('.').first,
                style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor),
              ),
              const Spacer(),
              if (widget.request.paused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    Color color;
    switch (method.toUpperCase()) {
      case 'GET': color = Colors.green; break;
      case 'POST': color = Colors.blue; break;
      case 'PUT': color = Colors.orange; break;
      case 'DELETE': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Headers'),
          Tab(text: 'Body'),
          Tab(text: 'Response'),
        ],
      ),
    );
  }

  Widget _buildHeadersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('REQUEST HEADERS'),
        _buildJsonEditor(
          data: _editedHeaders,
          controllers: _headerControllers,
          onEdit: (key, value) => setState(() => _editedHeaders[key] = value),
          onAdd: () => _showAddDialog('Header', (k, v) {
            setState(() {
              _editedHeaders[k] = v;
              _headerControllers[k] = TextEditingController(text: v.toString());
            });
          }),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('RESPONSE HEADERS'),
        if (widget.response != null && widget.response!.headers != null)
          _buildJsonEditor(
            data: widget.response!.headers!,
            controllers: {}, // Read-only
            readOnly: true,
            onEdit: (_, __) {},
            onAdd: () {},
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No response headers available yet', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildBodyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('QUERY PARAMETERS'),
        _buildJsonEditor(
          data: _editedQueryParams,
          controllers: _queryControllers,
          onEdit: (key, value) => setState(() => _editedQueryParams[key] = value),
          onAdd: () => _showAddDialog('Param', (k, v) {
            setState(() {
              _editedQueryParams[k] = v;
              _queryControllers[k] = TextEditingController(text: v.toString());
            });
          }),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('REQUEST BODY'),
        const SizedBox(height: 8),
        _buildRichJsonEditor(
          data: _editedBody,
          controller: _bodyController,
          isEditing: _isEditing,
          onChanged: (v) => _editedBody = v,
          label: 'Body',
        ),
      ],
    );
  }

  Widget _buildResponseTab() {
    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(widget.error!.errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (widget.response == null) {
      return const Center(child: Text('Waiting for response...'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('RESPONSE SUMMARY'),
        Row(
          children: [
            _buildStatusCodeBadge(_isEditingResponse ? _editedStatusCode ?? 0 : widget.response!.statusCode ?? 0),
            const SizedBox(width: 12),
            Text('${widget.response!.durationMillis} ms', style: TextStyle(color: Theme.of(context).disabledColor)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('RESPONSE BODY'),
        const SizedBox(height: 8),
        _buildRichJsonEditor(
          data: _isEditingResponse ? _editedResponseBody : widget.response!.body,
          controller: _responseBodyController,
          isEditing: _isEditingResponse,
          onChanged: (v) => _editedResponseBody = v,
          label: 'Response Body',
          statusCodeController: _statusCodeController,
        ),
        if (widget.request.paused || _isEditingResponse) ...[
          const SizedBox(height: 16),
          _buildResponseActions(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildStatusCodeBadge(int statusCode) {
    Color color = (statusCode >= 200 && statusCode < 300) ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        statusCode.toString(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildJsonEditor({
    required Map<String, dynamic> data,
    required Map<String, TextEditingController> controllers,
    required Function(String, dynamic) onEdit,
    required VoidCallback onAdd,
    bool readOnly = false,
  }) {
    if (data.isEmpty && !(_isEditing && !readOnly)) {
      return const Text('No data', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic));
    }

    bool editing = _isEditing && !readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...data.entries.map((e) => _buildEditorRow(e.key, e.value, controllers[e.key], onEdit, editing)),
        if (editing)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Entry', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildEditorRow(String key, dynamic value, TextEditingController? controller, Function(String, dynamic) onEdit, bool editing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.blueGrey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: editing
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => onEdit(key, v),
                  )
                : Text(value.toString(), style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRichJsonEditor({
    required dynamic data,
    required TextEditingController controller,
    required bool isEditing,
    required Function(dynamic) onChanged,
    required String label,
    TextEditingController? statusCodeController,
  }) {
    if (isEditing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusCodeController != null) ...[
            TextField(
              controller: statusCodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Status Code', 
                border: const OutlineInputBorder(),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
              ),
              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              onChanged: (v) {
                if (label == 'Response Body') {
                  _editedStatusCode = int.tryParse(v);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: TextField(
              maxLines: null,
              expands: true,
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: 'Enter JSON here...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              ),
              style: const TextStyle(
                fontFamily: 'monospace', 
                fontSize: 13, 
                color: Color(0xFFD4D4D4), // VS Code standard light grey
              ),
              onChanged: (v) {
                try {
                  onChanged(v.startsWith('{') || v.startsWith('[') ? jsonDecode(v) : v);
                } catch (_) {
                  onChanged(v);
                }
              },
            ),
          ),
        ],
      );
    }

    if (data == null || (data is String && data.isEmpty)) {
      return const Text('No data available', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: JsonColorViewer(data: data),
    );
  }

  Widget _buildActionFooter() {
    if (!widget.request.paused || widget.response != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isEditing)
            TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))
          else
            TextButton(
              onPressed: () {
                _initializeEditableFields();
                setState(() => _isEditing = true);
              }, 
              child: const Text('Edit Request'),
            ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _continueRequest,
            child: Text(_isEditing ? 'Continue with Modifications' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isEditingResponse)
          TextButton(onPressed: () => setState(() => _isEditingResponse = false), child: const Text('Cancel'))
        else
          TextButton(
            onPressed: () {
              _initializeResponseEditing();
              setState(() => _isEditingResponse = true);
            }, 
            child: const Text('Edit Response'),
          ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _continueResponse,
          child: Text(_isEditingResponse ? 'Apply & Continue' : 'Continue Response'),
        ),
      ],
    );
  }

  void _showAddDialog(String title, Function(String, dynamic) onAdd) {
    String key = '';
    String value = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (v) => key = v, decoration: const InputDecoration(labelText: 'Key')),
            TextField(onChanged: (v) => value = v, decoration: const InputDecoration(labelText: 'Value')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (key.isNotEmpty) {
                onAdd(key, value);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Map || value is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }
}

class JsonColorViewer extends StatelessWidget {
  final dynamic data;
  const JsonColorViewer({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null) return const Text('null', style: TextStyle(color: Colors.grey));
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace', 
          fontSize: 12, 
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        children: _buildTextSpans(data, 0, isDark),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(dynamic data, int indent, bool isDark) {
    final List<TextSpan> spans = [];
    final String space = '  ' * indent;
    final baseColor = isDark ? Colors.white70 : Colors.black87;

    if (data is Map) {
      spans.add(TextSpan(text: '{\n', style: TextStyle(color: baseColor)));
      final entries = data.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        spans.add(TextSpan(text: '$space  ', style: TextStyle(color: baseColor)));
        spans.add(TextSpan(text: '"${entry.key}"', style: TextStyle(color: isDark ? Colors.cyanAccent : Colors.blue.shade700)));
        spans.add(TextSpan(text: ': ', style: TextStyle(color: baseColor)));
        spans.addAll(_buildTextSpans(entry.value, indent + 1, isDark));
        if (i < entries.length - 1) spans.add(TextSpan(text: ',', style: TextStyle(color: baseColor)));
        spans.add(TextSpan(text: '\n', style: TextStyle(color: baseColor)));
      }
      spans.add(TextSpan(text: '$space}', style: TextStyle(color: baseColor)));
    } else if (data is List) {
      spans.add(TextSpan(text: '[\n', style: TextStyle(color: baseColor)));
      for (int i = 0; i < data.length; i++) {
        spans.add(TextSpan(text: '$space  ', style: TextStyle(color: baseColor)));
        spans.addAll(_buildTextSpans(data[i], indent + 1, isDark));
        if (i < data.length - 1) spans.add(TextSpan(text: ',', style: TextStyle(color: baseColor)));
        spans.add(TextSpan(text: '\n', style: TextStyle(color: baseColor)));
      }
      spans.add(TextSpan(text: '$space]', style: TextStyle(color: baseColor)));
    } else if (data is String) {
      spans.add(TextSpan(text: '"$data"', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green.shade700)));
    } else if (data is num) {
      spans.add(TextSpan(text: data.toString(), style: TextStyle(color: isDark ? Colors.orangeAccent : Colors.orange.shade800)));
    } else if (data is bool) {
      spans.add(TextSpan(text: data.toString(), style: TextStyle(color: isDark ? Colors.blueAccent : Colors.deepPurple.shade700)));
    } else {
      spans.add(TextSpan(text: data.toString(), style: TextStyle(color: baseColor)));
    }

    return spans;
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        (oldWidget.request.paused != widget.request.paused &&
            widget.request.paused) ||
        oldWidget.response != widget.response) {
      _initializeEditableFields();
      _isEditing = false;
      _isEditingResponse = false;

      if (oldWidget.response == null &&
          widget.response != null &&
          widget.request.paused) {
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

    final success = await widget.vmServiceClient.continueRequest(
      widget.request.id,
      modifications: modifications,
    );

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

    final success = await widget.vmServiceClient.continueResponse(
      widget.request.id,
      modifications: modifications,
    );

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Retry triggered')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to trigger retry.')));
    }
  }

  String _buildCurlCommand() {
    final req = widget.request;
    final buf = StringBuffer();
    buf.write('curl -X ${req.method}');
    if (req.headers != null) {
      req.headers!.forEach((k, v) {
        final esc = v.toString().replaceAll("'", "'\\''");
        buf.write(" \\\n  -H '$k: $esc'");
      });
    }
    if (req.body != null) {
      String body;
      if (req.body is Map || req.body is List) {
        body = jsonEncode(req.body);
      } else {
        body = req.body.toString();
      }
      final esc = body.replaceAll("'", "'\\''");
      buf.write(" \\\n  -d '$esc'");
    }
    String url = req.url;
    if (req.queryParameters != null && req.queryParameters!.isNotEmpty) {
      final params = req.queryParameters!.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url = '$url?$params';
    }
    buf.write(" \\\n  '$url'");
    return buf.toString();
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
          _buildUniversalActionFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMethodBadge(
                _isEditing ? _editedMethod : widget.request.method,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _urlController,
                        onChanged: (v) => _editedUrl = v,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      )
                    : Text(
                        widget.request.url,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.terminal, size: 18),
                  tooltip: 'Copy as cURL',
                  onPressed: () async {
                    final curl = _buildCurlCommand();
                    await Clipboard.setData(ClipboardData(text: curl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('cURL copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              if (!_isEditing &&
                  (widget.response != null || widget.error != null))
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
              Icon(
                Icons.access_time,
                size: 14,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.request.timestamp.toLocal().toString().split('.').first,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).disabledColor,
                ),
              ),
              const Spacer(),
              if (widget.request.paused)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
      case 'GET':
        color = Colors.blue;
        break;
      case 'POST':
        color = Colors.green;
        break;
      case 'PUT':
        color = Colors.orange;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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
            child: Text(
              'No response headers available yet',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
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
          onEdit: (key, value) =>
              setState(() => _editedQueryParams[key] = value),
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
            Text(
              widget.error!.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
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
            _buildStatusCodeBadge(
              _isEditingResponse
                  ? _editedStatusCode ?? 0
                  : widget.response!.statusCode ?? 0,
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.response!.durationMillis} ms',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('RESPONSE BODY'),
        const SizedBox(height: 8),
        _buildRichJsonEditor(
          data: _isEditingResponse
              ? _editedResponseBody
              : widget.response!.body,
          controller: _responseBodyController,
          isEditing: _isEditingResponse,
          onChanged: (v) => _editedResponseBody = v,
          label: 'Response Body',
          statusCodeController: _statusCodeController,
        ),
        const SizedBox(height: 80), // Padding for fixed bottom buttons
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
    Color color = (statusCode >= 200 && statusCode < 300)
        ? Colors.green
        : Colors.red;
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
      return const Text(
        'No data',
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    bool editing = _isEditing && !readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...data.entries.map(
          (e) => _buildEditorRow(
            e.key,
            e.value,
            controllers[e.key],
            onEdit,
            editing,
          ),
        ),
        if (editing)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Entry', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildEditorRow(
    String key,
    dynamic value,
    TextEditingController? controller,
    Function(String, dynamic) onEdit,
    bool editing,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: editing
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
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
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (v) {
                if (label == 'Response Body') {
                  _editedStatusCode = int.tryParse(v);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          Container(
            height: 350,
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
                color: Color(0xFFD4D4D4),
              ),
              onChanged: (v) {
                try {
                  onChanged(
                    v.startsWith('{') || v.startsWith('[') ? jsonDecode(v) : v,
                  );
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
      return const Text(
        'No data available',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: JsonColorViewer(data: data),
        ),
      ],
    );
  }

  Widget _buildUniversalActionFooter() {
    if (!widget.request.paused && !_isEditing && !_isEditingResponse)
      return const SizedBox.shrink();

    // Check if we are in a state that requires response actions
    bool showResponseActions =
        widget.response != null &&
        (widget.request.paused || _isEditingResponse);
    // Check if we are in a state that requires request actions (request is paused)
    bool showRequestActions =
        widget.response == null && (widget.request.paused || _isEditing);

    if (!showResponseActions && !showRequestActions)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showRequestActions) ...[
            if (_isEditing)
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              )
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
              child: Text(
                _isEditing ? 'Continue with Modifications' : 'Continue',
              ),
            ),
          ] else if (showResponseActions) ...[
            if (_isEditingResponse)
              TextButton(
                onPressed: () => setState(() => _isEditingResponse = false),
                child: const Text('Cancel'),
              )
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
              child: Text(
                _isEditingResponse ? 'Apply & Continue' : 'Continue Response',
              ),
            ),
          ],
        ],
      ),
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
            TextField(
              onChanged: (v) => key = v,
              decoration: const InputDecoration(labelText: 'Key'),
            ),
            TextField(
              onChanged: (v) => value = v,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
    if (data == null)
      return const Text('null', style: TextStyle(color: Colors.grey));
      
    return Stack(
      children: [
        SelectionArea(child: JsonNodeViewer(data: data)),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy JSON',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              String textToCopy;
              if (data is String) {
                textToCopy = data;
              } else {
                try {
                  textToCopy = const JsonEncoder.withIndent('  ').convert(data);
                } catch (_) {
                  textToCopy = data.toString();
                }
              }
              await Clipboard.setData(ClipboardData(text: textToCopy));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class JsonNodeViewer extends StatefulWidget {
  final dynamic data;
  final int indent;
  final String? keyName;
  final bool isLast;

  const JsonNodeViewer({
    Key? key,
    required this.data,
    this.indent = 0,
    this.keyName,
    this.isLast = true,
  }) : super(key: key);

  @override
  State<JsonNodeViewer> createState() => _JsonNodeViewerState();
}

class _JsonNodeViewerState extends State<JsonNodeViewer> {
  bool _expanded = true;
  bool _isHovering = false;

  void _copyToClipboard() async {
    String textToCopy;
    if (widget.data is String) {
      textToCopy = widget.data;
    } else if (widget.data is Map || widget.data is List) {
      try {
        textToCopy = const JsonEncoder.withIndent('  ').convert(widget.data);
      } catch (_) {
        textToCopy = widget.data.toString();
      }
    } else {
      textToCopy = widget.data.toString();
    }
    
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Node copied'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white70 : Colors.black87;
    final keyColor = isDark ? Colors.cyanAccent : Colors.blue.shade700;
    final stringColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final numberColor = isDark ? Colors.orangeAccent : Colors.orange.shade800;
    final boolColor = isDark ? Colors.blueAccent : Colors.deepPurple.shade700;

    Widget buildKey() {
      if (widget.keyName == null) return const SizedBox.shrink();
      return Text(
        '"${widget.keyName}": ',
        style: TextStyle(
          color: keyColor,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      );
    }

    if (widget.data is Map || widget.data is List) {
      final isMap = widget.data is Map;
      final children = isMap
          ? (widget.data as Map).entries.toList()
          : (widget.data as List);
      final openingBrace = isMap ? '{' : '[';
      final closingBrace = isMap ? '}' : ']';

      if (children.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(left: widget.indent * 16.0),
          child: Row(
            children: [
              buildKey(),
              Text(
                '$openingBrace$closingBrace${widget.isLast ? '' : ','}',
                style: TextStyle(
                  color: baseColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(left: widget.indent * 16.0),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    buildKey(),
                    Text(
                      openingBrace,
                      style: TextStyle(
                        color: baseColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    if (!_expanded)
                      Text(
                        ' ... $closingBrace${widget.isLast ? '' : ','}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    if (_isHovering && widget.keyName != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _copyToClipboard,
                        child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            for (int i = 0; i < children.length; i++)
              JsonNodeViewer(
                data: isMap ? children[i].value : children[i],
                keyName: isMap ? children[i].key.toString() : null,
                indent: widget.indent + 1,
                isLast: i == children.length - 1,
              ),
            Padding(
              padding: EdgeInsets.only(left: widget.indent * 16.0 + 16.0),
              child: Text(
                '$closingBrace${widget.isLast ? '' : ','}',
                style: TextStyle(
                  color: baseColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Primitive values
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: EdgeInsets.only(left: widget.indent * 16.0 + 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildKey(),
            Expanded(
              child: _buildValueWidget(
                widget.data,
                stringColor,
                numberColor,
                boolColor,
                baseColor,
              ),
            ),
            if (!widget.isLast)
              Text(
                ',',
                style: TextStyle(
                  color: baseColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            if (_isHovering && widget.keyName != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _copyToClipboard,
                child: const Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValueWidget(
    dynamic value,
    Color stringColor,
    Color numberColor,
    Color boolColor,
    Color baseColor,
  ) {
    String text = value.toString();
    Color color = baseColor;

    if (value is String) {
      text = '"$value"';
      color = stringColor;
    } else if (value is num) {
      color = numberColor;
    } else if (value is bool) {
      color = boolColor;
    } else if (value == null) {
      text = 'null';
      color = Colors.grey;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
    );
  }
}

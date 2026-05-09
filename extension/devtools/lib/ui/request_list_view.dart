import 'package:flutter/material.dart';

import '../models/network_models.dart';

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

enum _StatusFilter { any, s2xx, s3xx, s4xx, s5xx }

enum _DurationFilter { any, fast, medium, slow }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Widget displaying list of intercepted requests with advanced filtering.
class RequestListView extends StatefulWidget {
  final List<NetworkRequest> requests;
  final Map<String, NetworkResponse> responses;
  final Map<String, NetworkError> errors;
  final NetworkRequest? selectedRequest;
  final Function(NetworkRequest) onRequestSelected;

  const RequestListView({
    super.key,
    required this.requests,
    required this.responses,
    required this.errors,
    this.selectedRequest,
    required this.onRequestSelected,
  });

  @override
  State<RequestListView> createState() => _RequestListViewState();
}

class _RequestListViewState extends State<RequestListView> {
  // --- Search ---
  String _searchQuery = '';
  bool _isRegexMode = false;
  bool _regexInvalid = false;

  // --- Advanced filter panel visibility ---
  bool _showFilters = false;

  // --- Method filter ---
  final Set<String> _selectedMethods = {}; // empty = all

  // --- Status code filter ---
  _StatusFilter _statusFilter = _StatusFilter.any;

  // --- Duration filter ---
  _DurationFilter _durationFilter = _DurationFilter.any;

  // --- Failed only ---
  bool _failedOnly = false;

  // ---------------------------------------------------------------------------
  // Filtering logic
  // ---------------------------------------------------------------------------

  bool _matchesSearch(NetworkRequest r) {
    if (_searchQuery.isEmpty) return true;
    if (_isRegexMode) {
      try {
        final regex = RegExp(_searchQuery, caseSensitive: false);
        return regex.hasMatch(r.url) || regex.hasMatch(r.method);
      } catch (_) {
        return false;
      }
    }
    final q = _searchQuery.toLowerCase();
    return r.url.toLowerCase().contains(q) ||
        r.method.toLowerCase().contains(q);
  }

  bool _matchesMethod(NetworkRequest r) {
    if (_selectedMethods.isEmpty) return true;
    return _selectedMethods.contains(r.method.toUpperCase());
  }

  bool _matchesStatus(NetworkRequest r) {
    if (_statusFilter == _StatusFilter.any) return true;
    final resp = widget.responses[r.id];
    if (resp == null) return false;
    final code = resp.statusCode ?? 0;
    switch (_statusFilter) {
      case _StatusFilter.s2xx:
        return code >= 200 && code < 300;
      case _StatusFilter.s3xx:
        return code >= 300 && code < 400;
      case _StatusFilter.s4xx:
        return code >= 400 && code < 500;
      case _StatusFilter.s5xx:
        return code >= 500;
      case _StatusFilter.any:
        return true;
    }
  }

  bool _matchesDuration(NetworkRequest r) {
    if (_durationFilter == _DurationFilter.any) return true;
    final resp = widget.responses[r.id];
    if (resp == null) return false;
    final ms = resp.durationMillis;
    switch (_durationFilter) {
      case _DurationFilter.fast:
        return ms < 100;
      case _DurationFilter.medium:
        return ms >= 100 && ms <= 500;
      case _DurationFilter.slow:
        return ms > 500;
      case _DurationFilter.any:
        return true;
    }
  }

  bool _matchesFailed(NetworkRequest r) {
    if (!_failedOnly) return true;
    final resp = widget.responses[r.id];
    final err = widget.errors[r.id];
    if (err != null) return true;
    if (resp != null && (resp.statusCode ?? 0) >= 400) return true;
    return false;
  }

  List<NetworkRequest> get _filteredRequests {
    return widget.requests.where((r) {
      return _matchesSearch(r) &&
          _matchesMethod(r) &&
          _matchesStatus(r) &&
          _matchesDuration(r) &&
          _matchesFailed(r);
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedMethods.isNotEmpty ||
      _statusFilter != _StatusFilter.any ||
      _durationFilter != _DurationFilter.any ||
      _failedOnly;

  void _clearFilters() {
    setState(() {
      _selectedMethods.clear();
      _statusFilter = _StatusFilter.any;
      _durationFilter = _DurationFilter.any;
      _failedOnly = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_showFilters) _buildFilterPanel(),
        if (_hasActiveFilters) _buildActiveFilterChips(),
        Expanded(
          child: _filteredRequests.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty || _hasActiveFilters
                        ? 'No requests match filters'
                        : 'No requests yet',
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = _filteredRequests[index];
                    final response = widget.responses[request.id];
                    final error = widget.errors[request.id];
                    final isSelected = widget.selectedRequest?.id == request.id;

                    return RequestItem(
                      request: request,
                      response: response,
                      error: error,
                      isSelected: isSelected,
                      onTap: () => widget.onRequestSelected(request),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: _isRegexMode
                    ? 'Regex search (e.g. /users/\\d+)…'
                    : 'Search URL or method…',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Regex toggle
                    Tooltip(
                      message: 'Regex mode',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _isRegexMode = !_isRegexMode;
                          _regexInvalid = false;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            '.*',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _regexInvalid
                                  ? Colors.red
                                  : _isRegexMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Clear search
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _regexInvalid = false;
                        }),
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _regexInvalid
                        ? Colors.red
                        : Theme.of(context).dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _regexInvalid
                        ? Colors.red
                        : Theme.of(context).dividerColor,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                bool invalid = false;
                if (_isRegexMode && value.isNotEmpty) {
                  try {
                    RegExp(value);
                  } catch (_) {
                    invalid = true;
                  }
                }
                setState(() {
                  _searchQuery = value;
                  _regexInvalid = invalid;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          // Filter toggle
          Tooltip(
            message: _showFilters ? 'Hide filters' : 'Show filters',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _hasActiveFilters
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: _hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method chips
          _buildFilterLabel('Method'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
                .map((m) => _MethodChip(
                      method: m,
                      selected: _selectedMethods.contains(m),
                      onToggle: () => setState(() {
                        if (_selectedMethods.contains(m)) {
                          _selectedMethods.remove(m);
                        } else {
                          _selectedMethods.add(m);
                        }
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Status + Duration row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterLabel('Status'),
                    const SizedBox(height: 4),
                    _buildDropdown<_StatusFilter>(
                      value: _statusFilter,
                      items: const {
                        _StatusFilter.any: 'Any',
                        _StatusFilter.s2xx: '2xx',
                        _StatusFilter.s3xx: '3xx',
                        _StatusFilter.s4xx: '4xx',
                        _StatusFilter.s5xx: '5xx',
                      },
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterLabel('Duration'),
                    const SizedBox(height: 4),
                    _buildDropdown<_DurationFilter>(
                      value: _durationFilter,
                      items: const {
                        _DurationFilter.any: 'Any',
                        _DurationFilter.fast: '< 100ms',
                        _DurationFilter.medium: '100–500ms',
                        _DurationFilter.slow: '> 500ms',
                      },
                      onChanged: (v) => setState(() => _durationFilter = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Failed only
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _failedOnly,
                  onChanged: (v) => setState(() => _failedOnly = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Failed only', style: TextStyle(fontSize: 12)),
              const Spacer(),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    for (final m in _selectedMethods) {
      chips.add(_ActiveChip(
        label: m,
        onRemove: () => setState(() => _selectedMethods.remove(m)),
      ));
    }
    if (_statusFilter != _StatusFilter.any) {
      final labels = {
        _StatusFilter.s2xx: '2xx',
        _StatusFilter.s3xx: '3xx',
        _StatusFilter.s4xx: '4xx',
        _StatusFilter.s5xx: '5xx',
      };
      chips.add(_ActiveChip(
        label: 'Status: ${labels[_statusFilter]}',
        onRemove: () => setState(() => _statusFilter = _StatusFilter.any),
      ));
    }
    if (_durationFilter != _DurationFilter.any) {
      final labels = {
        _DurationFilter.fast: '< 100ms',
        _DurationFilter.medium: '100–500ms',
        _DurationFilter.slow: '> 500ms',
      };
      chips.add(_ActiveChip(
        label: labels[_durationFilter]!,
        onRemove: () => setState(() => _durationFilter = _DurationFilter.any),
      ));
    }
    if (_failedOnly) {
      chips.add(_ActiveChip(
        label: 'Failed only',
        onRemove: () => setState(() => _failedOnly = false),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Wrap(spacing: 4, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).disabledColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MethodChip extends StatelessWidget {
  final String method;
  final bool selected;
  final VoidCallback onToggle;

  const _MethodChip({
    required this.method,
    required this.selected,
    required this.onToggle,
  });

  Color _methodColor(String m) {
    switch (m) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(method);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          method,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request item (unchanged logic, pulled into its own StatelessWidget)
// ---------------------------------------------------------------------------

class RequestItem extends StatelessWidget {
  final NetworkRequest request;
  final NetworkResponse? response;
  final NetworkError? error;
  final bool isSelected;
  final VoidCallback onTap;

  const RequestItem({
    super.key,
    required this.request,
    this.response,
    this.error,
    required this.isSelected,
    required this.onTap,
  });

  String _getResponseType(NetworkResponse? response) {
    if (response == null) return '';
    final contentType = response.headers?.entries
            .cast<MapEntry<String, dynamic>?>()
            .firstWhere(
              (e) => e!.key.toLowerCase() == 'content-type',
              orElse: () => null,
            )
            ?.value
            .toString() ??
        '';
    if (contentType.contains('json')) return 'JSON';
    if (contentType.contains('html')) return 'HTML';
    if (contentType.contains('xml')) return 'XML';
    if (contentType.contains('text')) return 'TEXT';
    final body = response.body;
    if (body is Map || body is List) return 'JSON';
    if (body is String) {
      final trimmed = body.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'JSON';
    }
    return 'DATA';
  }

  Color _getResponseTypeColor(String type) {
    switch (type) {
      case 'JSON':
        return Colors.amber.shade700;
      case 'HTML':
        return Colors.purple;
      case 'XML':
        return Colors.teal;
      case 'TEXT':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$h:$m:$s  $d/$mo';
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responseType = _getResponseType(response);

    return Material(
      color:
          isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMethodBadge(),
              const SizedBox(width: 8),
              _buildUrlInfo(context, responseType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getMethodColor(request.method),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          request.method,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInfo(BuildContext context, String responseType) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Uri.decodeFull(request.url),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _buildStatusText(context),
              const SizedBox(width: 6),
              _buildResponseTypeBadge(responseType),
              if (request.clientType.isNotEmpty) ...[
                const SizedBox(width: 4),
                _buildClientBadge(request.clientType),
              ],
              const Spacer(),
              _buildTimestampAndStatusIcon(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientBadge(String clientType) {
    const colors = {
      'dio': Colors.blue,
      'http': Colors.teal,
    };
    final color = colors[clientType] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        clientType.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context) {
    if (response != null && !request.paused) {
      return Text(
        '${response!.statusCode} · ${response!.durationMillis}ms',
        style: TextStyle(
          fontSize: 10,
          color: (response!.statusCode ?? 0) >= 400
              ? Colors.red
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
      );
    } else if (error != null) {
      return Text(
        'Error: ${error!.errorType}',
        style: const TextStyle(fontSize: 10, color: Colors.red),
      );
    } else {
      return const Text(
        'Pending…',
        style: TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: Colors.orange,
        ),
      );
    }
  }

  Widget _buildResponseTypeBadge(String responseType) {
    if (responseType.isEmpty || response == null || request.paused) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _getResponseTypeColor(responseType).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: _getResponseTypeColor(responseType).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        responseType,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _getResponseTypeColor(responseType),
        ),
      ),
    );
  }

  Widget _buildTimestampAndStatusIcon(BuildContext context) {
    return Row(
      children: [
        Text(
          '${_formatTimestamp(request.timestamp)} · ',
          style: TextStyle(fontSize: 9, color: Theme.of(context).disabledColor),
        ),
        if (response != null && !request.paused)
          Icon(
            response!.statusCode! >= 400
                ? Icons.error_outline
                : Icons.check_circle_outline,
            size: 14,
            color: response!.statusCode! >= 400 ? Colors.red : Colors.green,
          )
        else if (error != null)
          const Icon(Icons.close, size: 14, color: Colors.red),
      ],
    );
  }
}

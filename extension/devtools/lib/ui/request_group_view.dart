import 'package:flutter/material.dart';

import '../models/network_models.dart';
import 'request_list_view.dart';

// ---------------------------------------------------------------------------
// Grouping strategy
// ---------------------------------------------------------------------------

enum GroupingStrategy {
  byDomain('By Domain', Icons.language),
  byPathPrefix('By Path Prefix', Icons.folder_outlined),
  byMethod('By Method', Icons.http),
  byHttpClient('By HTTP Client', Icons.api),
  byStatusFamily('By Status Code', Icons.signal_cellular_alt);

  final String label;
  final IconData icon;
  const GroupingStrategy(this.label, this.icon);
}

/// Groups a list of [NetworkRequest] entries by the given [GroupingStrategy].
class RequestGrouper {
  static Map<String, List<NetworkRequest>> group(
    List<NetworkRequest> requests,
    Map<String, NetworkResponse> responses,
    GroupingStrategy strategy,
  ) {
    switch (strategy) {
      case GroupingStrategy.byDomain:
        return _groupBy(
            requests, (r) => Uri.tryParse(r.url)?.host ?? 'Unknown');
      case GroupingStrategy.byPathPrefix:
        return _groupBy(requests, (r) {
          final segments = Uri.tryParse(r.url)?.pathSegments ?? [];
          if (segments.isEmpty) return '/';
          return '/${segments.first}';
        });
      case GroupingStrategy.byMethod:
        return _groupBy(requests, (r) => r.method.toUpperCase());
      case GroupingStrategy.byHttpClient:
        return _groupBy(requests, (r) => r.clientType);
      case GroupingStrategy.byStatusFamily:
        return _groupBy(requests, (r) {
          final resp = responses[r.id];
          if (resp == null) return 'Pending';
          final code = resp.statusCode ?? 0;
          if (code >= 200 && code < 300) return '2xx Success';
          if (code >= 300 && code < 400) return '3xx Redirect';
          if (code >= 400 && code < 500) return '4xx Client Error';
          if (code >= 500) return '5xx Server Error';
          return 'Unknown';
        });
    }
  }

  static Map<String, List<NetworkRequest>> _groupBy(
    List<NetworkRequest> requests,
    String Function(NetworkRequest) keyFn,
  ) {
    final result = <String, List<NetworkRequest>>{};
    for (final r in requests) {
      final key = keyFn(r);
      result.putIfAbsent(key, () => []).add(r);
    }
    // Sort groups alphabetically, but keep Pending/Unknown at bottom
    final sorted = result.entries.toList()
      ..sort((a, b) {
        final aLow = ['pending', 'unknown'].contains(a.key.toLowerCase());
        final bLow = ['pending', 'unknown'].contains(b.key.toLowerCase());
        if (aLow && !bLow) return 1;
        if (!aLow && bLow) return -1;
        return a.key.compareTo(b.key);
      });
    return Map.fromEntries(sorted);
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Grouped view of requests — similar to Charles Proxy's Focused/Structure view.
/// Each group is an expandable [ExpansionTile].
class RequestGroupView extends StatefulWidget {
  final List<NetworkRequest> requests;
  final Map<String, NetworkResponse> responses;
  final Map<String, NetworkError> errors;
  final NetworkRequest? selectedRequest;
  final Function(NetworkRequest) onRequestSelected;
  final GroupingStrategy strategy;

  const RequestGroupView({
    super.key,
    required this.requests,
    required this.responses,
    required this.errors,
    this.selectedRequest,
    required this.onRequestSelected,
    required this.strategy,
  });

  @override
  State<RequestGroupView> createState() => _RequestGroupViewState();
}

class _RequestGroupViewState extends State<RequestGroupView> {
  final Set<String> _expandedGroups = {};
  String _searchQuery = '';

  List<NetworkRequest> get _filteredRequests {
    if (_searchQuery.isEmpty) return widget.requests;
    final q = _searchQuery.toLowerCase();
    return widget.requests
        .where(
          (r) =>
              r.url.toLowerCase().contains(q) ||
              r.method.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = RequestGrouper.group(
      _filteredRequests,
      widget.responses,
      widget.strategy,
    );

    if (grouped.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Center(
              child: Text(
                'No requests yet',
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView(
            children: grouped.entries.map((entry) {
              return _GroupSection(
                groupKey: entry.key,
                requests: entry.value,
                responses: widget.responses,
                errors: widget.errors,
                selectedRequest: widget.selectedRequest,
                onRequestSelected: widget.onRequestSelected,
                strategy: widget.strategy,
                isExpanded: _expandedGroups.contains(entry.key),
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expandedGroups.add(entry.key);
                    } else {
                      _expandedGroups.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search URL or method…',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group section tile
// ---------------------------------------------------------------------------

class _GroupSection extends StatelessWidget {
  final String groupKey;
  final List<NetworkRequest> requests;
  final Map<String, NetworkResponse> responses;
  final Map<String, NetworkError> errors;
  final NetworkRequest? selectedRequest;
  final Function(NetworkRequest) onRequestSelected;
  final GroupingStrategy strategy;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const _GroupSection({
    required this.groupKey,
    required this.requests,
    required this.responses,
    required this.errors,
    this.selectedRequest,
    required this.onRequestSelected,
    required this.strategy,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  Color _groupColor(BuildContext context) {
    switch (strategy) {
      case GroupingStrategy.byMethod:
        switch (groupKey.toUpperCase()) {
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
      case GroupingStrategy.byStatusFamily:
        if (groupKey.startsWith('2')) return Colors.green;
        if (groupKey.startsWith('3')) return Colors.blue;
        if (groupKey.startsWith('4')) return Colors.orange;
        if (groupKey.startsWith('5')) return Colors.red;
        return Colors.grey;
      case GroupingStrategy.byHttpClient:
        switch (groupKey) {
          case 'http':
            return Colors.teal;
          default:
            return Colors.blue;
        }
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  int get _errorCount => requests
      .where((r) =>
          errors.containsKey(r.id) ||
          ((responses[r.id]?.statusCode ?? 0) >= 400))
      .length;

  @override
  Widget build(BuildContext context) {
    final color = _groupColor(context);
    final errCount = _errorCount;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupKey,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
              ),
              child: Text(
                '${requests.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (errCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$errCount err',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        children: requests.map((r) {
          return RequestItem(
            request: r,
            response: responses[r.id],
            error: errors[r.id],
            isSelected: selectedRequest?.id == r.id,
            onTap: () => onRequestSelected(r),
          );
        }).toList(),
      ),
    );
  }
}

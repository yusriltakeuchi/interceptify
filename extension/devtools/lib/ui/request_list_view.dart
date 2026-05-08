import 'package:flutter/material.dart';

import '../models/network_models.dart';

/// Widget displaying list of intercepted requests
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
  String _searchQuery = '';

  List<NetworkRequest> get _filteredRequests {
    if (_searchQuery.isEmpty) {
      return widget.requests;
    }
    return widget.requests
        .where(
          (r) =>
              r.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.method.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search URL or method...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        // Request list
        Expanded(
          child: _filteredRequests.isEmpty
              ? const Center(child: Text('No requests yet'))
              : ListView.builder(
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = _filteredRequests[index];
                    final response = widget.responses[request.id];
                    final error = widget.errors[request.id];
                    final isSelected = widget.selectedRequest?.id == request.id;

                    return _RequestItem(
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
}

class _RequestItem extends StatelessWidget {
  final NetworkRequest request;
  final NetworkResponse? response;
  final NetworkError? error;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestItem({
    required this.request,
    this.response,
    this.error,
    required this.isSelected,
    required this.onTap,
  });

  String _getResponseType(NetworkResponse? response) {
    if (response == null) return '';
    final contentType =
        response.headers?.entries
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
    // Fallback: infer from body
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
      color: isSelected
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.transparent,
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
            request.url,
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
              const Spacer(),
              _buildTimestampAndStatusIcon(context),
            ],
          ),
        ],
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
        'Pending...',
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
          "${_formatTimestamp(request.timestamp)} · ",
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

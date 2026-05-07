import 'package:flutter/material.dart';

import '../services/event_listener.dart';

/// Widget displaying list of intercepted requests
class RequestListView extends StatefulWidget {
  final List<NetworkRequest> requests;
  final Map<String, NetworkResponse> responses;
  final Map<String, NetworkError> errors;
  final NetworkRequest? selectedRequest;
  final Function(NetworkRequest) onRequestSelected;

  const RequestListView({
    Key? key,
    required this.requests,
    required this.responses,
    required this.errors,
    this.selectedRequest,
    required this.onRequestSelected,
  }) : super(key: key);

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
        .where((r) =>
            r.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.method.toLowerCase().contains(_searchQuery.toLowerCase()))
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
              ? const Center(
                  child: Text('No requests yet'),
                )
              : ListView.builder(
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = _filteredRequests[index];
                    final response = widget.responses[request.id];
                    final error = widget.errors[request.id];
                    final isSelected = widget.selectedRequest?.id == request.id;

                    return Material(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onRequestSelected(request);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              // Method badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
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
                              const SizedBox(width: 8),
                              // URL and status
                              Expanded(
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
                                    if (response != null)
                                      Text(
                                        'Status: ${response.statusCode} - ${response.durationMillis}ms',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                      )
                                    else if (error != null)
                                      Text(
                                        'Error: ${error.errorType}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.red,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Pending...',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Status icon
                              if (response != null)
                                Icon(
                                  response.statusCode! >= 400
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  size: 16,
                                  color: response.statusCode! >= 400
                                      ? Colors.red
                                      : Colors.green,
                                )
                              else if (error != null)
                                const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
}

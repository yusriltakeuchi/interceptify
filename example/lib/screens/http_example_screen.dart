import 'package:flutter/material.dart';
import 'package:interceptify/interceptify.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Example screen demonstrating Interceptify with package:http.
///
/// Setup (in main.dart):
/// ```dart
/// Interceptify.initialize();
/// final httpClient = Interceptify.httpClient();
/// ```
class HttpExampleScreen extends StatefulWidget {
  final http.Client httpClient;

  const HttpExampleScreen({required this.httpClient, super.key});

  @override
  State<HttpExampleScreen> createState() => _HttpExampleScreenState();
}

class _HttpExampleScreenState extends State<HttpExampleScreen> {
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  String _status = 'Ready — tap a button to make an HTTP request';
  bool _isLoading = false;
  dynamic _lastResult;

  void _setStatus(String msg, {dynamic result}) {
    setState(() {
      _status = msg;
      if (result != null) _lastResult = result;
    });
  }

  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() => _isLoading = true);
    _setStatus('$label…');
    try {
      await fn();
    } catch (e) {
      _setStatus('✗ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---- API calls using package:http ----------------------------------------

  Future<void> _getPosts() async {
    await _run('GET /posts', () async {
      final uri = Uri.parse('$_baseUrl/posts');
      final response = await widget.httpClient.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body) as List;
      _setStatus('✓ GET /posts — ${data.length} posts (${response.statusCode})', result: data);
    });
  }

  Future<void> _getUsers() async {
    await _run('GET /users', () async {
      final uri = Uri.parse('$_baseUrl/users');
      final response = await widget.httpClient.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body) as List;
      _setStatus('✓ GET /users — ${data.length} users (${response.statusCode})', result: data);
    });
  }

  Future<void> _getSinglePost() async {
    await _run('GET /posts/1', () async {
      final uri = Uri.parse('$_baseUrl/posts/1');
      final response = await widget.httpClient.get(uri);
      final data = jsonDecode(response.body);
      _setStatus('✓ GET /posts/1 (${response.statusCode}) — "${data['title']}"', result: data);
    });
  }

  Future<void> _createPost() async {
    await _run('POST /posts', () async {
      final uri = Uri.parse('$_baseUrl/posts');
      final response = await widget.httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': 'Interceptify HTTP Example',
          'body': 'Testing package:http with Interceptify at ${DateTime.now()}',
          'userId': 1,
        }),
      );
      final data = jsonDecode(response.body);
      _setStatus('✓ POST /posts — created id: ${data['id']} (${response.statusCode})', result: data);
    });
  }

  Future<void> _updatePost() async {
    await _run('PUT /posts/1', () async {
      final uri = Uri.parse('$_baseUrl/posts/1');
      final response = await widget.httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'id': 1,
          'title': 'Updated via package:http + Interceptify',
          'body': 'Updated body',
          'userId': 1,
        }),
      );
      final data = jsonDecode(response.body);
      _setStatus('✓ PUT /posts/1 (${response.statusCode})', result: data);
    });
  }

  Future<void> _deletePost() async {
    await _run('DELETE /posts/1', () async {
      final uri = Uri.parse('$_baseUrl/posts/1');
      final response = await widget.httpClient.delete(uri);
      _setStatus('✓ DELETE /posts/1 — status: ${response.statusCode}');
    });
  }

  Future<void> _triggerError() async {
    await _run('GET (404)', () async {
      final uri = Uri.parse('$_baseUrl/posts/999999');
      final response = await widget.httpClient.get(uri);
      _setStatus('Response: ${response.statusCode} — ${response.body}');
    });
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Package Example'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildSection('GET Requests', [
              _buildButton(
                'GET /posts',
                Icons.list,
                Colors.blue,
                _isLoading ? null : _getPosts,
              ),
              _buildButton(
                'GET /users',
                Icons.people,
                Colors.blue,
                _isLoading ? null : _getUsers,
              ),
              _buildButton(
                'GET /posts/1',
                Icons.article,
                Colors.blue,
                _isLoading ? null : _getSinglePost,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Mutate Requests', [
              _buildButton(
                'POST /posts',
                Icons.add,
                Colors.green,
                _isLoading ? null : _createPost,
              ),
              _buildButton(
                'PUT /posts/1',
                Icons.edit,
                Colors.orange,
                _isLoading ? null : _updatePost,
              ),
              _buildButton(
                'DELETE /posts/1',
                Icons.delete,
                Colors.red,
                _isLoading ? null : _deletePost,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Error Scenarios', [
              _buildButton(
                'GET 404 (not found)',
                Icons.error_outline,
                Colors.red,
                _isLoading ? null : _triggerError,
              ),
            ]),
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isError = _status.startsWith('✗');
    return Card(
      color: isError ? Colors.red.shade50 : Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.http,
                  color: isError ? Colors.red : Colors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'package:http + Interceptify',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isError ? Colors.red.shade800 : Colors.teal.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red.shade700 : Colors.teal.shade700,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...buttons.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: b,
            )),
      ],
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.4),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Response',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                const JsonEncoder.withIndent('  ').convert(_lastResult),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 20,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

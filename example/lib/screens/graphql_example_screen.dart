import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:interceptify/interceptify.dart';

/// Example screen demonstrating Interceptify with graphql_flutter.
///
/// Uses the public "Countries" GraphQL API (https://countries.trevorblades.com).
///
/// Setup in main.dart:
/// ```dart
/// Interceptify.initialize();
///
/// final httpLink = HttpLink('https://countries.trevorblades.com/graphql');
/// final interceptLink = Interceptify.graphqlLink(
///   next: httpLink,
///   endpoint: 'https://countries.trevorblades.com/graphql',
/// );
/// final client = GraphQLClient(link: interceptLink, cache: GraphQLCache());
/// ```
class GraphQLExampleScreen extends StatefulWidget {
  final GraphQLClient client;

  const GraphQLExampleScreen({required this.client, super.key});

  @override
  State<GraphQLExampleScreen> createState() => _GraphQLExampleScreenState();
}

class _GraphQLExampleScreenState extends State<GraphQLExampleScreen> {
  String _status = 'Ready — tap a button to run a GraphQL operation';
  bool _isLoading = false;
  dynamic _lastResult;
  String? _lastError;

  // ---------------------------------------------------------------------------
  // GraphQL documents
  // ---------------------------------------------------------------------------

  static const _queryContinents = r'''
    query GetContinents {
      continents {
        code
        name
      }
    }
  ''';

  static const _queryCountriesByContinent = r'''
    query GetCountries($code: ID!) {
      continent(code: $code) {
        name
        countries {
          code
          name
          capital
          emoji
        }
      }
    }
  ''';

  static const _queryCountryDetail = r'''
    query GetCountry($code: ID!) {
      country(code: $code) {
        name
        native
        capital
        emoji
        currency
        languages {
          name
        }
        continent {
          name
        }
      }
    }
  ''';

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _runQuery(
    String label,
    String document, {
    Map<String, dynamic> variables = const {},
  }) async {
    setState(() {
      _isLoading = true;
      _status = '$label…';
      _lastError = null;
    });

    try {
      final options = QueryOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      );
      final result = await widget.client.query(options);

      if (result.hasException) {
        setState(() {
          _lastError = result.exception.toString();
          _status =
              '✗ Error: ${result.exception?.graphqlErrors.firstOrNull?.message ?? result.exception}';
        });
      } else {
        setState(() {
          _lastResult = result.data;
          _status = '✓ $label — success';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
        _status = '✗ Exception: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GraphQL Example'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildSection('Queries', [
              _buildButton(
                'Query: Get Continents',
                Icons.public,
                Colors.deepPurple,
                _isLoading
                    ? null
                    : () => _runQuery('GetContinents', _queryContinents),
              ),
              _buildButton(
                'Query: Countries in Europe (EU)',
                Icons.map,
                Colors.deepPurple,
                _isLoading
                    ? null
                    : () => _runQuery(
                        'GetCountries (EU)',
                        _queryCountriesByContinent,
                        variables: {'code': 'EU'},
                      ),
              ),
              _buildButton(
                'Query: Countries in Asia (AS)',
                Icons.map_outlined,
                Colors.deepPurple,
                _isLoading
                    ? null
                    : () => _runQuery(
                        'GetCountries (AS)',
                        _queryCountriesByContinent,
                        variables: {'code': 'AS'},
                      ),
              ),
              _buildButton(
                'Query: Country Detail (ID)',
                Icons.info_outline,
                Colors.deepPurple,
                _isLoading
                    ? null
                    : () => _runQuery(
                        'GetCountry (ID)',
                        _queryCountryDetail,
                        variables: {'code': 'ID'},
                      ),
              ),
              _buildButton(
                'Query: Country Detail (US)',
                Icons.flag,
                Colors.deepPurple,
                _isLoading
                    ? null
                    : () => _runQuery(
                        'GetCountry (US)',
                        _queryCountryDetail,
                        variables: {'code': 'US'},
                      ),
              ),
            ]),
            const SizedBox(height: 8),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '💡 All GraphQL operations appear in the Interceptify DevTools panel with method "GRAPHQL". '
                  'In grouped view, use "By HTTP Client" to see them separately from Dio/HTTP requests.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(),
            ],
            if (_lastError != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isError = _status.startsWith('✗');
    return Card(
      color: isError ? Colors.red.shade50 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: isError ? Colors.red : Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'graphql_flutter + Interceptify',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isError
                        ? Colors.red.shade800
                        : Colors.deepPurple.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Endpoint: countries.trevorblades.com/graphql',
              style: TextStyle(
                fontSize: 11,
                color: isError
                    ? Colors.red.shade400
                    : Colors.deepPurple.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: TextStyle(
                fontSize: 13,
                color: isError
                    ? Colors.red.shade700
                    : Colors.deepPurple.shade700,
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
        ...buttons.map(
          (b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
        ),
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
    // Pretty-print maps/lists
    String text;
    try {
      if (_lastResult is Map || _lastResult is List) {
        final entries = <String>[];
        if (_lastResult is Map) {
          (_lastResult as Map).forEach((k, v) {
            entries.add('$k: ${_prettyValue(v)}');
          });
          text = entries.join('\n');
        } else {
          text = (_lastResult as List).take(20).map(_prettyValue).join('\n');
        }
      } else {
        text = _lastResult.toString();
      }
    } catch (_) {
      text = _lastResult.toString();
    }

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
            const Divider(),
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _lastError ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyValue(dynamic v) {
    if (v is Map)
      return '{${v.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
    if (v is List) return '[${v.take(5).join(', ')}${v.length > 5 ? '…' : ''}]';
    return v.toString();
  }
}

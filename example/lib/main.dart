import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:interceptify/interceptify.dart';

import 'screens/home_screen.dart';
import 'screens/http_example_screen.dart';

void main() {
  // 1. Initialize Interceptify (debug mode only — no-op in release)
  Interceptify.initialize();

  // 2. Dio setup
  final dio = Dio();
  dio.interceptors.add(Interceptify.dioInterceptor);
  Interceptify.registerDioInstance(dio);

  // 3. package:http setup — wrap with InterceptifyHttpClient
  final httpClient = Interceptify.httpClient(inner: http.Client());

  runApp(MyApp(dio: dio, httpClient: httpClient));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  final http.Client httpClient;

  const MyApp({required this.dio, required this.httpClient, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interceptify Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _ExampleHome(dio: dio, httpClient: httpClient),
    );
  }
}

class _ExampleHome extends StatelessWidget {
  final Dio dio;
  final http.Client httpClient;

  const _ExampleHome({required this.dio, required this.httpClient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 20),
            SizedBox(width: 8),
            Text(
              'Interceptify Examples',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📡 Interceptify Example App',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose an HTTP client to see its requests in the '
                      'Interceptify DevTools panel.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Dio example ---
            _ExampleCard(
              icon: Icons.http,
              color: Colors.blue,
              title: 'Dio Interceptor',
              subtitle: 'Classic usage with Dio + QueuedInterceptor',
              badge: 'DIO',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen(dio: dio)),
              ),
            ),
            const SizedBox(height: 16),

            // --- http package example ---
            _ExampleCard(
              icon: Icons.lan,
              color: Colors.teal,
              title: 'package:http Client',
              subtitle: 'InterceptifyHttpClient wraps BaseClient',
              badge: 'HTTP',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HttpExampleScreen(httpClient: httpClient),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                '💡 Open Flutter DevTools → Interceptify tab to see all traffic in real-time. '
                'Switch between List and Grouped view, and try "By HTTP Client" grouping to see Dio / HTTP separately.',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).disabledColor),
            ],
          ),
        ),
      ),
    );
  }
}

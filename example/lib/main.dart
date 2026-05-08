import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:interceptify/interceptify.dart';
import 'screens/home_screen.dart';

void main() {
  // Initialize Interceptify (debug mode only)
  Interceptify.initialize();

  // Create Dio instance with Interceptify interceptor
  final dio = Dio();
  dio.interceptors.add(Interceptify.dioInterceptor);

  // Register Dio instance for "Retry" support from DevTools
  Interceptify.registerDioInstance(dio);

  runApp(MyApp(dio: dio));
}

class MyApp extends StatelessWidget {
  final Dio dio;

  const MyApp({required this.dio, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interceptify Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(dio: dio),
    );
  }
}

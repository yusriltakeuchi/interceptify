import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'ui/interceptify_extension_screen.dart';

void main() {
  runApp(const InterceptifyDevToolsApp());
}

class InterceptifyDevToolsApp extends StatelessWidget {
  const InterceptifyDevToolsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interceptify DevTools Extension',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: DevToolsExtension(
        child: const InterceptifyExtensionScreen(),
      ),
    );
  }
}

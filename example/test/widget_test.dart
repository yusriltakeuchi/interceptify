// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:interceptify_example/main.dart';

void main() {
  testWidgets('Example app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final dio = Dio();
    await tester.pumpWidget(MyApp(dio: dio));

    // Verify that the Interceptify Example title is present.
    expect(find.text('Interceptify Example'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/main.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TaskManagerApp(
        home: Scaffold(body: Center(child: Text('Task Manager'))),
      ),
    );

    expect(find.text('Task Manager'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

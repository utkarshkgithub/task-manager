import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/main.dart';
import 'package:task_manager/models/task_item.dart';
import 'package:task_manager/widgets/task_card.dart';

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

  testWidgets('swiping a task card marks it completed', (
    WidgetTester tester,
  ) async {
    var completedValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: TaskItem(
              id: 'task-1',
              title: 'Write tests',
              description: 'Add coverage for task interactions',
              date: DateTime(2026, 5, 12),
              completed: false,
            ),
            onEdit: () {},
            onDelete: () {},
            onToggleCompleted: (value) {
              completedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.fling(find.byType(Dismissible), const Offset(1000, 0), 5000);
    await tester.pumpAndSettle();

    expect(completedValue, isTrue);
  });
}

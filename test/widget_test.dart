import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Text widget renders correctly', (WidgetTester tester) async {
      // بناء ويدجت نص بسيط
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Hello Almashe'),
          ),
        ),
      );

      expect(find.text('Hello Almashe'), findsOneWidget);
    });

    testWidgets('Container with color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.blue,
              child: const Text('Blue Container'),
            ),
          ),
        ),
      );

      expect(find.text('Blue Container'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('ListView test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Interaction Tests', () {
    testWidgets('Tap counter test', (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Counter: $counter'),
                ElevatedButton(
                  onPressed: () => counter++,
                  child: const Text('Increment'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Counter: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      // تحديث الويدجت مع القيمة الجديدة
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Counter: $counter'),
                ElevatedButton(
                  onPressed: () => counter++,
                  child: const Text('Increment'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Counter: 1'), findsOneWidget);
    });
  });
}
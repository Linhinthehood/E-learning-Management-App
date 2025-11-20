import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Common Widget Tests', () {
    testWidgets('ElevatedButton should trigger callback on tap', (
      WidgetTester tester,
    ) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: Key('test_button'),
              onPressed: () {
                buttonPressed = true;
              },
              child: Text('Click Me'),
            ),
          ),
        ),
      );

      // Find and tap the button
      await tester.tap(find.byKey(Key('test_button')));
      await tester.pump();

      // Verify callback was called
      expect(buttonPressed, true);
    });

    testWidgets('TextField should display hint text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                hintText: 'Enter your name',
                labelText: 'Name',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('Card widget should display content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Card Title'),
                    SizedBox(height: 8),
                    Text('Card Description'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Description'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('ListView should display multiple items', (
      WidgetTester tester,
    ) async {
      final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(items[index]));
              },
            ),
          ),
        ),
      );

      // Verify all items are built
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }

      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('CircularProgressIndicator should be visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AlertDialog should display title and content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Alert Title'),
                        content: Text('Alert message'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Alert Title'), findsOneWidget);
      expect(find.text('Alert message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}

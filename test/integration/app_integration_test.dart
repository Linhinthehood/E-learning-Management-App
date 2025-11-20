import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('Complete user flow - navigation test', (
      WidgetTester tester,
    ) async {
      // Build a simple app with navigation
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
          routes: {'/details': (context) => DetailsPage()},
        ),
      );

      // Verify we're on home page
      expect(find.text('Home Page'), findsOneWidget);

      // Tap navigation button
      await tester.tap(find.byKey(Key('navigate_button')));
      await tester.pumpAndSettle();

      // Verify we navigated to details page
      expect(find.text('Details Page'), findsOneWidget);
    });

    testWidgets('Form submission flow', (WidgetTester tester) async {
      String? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormWidget(
              onSubmit: (data) {
                submittedData = data;
              },
            ),
          ),
        ),
      );

      // Enter data in form
      await tester.enterText(find.byKey(Key('name_field')), 'John Doe');
      await tester.enterText(
        find.byKey(Key('email_field')),
        'john@example.com',
      );

      // Submit form
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pump();

      // Verify form was submitted with correct data
      expect(submittedData, isNotNull);
      expect(submittedData, contains('John Doe'));
    });

    testWidgets('List filtering and search', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ListPage()));

      // Initial state - all items visible
      expect(find.byType(ListTile), findsNWidgets(3));

      // Enter search term
      await tester.enterText(find.byKey(Key('search_field')), 'Item 1');
      await tester.pump();

      // Verify filtered results - should only have 1 ListTile now
      expect(find.byType(ListTile), findsOneWidget);
      // Find text within ListTile
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Item 1'),
        ),
        findsOneWidget,
      );
    });
  });
}

// Helper widgets for testing
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Page'),
            ElevatedButton(
              key: Key('navigate_button'),
              onPressed: () => Navigator.pushNamed(context, '/details'),
              child: Text('Go to Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Details Page')));
  }
}

class FormWidget extends StatelessWidget {
  final Function(String) onSubmit;

  const FormWidget({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    return Column(
      children: [
        TextField(
          key: Key('name_field'),
          controller: nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextField(
          key: Key('email_field'),
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        ElevatedButton(
          key: Key('submit_button'),
          onPressed: () {
            onSubmit('${nameController.text}, ${emailController.text}');
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String searchQuery = '';
  final items = ['Item 1', 'Item 2', 'Item 3'];

  @override
  Widget build(BuildContext context) {
    final filteredItems = items
        .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          TextField(
            key: Key('search_field'),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(labelText: 'Search'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(filteredItems[index]));
              },
            ),
          ),
        ],
      ),
    );
  }
}

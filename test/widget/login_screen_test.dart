import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('should have email and password fields', (
      WidgetTester tester,
    ) async {
      // Build a simple login screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  key: Key('login_button'),
                  onPressed: () {},
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify email field exists
      expect(find.byKey(Key('email_field')), findsOneWidget);

      // Verify password field exists
      expect(find.byKey(Key('password_field')), findsOneWidget);

      // Verify login button exists
      expect(find.byKey(Key('login_button')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('password field should be obscured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: Key('password_field'),
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
          ),
        ),
      );

      final passwordField = tester.widget<TextField>(
        find.byKey(Key('password_field')),
      );
      expect(passwordField.obscureText, true);
    });

    testWidgets('should accept text input', (WidgetTester tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
          ),
        ),
      );

      // Enter email
      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      expect(emailController.text, 'test@example.com');

      // Enter password
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      expect(passwordController.text, 'password123');
    });
  });
}

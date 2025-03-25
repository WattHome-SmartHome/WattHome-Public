// filepath: /home/ajaz/Desktop/StudioProjects/WattHome-App/watthome_app/lib/Login/pwReset_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watthome_app/Login/pwReset.dart';
import 'package:watthome_app/Widgets/textField.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forgot Password Tests', () {
    testWidgets('Email validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Forgot()));

      await tester.enterText(find.byType(CustomTextField), 'invalidemail');
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Reset button enabled/disabled state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Forgot()));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);

      await tester.enterText(find.byType(CustomTextField), 'test@example.com');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isTrue);
    });

    testWidgets('Success message for password reset',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Forgot()));

      await tester.enterText(find.byType(CustomTextField), 'test@example.com');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Password reset email sent. Please check your inbox.'),
          findsOneWidget);
    });

    testWidgets('Error message for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Forgot()));

      await tester.enterText(find.byType(CustomTextField), 'invalidemail');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('The email address is not valid.'), findsOneWidget);
    });

    testWidgets('Error message for user not found',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Forgot()));

      await tester.enterText(
          find.byType(CustomTextField), 'notfound@example.com');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
          find.text('No user found with this email address.'), findsOneWidget);
    });
  });
}

// filepath: /home/ajaz/Desktop/StudioProjects/WattHome-App/watthome_app/lib/Login/signUp_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watthome_app/Login/signUp-Role.dart';
import 'package:watthome_app/Login/signUp.dart';
import 'package:watthome_app/Widgets/textField.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Signup Tests', () {
    testWidgets('Name validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Signup()));

      await tester.enterText(find.byType(CustomTextField).first, '');
      await tester.pump();

      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    testWidgets('Email validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Signup()));

      await tester.enterText(find.byType(CustomTextField).last, 'invalidemail');
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Sign Up button enabled/disabled state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Signup()));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);

      await tester.enterText(find.byType(CustomTextField).first, 'Test User');
      await tester.enterText(
          find.byType(CustomTextField).last, 'test@example.com');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isTrue);
    });

    testWidgets('Navigation to SignupRole screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Signup()));

      await tester.enterText(find.byType(CustomTextField).first, 'Test User');
      await tester.enterText(
          find.byType(CustomTextField).last, 'test@example.com');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SignupRole), findsOneWidget);
    });
  });
}

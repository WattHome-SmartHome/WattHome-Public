// filepath: /home/ajaz/Desktop/StudioProjects/WattHome-App/watthome_app/lib/Login/signIn_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watthome_app/Login/signIn.dart';
import 'package:watthome_app/Login/signUp.dart';
import 'package:watthome_app/Login/pwReset.dart';
import 'package:watthome_app/Widgets/textField.dart';
import 'package:watthome_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Tests', () {
    testWidgets('Forgot Password navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        navigatorKey: navigatorKey,
      ));

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(Forgot), findsOneWidget);
    });

    testWidgets('Sign Up navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        navigatorKey: navigatorKey,
      ));

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(Signup), findsOneWidget);
    });

    testWidgets('Email validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(
          find.byType(CustomTextField).first, 'invalidemail');
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('Password validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(find.byType(CustomTextField).last, '');
      await tester.pump();

      expect(find.text('Password cannot be empty'), findsOneWidget);
    });

    testWidgets('Sign In button enabled/disabled state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);

      await tester.enterText(
          find.byType(CustomTextField).first, 'test@example.com');
      await tester.enterText(find.byType(CustomTextField).last, 'password');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isTrue);
    });
  });
}

// filepath: /home/ajaz/Desktop/StudioProjects/WattHome-App/watthome_app/lib/Login/OTPVerificationScreen_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watthome_app/Dweller/Screens/OnBoarding/joinHome.dart';
import 'package:watthome_app/Login/OTPVerificationScreen.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:watthome_app/Widgets/navbar-dweller.dart';
import 'package:watthome_app/Widgets/textField.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTPVerificationScreen Tests', () {
    testWidgets('OTP field validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OTPVerificationScreen()));

      await tester.enterText(find.byType(CustomTextField), '123456');
      await tester.pump();

      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('Navigation based on user role and home existence',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OTPVerificationScreen()));

      // Mock FirebaseAuth and Firestore
      final User user = FirebaseAuth.instance.currentUser!;
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;
      final String userRole = userDoc['role'];
      final bool homeExists = userData.containsKey('homeId') &&
          (await FirebaseFirestore.instance
                  .collection('homes')
                  .doc(userData['homeId'])
                  .get())
              .exists;

      await tester.enterText(find.byType(CustomTextField), '123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      if (userRole == 'Admin') {
        expect(find.byType(NavbarAdmin), findsOneWidget);
      } else if (userRole == 'User') {
        if (homeExists) {
          expect(find.byType(NavbarDweller), findsOneWidget);
        } else {
          expect(find.byType(JoinHome), findsOneWidget);
        }
      }
    });

    testWidgets('Error message for invalid OTP', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OTPVerificationScreen()));

      await tester.enterText(find.byType(CustomTextField), 'invalid');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('OTP has expired or is invalid. Please try again.'),
          findsOneWidget);
    });
  });
}

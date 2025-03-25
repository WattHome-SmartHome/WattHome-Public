// filepath: /home/ajaz/Desktop/StudioProjects/WattHome-App/watthome_app/lib/Tests/navtest1.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_html/js.dart';
import 'package:watthome_app/Dweller/Screens/Profile/accountMain.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/main.dart';
import 'package:watthome_app/Login/onBoarding.dart';
import 'package:watthome_app/Login/signIn.dart';
import 'package:watthome_app/Widgets/navbar-dweller.dart';
import 'package:watthome_app/Login/signUp.dart';
import 'package:watthome_app/Login/pwReset.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:watthome_app/Dweller/Screens/OnBoarding/joinHome.dart';
import 'package:watthome_app/Login/OTPVerificationScreen.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/EnergyReport/energyReport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(Firebase.apps.isNotEmpty, true);
  });

  testWidgets('App has correct initial route', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(OnBoarding), findsOneWidget);
  });

  testWidgets('App routes are defined correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final Map<String, WidgetBuilder> routes = {
      '/onBoarding': (context) => const OnBoarding(),
      '/login': (context) => const LoginScreen(),
      '/NavHome': (context) => const NavbarDweller(),
      '/signUp': (context) => const Signup(),
      '/forgotPassword': (context) => const Forgot(),
      '/Settings': (context) => SettingsScreen(),
      '/NavDweller': (context) => const NavbarDweller(),
      '/NavAdmin': (context) => const NavbarAdmin(),
      '/JoinHome': (context) => const JoinHome(),
      '/loginOTPverify': (context) => const OTPVerificationScreen(),
      '/energyReport': (context) => const EnergyReport(),
    };

    routes.forEach((route, builder) async {
      await tester.pumpWidget(Builder(builder: builder));
      expect(find.byType(builder(context as BuildContext).runtimeType), findsOneWidget);
    });
  });

  testWidgets('System UI overlay style is set correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    final SystemUiOverlayStyle style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor, CustomColors.backgroundColor);
    expect(style.statusBarColor, const Color.fromARGB(255, 27, 27, 27));
    expect(style.statusBarIconBrightness, Brightness.light);
  });
}

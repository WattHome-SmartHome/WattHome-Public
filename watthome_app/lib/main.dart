import 'package:flutter/material.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/EnergyReport/energyReport.dart';
import 'package:watthome_app/Dweller/Screens/OnBoarding/joinHome.dart';
import 'package:watthome_app/Login/adminCreateHome.dart';
import 'package:watthome_app/Login/onBoarding.dart';
import 'package:watthome_app/Login/pwReset.dart';
import 'package:watthome_app/Login/signIn.dart';
import 'package:watthome_app/Login/signUp.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:watthome_app/Widgets/navbar-dweller.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:watthome_app/Dweller/Screens/Profile/accountMain.dart';
import 'package:get/get.dart';
import 'package:watthome_app/Widgets/customPageTransitionBuilder.dart';
import 'package:watthome_app/Login/OTPVerificationScreen.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  Get.testMode = true;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey:
            '', // Replace with your actual API Key
        appId:
            '', // Replace with your actual App ID
        messagingSenderId:
            '', // Replace with your actual Messaging Sender ID
        projectId: '', // Replace with your actual Project ID
        storageBucket:
            '', // Replace with your actual Storage Bucket
      ),
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }
}

void setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor:
        CustomColors.backgroundColor, // Set the navigation bar color
    statusBarColor: Color.fromARGB(
        255, 27, 27, 27), // Set the status bar color to dark grey
    statusBarIconBrightness:
        Brightness.light, // Set the status bar text color to white
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    setSystemUIOverlayStyle(); // Set the system UI overlay style

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WattHome App',
      theme: ThemeData(
        scaffoldBackgroundColor: CustomColors.backgroundColor,
        fontFamily: 'Google',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
            TargetPlatform.fuchsia:
                CustomPageTransitionBuilder(), // Add this line for web support
          },
        ),
      ),
      themeMode: ThemeMode.system, // Use system theme mode
      navigatorKey: navigatorKey, // Set the navigator key
      initialRoute: '/onBoarding',
      routes: {
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
        '/AdminCreateHome': (context) => const AdminCreateHome(),
      },
      builder: (context, child) {
        if (kIsWeb) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}

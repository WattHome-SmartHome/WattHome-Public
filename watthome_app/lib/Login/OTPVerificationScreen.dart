import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/main.dart';
import 'package:watthome_app/Widgets/textField.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  _OTPVerificationScreen createState() => _OTPVerificationScreen();
}

class _OTPVerificationScreen extends State<OTPVerificationScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: CustomColors.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              // Expanded to push content upwards
              child: Column(
                children: [
                  Image(
                    image: AssetImage('assets/Images/otp.png'),
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'Enter the OTP on your App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: otpController,
                    hintText: 'Enter OTP',
                    isPasswordField: false,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final User? user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  print('User not logged in');
                  return;
                }

                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                Map<String, dynamic> userData =
                    userDoc.data() as Map<String, dynamic>;
                String userRole = userDoc['role'];

                bool homeExists = false;
                String? homeId =
                    userData.containsKey('homeId') ? userData['homeId'] : null;
                if (homeId != null) {
                  DocumentSnapshot homeDoc = await FirebaseFirestore.instance
                      .collection('homes')
                      .doc(homeId)
                      .get();
                  homeExists = homeDoc.exists;
                }

                String genrateotp = OTP.generateTOTPCodeString(
                    userData['secret'], DateTime.now().millisecondsSinceEpoch,
                    interval: 30,
                    length: 6,
                    algorithm: Algorithm.SHA1,
                    isGoogle: true);

                if (genrateotp == otpController.text.trim()) {
                  if (navigatorKey.currentState != null) {
                    if (userRole == 'Admin') {
                      navigatorKey.currentState!
                          .pushReplacementNamed('/NavAdmin');
                    } else if (userRole == 'User') {
                      if (homeExists) {
                        navigatorKey.currentState!
                            .pushReplacementNamed('/NavDweller');
                      } else {
                        navigatorKey.currentState!
                            .pushReplacementNamed('/JoinHome');
                      }
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'OTP has expired or is invalid. Please try again.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: CustomColors.primaryColor,
                foregroundColor: CustomColors.backgroundColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

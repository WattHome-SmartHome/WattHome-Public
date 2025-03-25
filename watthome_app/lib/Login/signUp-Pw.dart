import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watthome_app/Dweller/Screens/OnBoarding/joinHome.dart';
import 'package:watthome_app/Login/adminCreateHome.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/textField.dart';
import 'package:watthome_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/ipaddress.dart';

class SignupPw extends StatefulWidget {
  final String name;
  final String email;
  final String role;

  const SignupPw(
      {required this.name, required this.email, required this.role, super.key});

  @override
  State<SignupPw> createState() => _SignupPwState();
}

class _SignupPwState extends State<SignupPw> {
  // Controllers
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    password.addListener(_updateButtonState);
    confirmPassword.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    password.removeListener(_updateButtonState);
    confirmPassword.removeListener(_updateButtonState);
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  // Signup function with Firebase Authentication
  signup() async {
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match."),
          backgroundColor: CustomColors.errorColor,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: password.text,
      );

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "name": widget.name,
        "role": widget.role,
        "2faEnabled": false,
      });

      // Show loading screen before making the HTTP request
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoadingScreen()),
      );

      // Make the HTTP request
      Uri uri = Uri.parse("http://${ip_address}/updatesql");
      await http.get(uri);

      // Navigate to adminCreateHome page
      if (widget.role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminCreateHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JoinHome()),
        );
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: CustomColors.successColor,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = "The password is too weak. Please use a stronger password.";
      } else if (e.code == 'email-already-in-use') {
        message =
            "The email is already registered. Please log in or use a different email.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      } else {
        message = "Something went wrong. Please try again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: CustomColors.errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: CustomColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    setSystemUIOverlayStyle();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 25),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: CustomColors.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Create Your Password",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Please create a strong password to secure your account.",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 30),
                          CustomTextField(
                            controller: password,
                            hintText: 'Password',
                            isPasswordField: true,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: confirmPassword,
                            hintText: 'Confirm Password',
                            isPasswordField: true,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: password.text.isNotEmpty &&
                                  confirmPassword.text.isNotEmpty
                              ? CustomColors.primaryColor
                              : CustomColors.textboxColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: password.text.isNotEmpty &&
                                confirmPassword.text.isNotEmpty
                            ? signup
                            : null,
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Loading Screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: CustomColors.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              "Setting up your account...",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

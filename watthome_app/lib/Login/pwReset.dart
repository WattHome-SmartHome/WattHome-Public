import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:watthome_app/main.dart';

import '../Models/customColors.dart';
import '../Widgets/textField.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController email = TextEditingController();
  bool isEmailValid = false;

  @override
  void initState() {
    super.initState();
    email.addListener(validateEmail);
  }

  void validateEmail() {
    setState(() {
      isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.text);
    });
  }

  // Function to send reset email
  reset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);

      // Show success message
      const snackBar = SnackBar(
        content: AwesomeSnackbarContent(
          title: 'Success',
          message: 'Password reset email sent. Please check your inbox.',
          contentType: ContentType.success,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = "No user found with this email address.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      } else {
        message = "An unexpected error occurred: ${e.message}";
      }
      final snackBar = SnackBar(
        content: AwesomeSnackbarContent(
          title: 'Error',
          message: message,
          contentType: ContentType.failure,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      final snackBar = SnackBar(
        content: AwesomeSnackbarContent(
          title: 'Error',
          message: 'An error occurred: $e',
          contentType: ContentType.failure,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: CustomColors.iconColor,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo/Title
              const Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: 100,
                      width: 200,
                      child: Image(
                        image: AssetImage('assets/Images/Logo&Name.png'),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "RECOVER PASSWORD",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.textColor,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Forgot your password? Don’t worry, enter your email to reset your current password.",
                          style: TextStyle(
                            fontSize: 12,
                            color: CustomColors.textAccentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Email Input
              CustomTextField(
                controller: email,
                hintText: 'Email',
                isEmailField: true,
                isValid: isEmailValid,
              ),

              if (!isEmailValid && email.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Please enter a valid email address",
                    style:
                        TextStyle(color: CustomColors.errorColor, fontSize: 10),
                  ),
                ),

              const Spacer(),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isEmailValid ? reset : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmailValid
                        ? CustomColors.primaryColor
                        : CustomColors.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 16,
                      color: isEmailValid
                          ? CustomColors.textboxColor
                          : CustomColors.textAccentColor,
                    ),
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  // Navigate to Sign Up screen
                  if (navigatorKey.currentState != null) {
                    navigatorKey.currentState!.pushNamed('/signUp');
                  }
                },
                child: const Text.rich(
                  selectionColor: CustomColors.primaryColor,
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(
                      color: CustomColors.textAccentColor,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(
                            color: CustomColors.primaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

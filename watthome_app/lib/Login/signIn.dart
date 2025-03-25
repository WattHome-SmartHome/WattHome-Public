import 'package:flutter/material.dart';
import 'package:watthome_app/main.dart'; // Import the main.dart to access the navigator key
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:watthome_app/Widgets/textField.dart';

import '../Models/customColors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final _formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    email.addListener(validateEmail);
    password.addListener(validatePassword);
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
  }

  void validateEmail() {
    setState(() {
      isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.text);
    });
  }

  void validatePassword() {
    setState(() {
      isPasswordValid = password.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      // Fetch user role and home ID from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String userRole = userDoc['role'];
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? homeId =
          userData.containsKey('homeId') ? userData['homeId'] : null;

      // Check if home ID exists in the home collection
      bool homeExists = false;
      if (homeId != null) {
        DocumentSnapshot homeDoc = await FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .get();
        homeExists = homeDoc.exists;
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'Welcome!',
            message: 'Login successful!',
            contentType: ContentType.success,
          ),
        ),
      );

      if (userDoc['2faEnabled'] == true) {
        navigatorKey.currentState!.pushReplacementNamed('/loginOTPverify');
      } else {
        // Navigate based on role and home existence
        if (navigatorKey.currentState != null) {
          if (userRole == 'Admin') {
            if (homeExists) {
              navigatorKey.currentState!.pushReplacementNamed('/NavAdmin');
            } else {
              navigatorKey.currentState!
                  .pushReplacementNamed('/AdminCreateHome');
            }
          } else if (userRole == 'User') {
            if (homeExists) {
              navigatorKey.currentState!.pushReplacementNamed('/NavDweller');
            } else {
              navigatorKey.currentState!.pushReplacementNamed('/JoinHome');
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth errors
      String message;
      if (e.code == 'user-not-found') {
        message = "No user found with this email. Please sign up.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      } else {
        message = "An unexpected error occurred: ${e.message}";
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'Oh Snap!',
            message: message,
            contentType: ContentType.failure,
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: CustomColors.backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width =
                constraints.maxWidth > 600 ? 400 : constraints.maxWidth * 0.9;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width,
                ),
                child: Column(
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        height: 100,
                        width: 200,
                        child: Image(
                          image: AssetImage('assets/Images/Logo&Name.png'),
                        ),
                      ),
                    ),
                    const Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('SIGN IN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Welcome back! Please login to your account.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: email,
                            hintText: 'Email',
                            isEmailField: true,
                            isValid: isEmailValid || email.text.isEmpty,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: password,
                            hintText: 'Password',
                            isPasswordField: true,
                            isValid: isPasswordValid || password.text.isEmpty,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                isEmailValid && isPasswordValid && !isLoading
                                    ? () {
                                        if (_formKey.currentState!.validate()) {
                                          signIn();
                                        }
                                      }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: isEmailValid && isPasswordValid
                                  ? CustomColors.primaryColor
                                  : CustomColors.errorColor,
                              foregroundColor: CustomColors.backgroundColor,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        CustomColors.primaryColor),
                                  )
                                : Text(
                                    "Log In",
                                    style: TextStyle(
                                        color: isEmailValid && isPasswordValid
                                            ? CustomColors.backgroundColor
                                            : CustomColors.textAccentColor),
                                  ),
                          ),
                          // single line divider and text "or"
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                          //   child: Row(
                          //     children: [
                          //       Expanded(
                          //         child: Container(
                          //           height: 1,
                          //           color: Theme.of(context)
                          //               .textTheme
                          //               .bodyLarge!
                          //               .color!
                          //               .withOpacity(0.24),
                          //         ),
                          //       ),
                          //       const SizedBox(width: 16.0),
                          //       Text(
                          //         'or log in with',
                          //         style: Theme.of(context)
                          //             .textTheme
                          //             .bodyMedium!
                          //             .copyWith(
                          //               color: Theme.of(context)
                          //                   .textTheme
                          //                   .bodyLarge!
                          //                   .color!
                          //                   .withOpacity(0.64),
                          //             ),
                          //       ),
                          //       const SizedBox(width: 16.0),
                          //       Expanded(
                          //         child: Container(
                          //           height: 1,
                          //           color: Theme.of(context)
                          //               .textTheme
                          //               .bodyLarge!
                          //               .color!
                          //               .withOpacity(0.24),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // // social login buttons
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: OutlinedButton(
                          //         onPressed: () {},
                          //         style: OutlinedButton.styleFrom(
                          //           side: BorderSide(
                          //             color: Theme.of(context)
                          //                 .textTheme
                          //                 .bodyLarge!
                          //                 .color!
                          //                 .withOpacity(0.24),
                          //           ),
                          //           minimumSize:
                          //               const Size(double.infinity, 48),
                          //           shape: const StadiumBorder(),
                          //         ),
                          //         child: Row(
                          //           mainAxisAlignment: MainAxisAlignment.center,
                          //           children: [
                          //             Image.asset(
                          //               'assets/Images/googlelogo.png',
                          //               height: 20,
                          //             ),
                          //             const SizedBox(width: 8.0),
                          //             Text(
                          //               'Google',
                          //               style: Theme.of(context)
                          //                   .textTheme
                          //                   .bodyMedium!
                          //                   .copyWith(
                          //                     color: Theme.of(context)
                          //                         .textTheme
                          //                         .bodyLarge!
                          //                         .color!
                          //                         .withOpacity(0.64),
                          //                   ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    //const Spacer(),
                    // Forgot Password and Sign Up at the bottom
                    Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Navigate to Forgot Password screen
                            if (navigatorKey.currentState != null) {
                              navigatorKey.currentState!
                                  .pushNamed('/forgotPassword');
                            }
                          },
                          child: const Text('Forgot Password?'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to Sign Up screen
                            if (navigatorKey.currentState != null) {
                              navigatorKey.currentState!.pushNamed('/signUp');
                            }
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "Don’t have an account? ",
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: CustomColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:watthome_app/Login/signUp-Role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/textField.dart';
import 'package:watthome_app/main.dart';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controllers
  TextEditingController email = TextEditingController();
  TextEditingController name = TextEditingController();
  bool isNameValid = false;
  bool isEmailValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    name.addListener(validateName);
    email.addListener(validateEmail);
  }

  void validateName() {
    setState(() {
      isNameValid = name.text.isNotEmpty;
    });
  }

  void validateEmail() {
    setState(() {
      isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.text);
    });
  }

  Future<void> checkEmailInUse() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Check if email exists in Firestore
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.text)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      if (documents.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: AwesomeSnackbarContent(
              title: 'Oh Snap!',
              message: 'The email address is already in use.',
              contentType: ContentType.failure,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignupRole(
              name: name.text,
              email: email.text,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'An error occurred while checking the email: $e',
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
    setSystemUIOverlayStyle(); // Set the system UI overlay style

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 25, // Increased size
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: CustomColors.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
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
                              // Logo
                              Center(
                                child: Image.asset(
                                  'assets/Images/Logo.png',
                                  height: 100,
                                  width: 100,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Instruction Text
                              const Text(
                                "To get started, add your name and email!",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: CustomColors.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Name Field
                              CustomTextField(
                                controller: name,
                                hintText: 'Name',
                                isValid: isNameValid || name.text.isEmpty,
                              ),
                              const SizedBox(height: 20),
                              // Email Field
                              CustomTextField(
                                controller: email,
                                hintText: 'Email',
                                isEmailField: true,
                                isValid: isEmailValid || email.text.isEmpty,
                              ),
                              if (!isEmailValid && email.text.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Please enter a valid email address",
                                    style: TextStyle(
                                        color: CustomColors.errorColor,
                                        fontSize: 10),
                                  ),
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
                              backgroundColor: isEmailValid && isNameValid
                                  ? CustomColors.primaryColor
                                  : CustomColors.textAccentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isEmailValid && isNameValid && !isLoading
                                ? () {
                                    checkEmailInUse();
                                  }
                                : null,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : const Text(
                                    "Next",
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
            );
          },
        ),
      ),
    );
  }
}

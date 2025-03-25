// Edit page for Trisha

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/main.dart'; // Import the main.dart to access the navigator key
import 'package:watthome_app/Widgets/textField.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isCurrentPasswordValid = false;
  bool isNewPasswordValid = false;
  bool isConfirmPasswordValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentPasswordController.addListener(validateCurrentPassword);
    newPasswordController.addListener(validateNewPassword);
    confirmPasswordController.addListener(validateConfirmPassword);
  }

  void validateCurrentPassword() {
    setState(() {
      isCurrentPasswordValid = currentPasswordController.text.length >= 8;
    });
  }

  void validateNewPassword() {
    setState(() {
      isNewPasswordValid = newPasswordController.text.length >= 8;
    });
  }

  void validateConfirmPassword() {
    setState(() {
      isConfirmPasswordValid = confirmPasswordController.text.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: CustomColors.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: currentPasswordController,
              hintText: 'Current password',
              isPasswordField: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: newPasswordController,
              hintText: 'New password',
              isPasswordField: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: confirmPasswordController,
              hintText: 'Re-enter your new password',
              isPasswordField: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isCurrentPasswordValid &&
                      isNewPasswordValid &&
                      isConfirmPasswordValid &&
                      !isLoading
                  ? () {
                      if (newPasswordController.text ==
                          confirmPasswordController.text) {
                        setState(() {
                          isLoading = true;
                        });
                        changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                          confirmPasswordController.text,
                        ).then((_) {
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.pop(context);
                          navigatorKey.currentState
                              ?.pushReplacementNamed('/login');
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            content: AwesomeSnackbarContent(
                              title: 'Error',
                              message: 'New passwords do not match!',
                              contentType: ContentType.failure,
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isCurrentPasswordValid &&
                        isNewPasswordValid &&
                        isConfirmPasswordValid
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
                      "Submit",
                      style: TextStyle(
                          color: isCurrentPasswordValid &&
                                  isNewPasswordValid &&
                                  isConfirmPasswordValid
                              ? CustomColors.backgroundColor
                              : CustomColors.textAccentColor),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-authenticate the user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Update the password
        await user.updatePassword(newPassword);
        await user.reload();
        print('Password updated successfully');
      } else {
        print('No user is currently signed in');
      }
    } catch (e) {
      print('Failed to update password: $e');
    }
  }
}

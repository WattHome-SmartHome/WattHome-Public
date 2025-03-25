import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:watthome_app/Login/signUp-Pw.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/main.dart';

class SignupRole extends StatefulWidget {
  final String name;
  final String email;

  const SignupRole({required this.name, required this.email, Key? key})
      : super(key: key);

  @override
  State<SignupRole> createState() => _SignupRoleState();
}

class _SignupRoleState extends State<SignupRole> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    setSystemUIOverlayStyle(); // Set the system UI overlay style

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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Are You a Home Owner or Home Dweller?",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Based on your selection, it will restrict the amount of access to your smart home. Beware, you may not be able to change your selection later!",
                            //textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedRole == 'User'
                                    ? CustomColors.primaryColor
                                    : CustomColors.textboxColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedRole = 'User';
                                });
                              },
                              child: const Text(
                                "Home Dweller",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedRole == 'Admin'
                                    ? CustomColors.primaryColor
                                    : CustomColors.textboxColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedRole = 'Admin';
                                });
                              },
                              child: const Text(
                                "Home Owner",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/Images/Cool Kids Fresh Air.png',
                            height: 300,
                            width: 300,
                          ),
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
                          backgroundColor: selectedRole != null
                              ? CustomColors.primaryColor
                              : CustomColors.textboxColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: selectedRole != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupPw(
                                      name: widget.name,
                                      email: widget.email,
                                      role: selectedRole!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: const Text(
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
        ),
      ),
    );
  }
}

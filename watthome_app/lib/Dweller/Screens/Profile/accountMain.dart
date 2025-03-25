import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/textField.dart';
import 'package:watthome_app/main.dart';
import 'accountMain-pw.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController inputController = TextEditingController();
  final TextEditingController inputController2 = TextEditingController();
  final TextEditingController inputController3 = TextEditingController();
  Color appBarColor = CustomColors.primaryAccentColor; // Default color
  Color waveClipperColor = CustomColors.primaryAccentColor; // Default color

  @override
  void initState() {
    super.initState();
    checkUserRole(); // Check user role when initializing the state
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = getUserEmail();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          'Your Account',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Brown curve background
            Hero(
              tag: 'background-curve',
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: waveClipperColor,
                  ),
                ),
              ),
            ),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth > 600
                      ? 400
                      : constraints.maxWidth * 0.95;
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // const SizedBox(
                        //     height: 50), // Adjust the height as needed
                        Stack(
                          children: [
                            const Hero(
                              tag: 'profile-picture',
                              child: CircleAvatar(
                                radius: 80,
                                backgroundImage: AssetImage(
                                    'assets/Images/DefaultProfile.png'),
                              ),
                            ),
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: GestureDetector(
                            //     onTap: () {
                            //       print('Edit profile picture');
                            //     },
                            //     child: const CircleAvatar(
                            //       radius: 20,
                            //       backgroundColor:
                            //           Color.fromRGBO(185, 121, 75, 1),
                            //       child: Icon(Icons.edit,
                            //           size: 20, color: Colors.white),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<String>(
                          future: getUserName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                "Loading...",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              );
                            } else {
                              return Text(
                                snapshot.data ?? "No name found",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userEmail,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        _buildProfileOption(
                            context, Icons.person, 'Change Name', onTap: () {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.infoReverse,
                            animType: AnimType.bottomSlide,
                            dialogBorderRadius:
                                BorderRadius.all(Radius.circular(15)),
                            body: Column(
                              children: [
                                CustomTextField(
                                    controller: inputController,
                                    hintText: 'Enter Name'),
                              ],
                            ),
                            btnCancelOnPress: () {},
                            btnCancelColor: CustomColors.errorColor,
                            btnOkOnPress: () {
                              if (inputController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Name cannot be empty')),
                                );
                                return;
                              }
                              updateName(inputController.text);
                              Navigator.pop(context);
                            },
                            btnOkColor: CustomColors.successColor,
                          ).show();
                        }),
                        // _buildProfileOption(
                        //     context, Icons.flag, 'Change profile Pic'),
                        // _buildProfileOption(
                        //     context, Icons.email_rounded, 'Change Email',
                        //     onTap: () {
                        //   AwesomeDialog(
                        //     context: context,
                        //     dialogType: DialogType.infoReverse,
                        //     animType: AnimType.bottomSlide,
                        //     dialogBorderRadius:
                        //         BorderRadius.all(Radius.circular(15)),
                        //     body: Column(
                        //       children: [
                        //         CustomTextField(
                        //             controller: inputController,
                        //             hintText: 'New Email'),
                        //       ],
                        //     ),
                        //     btnCancelOnPress: () {},
                        //     btnCancelColor: CustomColors.errorColor,
                        //     btnOkOnPress: () {
                        //       if (inputController.text.isEmpty) {
                        //         ScaffoldMessenger.of(context).showSnackBar(
                        //           const SnackBar(
                        //               content: Text('Email cannot be empty')),
                        //         );
                        //         return;
                        //       }
                        //       changeEmail(inputController.text);
                        //       Navigator.pop(context);
                        //       Navigator.pop(context); // Pop the current page
                        //       // Navigator.push(
                        //       //     context,
                        //       //     MaterialPageRoute(
                        //       //         builder: (context) => SettingsScreen()));
                        //     },
                        //     btnOkColor: CustomColors.successColor,
                        //   ).show();
                        // }),
                        _buildProfileOption(
                            context, Icons.password_rounded, 'Change password',
                            onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen()),
                          );
                        }),
                        _buildProfileOption(
                          context,
                          Icons.security,
                          'Enable/Disable 2FA',
                          onTap: () => enableDisable2FA(context),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                          child: Divider(),
                        ),
                        _buildProfileOption(
                          context,
                          Icons.delete_forever,
                          'Delete Account',
                          onTap: () {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              animType: AnimType.bottomSlide,
                              dialogBorderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              title: 'Delete Account',
                              desc:
                                  'Are you sure you want to delete your account? Your home & all your data will also go with you! This action cannot be undone!',
                              btnCancelOnPress: () {},
                              btnCancelColor: CustomColors.successColor,
                              btnOkOnPress: () async {
                                await deleteUserAccount();
                                navigatorKey.currentState!
                                    .pushReplacementNamed('/login');
                              },
                              btnOkColor: CustomColors.errorColor,
                            ).show();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getUserEmail() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return '${user.email}';
    }
    return "email not found";
  }

  Future<DocumentSnapshot> fetchUserDocument() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc('nonexistent')
          .get();
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<String> getUserName() async {
    DocumentSnapshot userDoc = await fetchUserDocument();
    if (userDoc.exists == true) {
      final data = userDoc.data() as Map<String, dynamic>;
      return data['name'] ?? "No name found";
    } else {
      return "user not found";
    }
  }

  Future<void> updateName(newName) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not found');
      return;
    }

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await docRef.update({
        'name': newName,
      });

      print('Document successfully updated!');
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<void> changePassword(
      currentPassword, password, confirmPassword) async {
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
        await user.updatePassword(password);
        await user.reload();
        print('Password updated successfully');
      } else {
        print('No user is currently signed in');
      }
    } catch (e) {
      print('Failed to update password: $e');
    }
  }

  Future<void> changeEmail(email) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update the password
      await user.verifyBeforeUpdateEmail(email);
    }
  }

  Future<void> enableDisable2FA(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      DocumentSnapshot snapshot = await docRef.get();
      final data = snapshot.data() as Map<String, dynamic>?;
      bool is2FAEnabled = data?['2faEnabled'] ?? false;

      if (is2FAEnabled == true) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          headerAnimationLoop: false,
          animType: AnimType.bottomSlide,
          title: 'You are going to disable 2FA',
          desc: 'To re-enable you will have to re-add the auth to your app',
          btnCancelOnPress: () {},
          btnOkOnPress: () async {
            await docRef.update({'2faEnabled': false});
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('2FA has been disabled.')));
          },
        ).show();
      } else if (is2FAEnabled == false) {
        final String secret = OTP.randomSecret();

        final String otpauthUrl = _generateOtpAuthUrl(
          secret: secret,
          accountName: user.email!,
          issuer: 'watthome',
        );

        AwesomeDialog(
                context: context,
                dialogType: DialogType.info,
                dialogBorderRadius: BorderRadius.circular(15),
                animType: AnimType.bottomSlide,
                body: Column(
                  children: [
                    const Text(
                      'Scan the QR code below with your authenticator app:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: QrImageView(
                          data: otpauthUrl,
                          version: QrVersions.auto,
                          size: 150,
                          gapless: false,
                        ),
                      ),
                    ),
                  ],
                ),
                btnOkOnPress: () {
                  _confirmOTP(context, secret);
                },
                btnOkColor: CustomColors.primaryColor)
            .show();
      }
    } catch (e) {
      print('Error toggling 2FA: $e');
    }
  }

  String _generateOtpAuthUrl({
    required String secret,
    required String accountName,
    required String issuer,
  }) {
    final Uri uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$issuer:$accountName',
      queryParameters: {
        'secret': secret,
        'issuer': issuer,
        'algorithm': 'SHA1',
        'digits': '6',
        'period': '30',
      },
    );
    return uri.toString();
  }

  void _confirmOTP(BuildContext context, String secret) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    final TextEditingController otpController = TextEditingController();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.bottomSlide,
      // title: 'Enter OTP',
      dialogBorderRadius: BorderRadius.all(Radius.circular(15)),
      body: Column(
        children: [
          CustomTextField(
              controller: otpController, hintText: 'Enter OTP', maxLength: 6),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelColor: CustomColors.errorColor,
      btnOkOnPress: () {
        String enteredOtp = otpController.text.trim();
        String correctOTP = OTP.generateTOTPCodeString(
            secret, DateTime.now().millisecondsSinceEpoch,
            interval: 30, length: 6, algorithm: Algorithm.SHA1, isGoogle: true);

        if (correctOTP == enteredOtp.toString()) {
          DocumentReference docRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          try {
            docRef.update({'secret': secret, '2faEnabled': true});
            print('Document successfully updated!');
          } catch (e) {
            print('Error updating document: $e');
          }

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP Confirmed: $enteredOtp')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('OTP has expired or is invalid. Please try again.')),
          );

          OTP.generateTOTPCodeString(
              secret, DateTime.now().millisecondsSinceEpoch,
              interval: 30,
              length: 6,
              algorithm: Algorithm.SHA1,
              isGoogle: true);
        }
      },
      btnOkColor: CustomColors.successColor,
    ).show();
  }

  Future<void> checkUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'user';
        if (role == 'Admin') {
          setState(() {
            appBarColor = CustomColors.secondaryAccentColor;
            waveClipperColor = CustomColors.secondaryAccentColor;
          });
          print(true);
        } else {
          print(false);
        }
      } else {
        print('User document does not exist');
      }
    } else {
      print('No user is currently signed in');
    }
  }

  Future<void> deleteUserAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'user';
        final String homeId = data['homeId'];
        if (role == 'Admin') {
          // Delete the home the admin is tied to
          await FirebaseFirestore.instance
              .collection('homes')
              .doc(homeId)
              .delete();
        } else {
          // Remove the user from the home's members collection
          QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
              .collection('homes')
              .doc(homeId)
              .collection('members')
              .where('email', isEqualTo: user.email)
              .get();

          for (QueryDocumentSnapshot memberDoc in membersSnapshot.docs) {
            await memberDoc.reference.delete();
          }
        }
        await userDocRef.delete();
        await user.delete();
        print('User account and associated data deleted successfully');
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error deleting user account: $e');
    }
  }
}

Widget _buildProfileOption(BuildContext context, IconData icon, String title,
    {VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      tileColor: const Color.fromARGB(255, 223, 223, 223),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  );
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

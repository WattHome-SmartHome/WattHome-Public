import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watthome_app/Dweller/Screens/Profile/accountMain.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userEmail = getUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: CustomColors.secondaryAccentColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Hero(
              tag: 'background-curve',
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: CustomColors.secondaryAccentColor,
                  ),
                ),
              ),
            ),
            Hero(
              tag: 'background-curve-light',
              child: ClipPath(
                clipper: WaveClipperLight(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: CustomColors.secondaryAccentColor.withOpacity(0.5),
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
                      children: [
                        const SizedBox(height: 70),
                        const Stack(
                          children: [
                            Hero(
                              tag: 'profile-picture',
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(
                                    'assets/Images/DefaultProfile.png'),
                              ),
                            ),
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
                          style: const TextStyle(
                              fontSize: 16,
                              color: CustomColors.textAccentColor),
                        ),
                        const SizedBox(height: 32),
                        _buildProfileOption(
                            context, Icons.person, 'Account Settings',
                            onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsScreen()),
                          );
                        }),
                        // _buildProfileOption(context,
                        //     Icons.family_restroom_rounded, 'Manage Family',
                        //     onTap: () {}),
                        // _buildProfileOption(context, Icons.settings, 'Settings',
                        //     onTap: () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => const SettingsMain()),
                        //   );
                        // }),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                          child: Divider(),
                        ),
                        // _buildProfileOption(context, Icons.info, 'About', onTap: () => ),
                        _buildProfileOption(context, Icons.info, 'About',
                            onTap: () {
                          AwesomeDialog(
                            padding: const EdgeInsets.all(16),
                            context: context,
                            dialogType: DialogType.noHeader,
                            animType: AnimType.scale,
                            title: 'About This App',
                            titleTextStyle: TextStyle(
                              color: CustomColors.textColor,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                            descTextStyle: TextStyle(
                              color: CustomColors.textColor,
                              fontSize: 16,
                            ),
                            desc: 'The WattHome app is designed to help you track and manage your energy consumption in real-time. '
                                    'With a user-friendly interface and customizable alerts, you can stay on top of your energy usage and save on your electricity bills.\n\n'
                                    'Features:\n'
                                    '- Real-time data updates\n'
                                    '- Energy consumption tracking\n'
                                    '- Customizable alerts and notifications\n'
                                    '- User-friendly interface' +
                                '\n\nVersion: 1.0.0'
                                    '\nMade with ❤️ by Heriot Watt Group 12 (2025)',
                            btnOkOnPress: () {},
                            btnOkColor: CustomColors.primaryColor,
                            dialogBorderRadius:
                                BorderRadius.all(Radius.circular(15)),
                          ).show();
                        }),
                        _buildProfileOption(context, Icons.logout, 'Logout',
                            onTap: () {
                          // AwesomeDialog(
                          //   context: context,
                          //   dialogType: DialogType.warning,
                          //   animType: AnimType.scale,
                          //   title: 'Confirm Logout',
                          //   desc: 'Are you sure you want to log out?',
                          //   btnCancelOnPress: () {},
                          //   btnOkOnPress: () {
                          //     navigatorKey.currentState
                          //         ?.pushReplacementNamed('/login');
                          //   },
                          // ).show();
                          AwesomeDialog(
                            dialogBorderRadius: BorderRadius.circular(15),
                            context: context,
                            dialogType: DialogType.warning,
                            animType: AnimType.scale,
                            title: 'Confirm Logout',
                            desc: 'Are you sure you want to log out?',
                            btnCancelOnPress: () {},
                            btnOkOnPress: () {
                              navigatorKey.currentState
                                  ?.pushReplacementNamed('/login');
                            },
                            btnOkColor: CustomColors.errorColor,
                            btnCancelColor: CustomColors.successColor,
                          ).show();
                        }),
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

class WaveClipperLight extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 30);
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

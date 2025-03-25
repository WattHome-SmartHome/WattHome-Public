import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:watthome_app/Widgets/textField.dart';

class AdminCreateHome extends StatefulWidget {
  const AdminCreateHome({super.key});

  @override
  _AdminCreateHomeState createState() => _AdminCreateHomeState();
}

class _AdminCreateHomeState extends State<AdminCreateHome> {
  final _homeNameController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _homeNameController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _createHomeGroup() async {
    final homeName = _homeNameController.text;
    final user = _auth.currentUser;
    final inviteCode = _generateInviteCode();

    if (homeName.isNotEmpty && user != null) {
      final homeRef = await FirebaseFirestore.instance.collection('homes').add({
        'name': homeName,
        'createdAt': Timestamp.now(),
        'admin': user.uid,
        'inviteCode': inviteCode,
      });

      await homeRef.collection('members').doc(user.uid).set({
        'email': user.email,
        'role': 'admin',
      });

      // Add home ID to the current user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'homeId': homeRef.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Home group "$homeName" created')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavbarAdmin()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a home name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
          child: const Text(
            'Create Home',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: CustomColors.secondaryAccentColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
                  height: 80,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: CustomColors.secondaryAccentColor,
                  ),
                ),
              ),
            ),
            // New transparent wave background
            ClipPath(
              clipper: TransparentWaveClipper(),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CustomColors.secondaryAccentColor.withOpacity(0.5),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Image(image: AssetImage('assets/Images/home-image.png')),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _homeNameController,
                      hintText: 'Home Name',
                      maxLength: 15,
                    ),
                    const SizedBox(height: 20),
                    // Spacer(), // Add Spacer to push the button to the bottom
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _createHomeGroup,
                        child: const Text(
                          'Create Home Group',
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
          ],
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

class TransparentWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    var firstControlPoint = Offset(size.width / 4, size.height - 60);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height);
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Login/onBoarding.dart';
import 'package:watthome_app/Models/customColors.dart'; // Import the joinhome page
import 'package:watthome_app/main.dart';

class MyFamily extends StatefulWidget {
  const MyFamily({super.key});

  @override
  _MyFamilyState createState() => _MyFamilyState();
}

class _MyFamilyState extends State<MyFamily> {
  final _auth = FirebaseAuth.instance;
  String? _homeId;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final homeId = userDoc['homeId'];
        if (homeId != null) {
          final homeDoc = await FirebaseFirestore.instance
              .collection('homes')
              .doc(homeId)
              .get();
          if (homeDoc.exists) {
            if (mounted) {
              setState(() {
                _homeId = homeDoc.id;
              });
            }
            final membersSnapshot = await FirebaseFirestore.instance
                .collection('homes')
                .doc(_homeId)
                .collection('members')
                .get();
            final memberIds =
                membersSnapshot.docs.map((doc) => doc.id).toList();
            final memberDetails = await Future.wait(memberIds.map((id) async {
              final memberDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(id)
                  .get();
              if (memberDoc.exists) {
                return {'name': memberDoc['name'], 'role': memberDoc['role']};
              }
              return null;
            }));
            if (mounted) {
              setState(() {
                _members =
                    memberDetails.whereType<Map<String, dynamic>>().toList();
              });
            }
          }
        }
      }
    }
  }

  Future<void> _leaveFamily() async {
    final user = _auth.currentUser;
    if (user != null && _homeId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('homes')
            .doc(_homeId)
            .collection('members')
            .doc(user.uid)
            .delete();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'homeId': null});
        if (mounted) {
          setState(() {
            _homeId = null;
            _members = [];
          });
          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(builder: (context) => OnBoarding()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave family: $e')),
        );
      }
    }
  }

  void _confirmLeaveFamily() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Family'),
          content: const Text(
              'Are you sure you want to leave the family? You will have to log in again to join a new family.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _leaveFamily();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: CustomColors.backgroundColor,
          title: const Text(
            'My Family',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _confirmLeaveFamily,
            ),
          ]),
      body: _members.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
              color: CustomColors.primaryColor,
            ))
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/Images/DefaultProfile.png'),
                  ),
                  title: Text(member['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member['role']),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

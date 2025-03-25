import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:watthome_app/Models/customColors.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _homeNameController = TextEditingController();
  final _userCodeController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? _homeName;
  String? _inviteCode;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _checkAdminHome();
  }

  @override
  void dispose() {
    _homeNameController.dispose();
    _userCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminHome() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('homes')
          .where('admin', isEqualTo: user.uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final homeDoc = querySnapshot.docs.first;
        setState(() {
          _homeName = homeDoc['name'];
          _inviteCode = homeDoc['inviteCode'];
        });
        _loadMembers(homeDoc.id);
      }
    }
  }

  Future<void> _loadMembers(String homeId) async {
    final membersSnapshot = await FirebaseFirestore.instance
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .get();
    setState(() {
      _members = membersSnapshot.docs
          .map((doc) => {'email': doc['email'], 'role': doc['role']})
          .toList();
      // Sort members to ensure admin is first
      _members.sort((a, b) => b['role'] == 'admin' ? 1 : -1);
    });
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

      setState(() {
        _homeName = homeName;
        _inviteCode = inviteCode;
      });

      _homeNameController.clear();
      _loadMembers(homeRef.id);
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
          child: Text(
            _homeName ?? 'Family',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: CustomColors.secondaryAccentColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            padding: EdgeInsets.only(top: 10, right: 16),
            icon: const Icon(
              Icons.info_outline,
              size: 30,
            ),
            onPressed: () {
              AwesomeDialog(
                padding: const EdgeInsets.all(16),
                dialogBorderRadius: BorderRadius.circular(15),
                context: context,
                dialogType: DialogType.info,
                animType: AnimType.scale,
                title: 'Tip',
                titleTextStyle: TextStyle(
                  color: CustomColors.textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                desc:
                    'Want to remove a user? Swipe left on their profile and tap delete.',
                descTextStyle: TextStyle(
                  color: CustomColors.textColor,
                  fontSize: 16,
                ),
                btnOkOnPress: () {},
                btnOkColor: CustomColors.primaryColor,
              ).show();
            },
          ),
        ],
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
                  height:
                      80, // Increase the height to extend through the app bar
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
              child: _homeName != null
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 450,
                          width: context.width,
                          child: ListView.builder(
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final isAdmin = member['role'] == 'admin';
                              return isAdmin
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Card(
                                        color: Colors
                                            .white, // Make the card color white for admin
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(90),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal:
                                                  6.0), // Adjust padding to reduce gap
                                          leading: CircleAvatar(
                                            radius:
                                                30, // Increase the size of the profile picture
                                            backgroundImage: AssetImage(
                                                'assets/Images/DefaultProfile.png'),
                                          ),
                                          title: Text(member['email'],
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold)),
                                          subtitle: Text('${member['role']}'),
                                        ),
                                      ),
                                    )
                                  : Slidable(
                                      key: UniqueKey(),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              // Remove user from home
                                              // FirebaseFirestore.instance
                                              //     .collection('homes')
                                              //     .doc(
                                              //         _homeName) // Change this to use the correct document ID
                                              //     .collection('members')
                                              //     .where('email',
                                              //         isEqualTo:
                                              //             member['email'])
                                              //     .get()
                                              //     .then((snapshot) {
                                              //   snapshot.docs.forEach((doc) {
                                              //     doc.reference.delete();
                                              //   });
                                              // });

                                              // // Remove home ID from user
                                              // FirebaseFirestore.instance
                                              //     .collection('users')
                                              //     .doc(member['email'])
                                              //     .update({'homeId': null});

                                              // // Reload members
                                              // _loadMembers(
                                              //     _homeName!); // Change this to use the correct document ID
                                            },
                                            backgroundColor:
                                                CustomColors.errorColor,
                                            foregroundColor:
                                                CustomColors.backgroundColor,
                                            icon: Icons.delete,
                                            label: 'Delete',
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Card(
                                          color: CustomColors.tileColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(90),
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal:
                                                    6.0), // Adjust padding to reduce gap
                                            leading: CircleAvatar(
                                              radius:
                                                  30, // Increase the size of the profile picture
                                              backgroundImage: AssetImage(
                                                  'assets/Images/DefaultProfile.png'),
                                            ),
                                            title: Text(member['email'],
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Text(
                                              '${member['role']}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w100),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Divider(),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 5, 16, 5),
                          child: Text(
                            'Want to add someone? Have them join your home by sharing this invite code!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                color: CustomColors.textAccentColor),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _inviteCode ?? '',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                if (_inviteCode != null) {
                                  Clipboard.setData(
                                      ClipboardData(text: _inviteCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Invite code copied to clipboard')),
                                  );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Invite code copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Card(
                          color: CustomColors.tileBorderColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _homeNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Home Name',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _createHomeGroup,
                                  child: const Text('Create Home Group'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _userCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Invite Code',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

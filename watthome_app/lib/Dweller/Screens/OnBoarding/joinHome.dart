import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/ipaddress.dart';

class JoinHome extends StatefulWidget {
  const JoinHome({super.key});

  @override
  _JoinHomeState createState() => _JoinHomeState();
}

class _JoinHomeState extends State<JoinHome> {


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<TextEditingController> _controllers =
      List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());

  void _joinHomeGroup() async {
    String userCode = _controllers.map((c) => c.text).join();
    final user = _auth.currentUser;

    if (userCode.length == 5 && user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('homes')
          .where('inviteCode', isEqualTo: userCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final homeDoc = querySnapshot.docs.first;

        await homeDoc.reference.collection('members').doc(user.uid).set({
          'email': user.email,
          'role': 'member',
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'homeId': homeDoc.id,
        });

        String query = """UPDATE Homes
SET home_name = CONCAT('home_', 
    (SELECT id FROM (SELECT id FROM Homes WHERE user_id = (SELECT id FROM User WHERE firebase_id = ${homeDoc['admin']})) AS subquery LIMIT 1)
)
WHERE user_id = (SELECT id FROM User WHERE firebase_id = "${user.uid}");
""";

        Uri uri = Uri.parse("http://$ip_address/connection").replace(queryParameters: {
    'statm': query,
  });
        http.get(uri);

         uri = Uri.parse("http://$ip_address/updatesql");
        http.get(uri);



        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined home group "${homeDoc['name']}"')),
        );

        _controllers.forEach((c) => c.clear());

        Navigator.pushReplacementNamed(context, '/NavDweller');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid invite code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            bool? confirmLogout = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Confirm Logout"),
                  content: Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text("Logout"),
                    ),
                  ],
                );
              },
            );

            if (confirmLogout == true) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        backgroundColor: CustomColors.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image at the top
              Image.asset(
                'assets/Images/home-image.png',
              ),
              const SizedBox(height: 20),

              const Text(
                "Ask your home group admin for the invite code!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 4) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              // Validate Button
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
                  onPressed: _joinHomeGroup,
                  child: const Text(
                    "Validate",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

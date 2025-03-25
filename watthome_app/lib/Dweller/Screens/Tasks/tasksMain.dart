import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watthome_app/ipaddress.dart';

// String ip_address = "192.168.70.74:5000";

Future<List<String>> fetchTips(String home_id) async {
  String query =
      "SELECT home_id,challenge,tips,points_earned FROM ChallengeParticipants where home_id = $home_id;";

  Uri uri = Uri.parse("http://$ip_address/connection")
      .replace(queryParameters: {'statm': query});
  print(uri);

  final response = await http.get(uri);
  if (response.statusCode != 200) {
    print('Error: ${response.statusCode}');
    return [];
  }

  List<dynamic> jsonData = jsonDecode(response.body);
  // Assuming the first item in the response contains the tips
  String tipsString = jsonData[0]['tips'];
  List<String> tips = List<String>.from(
      jsonDecode(tipsString)); // Decode the tips string into a list of strings
  // print(tips);
  return tips;
}

Future<String> fetchDailyChallenge(String home_id) async {
  String query =
      "SELECT home_id,challenge,tips,points_earned FROM ChallengeParticipants where home_id = $home_id;";

  Uri uri = Uri.parse("http://$ip_address/connection")
      .replace(queryParameters: {'statm': query});
  print(uri);

  final response = await http.get(uri);
  if (response.statusCode != 200) {
    print('Error: ${response.statusCode}');
    return "No daily challenge available.";
  }

  List<dynamic> jsonData = jsonDecode(response.body);
  // Assuming the first item in the response contains the daily challenge
  String dailyChallenge = jsonData[0]['challenge'];
  print(dailyChallenge);
  return dailyChallenge;
}

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  Future<List<String>>? futureTips;
  Future<String>? futureDailyChallenge;
  String home_id = "0";

  Future<void> fetchhomeid() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print(user.uid);
    }

    String query = """SELECT SUBSTRING_INDEX(home_name, '_', -1) AS home_id
FROM Homes
WHERE user_id = (
    SELECT id 
    FROM User 
    WHERE firebase_id = '${user?.uid}'
);')""";

//     String query = """SELECT id
// FROM Homes
// WHERE user_id = (
//     SELECT id
//     FROM User
//     WHERE firebase_id = '${user?.uid}'
// );')""";

    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});
    print(uri);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    setState(() {
      home_id = jsonData[0]["home_id"]; // Update home_id
    });
    home_id = jsonData[0]["home_id"];
    print("HOME ID IS EAQUAL TO $home_id");
  }

  Future<void> _initialize() async {
    await fetchhomeid();

    // futureTips = fetchTips(home_id); // Fetch the tips when the screen is initialized
    // futureDailyChallenge = fetchDailyChallenge(home_id); // Fetch the daily challenge
    setState(() {
      futureTips =
          fetchTips(home_id); // Fetch the tips when the screen is initialized
      futureDailyChallenge =
          fetchDailyChallenge(home_id); // Fetch the daily challenge
    });
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    // futureTips = fetchTips(home_id); // Fetch the tips when the screen is initialized
    // futureDailyChallenge = fetchDailyChallenge(home_id); // Fetch the daily challenge
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Goals",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          AssetImage("assets/Images/DefaultProfile.png"),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: getUserName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(); // Show a loading indicator while waiting
                            } else if (snapshot.hasError) {
                              return Text("Error loading name");
                            } else {
                              return Text(
                                snapshot.data ?? "",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              );
                            }
                          },
                        ),
                        // Text("Energy Points: 1000",
                        //     style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TIPS",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  FutureBuilder<List<String>>(
                    future: futureTips, // Get the tips from the future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Show loading indicator
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No tips available.');
                      } else {
                        // Display the tips from the JSON response
                        return Column(
                          children: snapshot.data!
                              .map((tip) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text("• $tip",
                                        style: TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display daily challenge here in bottom navigation
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.nightlight_round, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Daily Challenge:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      FutureBuilder<String>(
                        future:
                            futureDailyChallenge, // Get the daily challenge from the future
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(); // Show loading indicator
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Text('No daily challenge available.');
                          } else {
                            return Text(
                              snapshot.data!,
                              style: TextStyle(fontSize: 14),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

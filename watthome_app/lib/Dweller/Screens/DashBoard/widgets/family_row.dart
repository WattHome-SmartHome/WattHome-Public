import 'package:flutter/material.dart';

class FamilyRow extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const FamilyRow({required this.members, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: members.map((member) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/Images/DefaultProfile.png'),
                  radius: 30,
                ),
                SizedBox(height: 8),
                Text(
                  member['name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

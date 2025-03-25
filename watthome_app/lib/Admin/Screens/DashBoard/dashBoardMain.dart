import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/ManageAppliances/manageAppliancePage.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';
import 'package:watthome_app/Widgets/homeChart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/ipaddress.dart';

const double widgetWidth = 600; // Needed for the highlight

class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  _DashboardMainState createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  String _selectedTimeRange = '1W';
  List<EnergyDataPoint> _currentData = dailyEnergyData;
  DateTime selectedTime = DateTime.now();
  String _houseName = "My House"; // Default house name
  String home_id = "0";

  final _auth = FirebaseAuth.instance;

  get pool => null;

  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    _fetchHouseName();
    await fetchhomeid();
  }

  Future<void> fetchhomeid() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print(user.uid);
    }
//     String query = """SELECT SUBSTRING_INDEX(home_name, '_', -1) AS home_id
// FROM Homes
// WHERE user_id = (
//     SELECT id
//     FROM User
//     WHERE firebase_id = '${user?.uid}'
// );')""";

    String query = """SELECT id
FROM Homes
WHERE user_id = (
    SELECT id 
    FROM User 
    WHERE firebase_id = '${user?.uid}'
);')""";

    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});
    print(uri);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }

    List<dynamic> jsonData = jsonDecode(response.body);

    home_id = jsonData[0]["id"].toString();
    print("HOME ID IS EHRE $home_id");
  }

  void _fetchHouseName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('homes')
          .where('admin', isEqualTo: user.uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final homeDoc = querySnapshot.docs.first;
        setState(() {
          _houseName = homeDoc['name'];
        });
      }
    }
  }

  Future<void> _updateChartData(String timeRange) async {
    DateTime end_date = DateTime.now();
    DateTime start_date = DateTime.now();
    List<EnergyDataPoint> newEnergyData = [];

    switch (timeRange) {
      case '6H':
        start_date = end_date.subtract(Duration(hours: 6));
        newEnergyData = await fetchEnergyData(start_date, end_date);
        break;

      case '24H':
        start_date = end_date.subtract(Duration(hours: 24));
        newEnergyData = await fetchEnergyData(start_date, end_date);

        break;
      case '1W':
        start_date = end_date.subtract(Duration(days: 7));
        newEnergyData = await fetchEnergyData(start_date, end_date);
        break;

      case '1M':
        start_date = end_date.subtract(Duration(days: 30));
        newEnergyData = await fetchEnergyData(start_date, end_date);
        break;
    }

    setState(() {
      _selectedTimeRange = timeRange;

      _currentData = newEnergyData;
    });

// // start_date = DateTime.parse("2025-02-06 13:22:51");
// // end_date= DateTime.parse("2025-02-28 13:22:51") ;
//       String start_date_str = start_date.toIso8601String();
//       String end_date_str = end_date.toIso8601String();

// String query = "SELECT timestamp, energy_consumed FROM energy_data WHERE home_id = 1 AND timestamp BETWEEN '$start_date_str' AND '$end_date_str' ";
//       print("print start date $start_date");

//   var url = "http://127.0.0.1:5000/connection";
//   Uri uri = Uri.parse(url).replace(queryParameters: {
//     'statm': query,
//   });
//   print(uri);
//   // print(uri.toString());

//   final response = await http.get(uri);

//   if (response.statusCode == 200) {
//     print('Response: ${response.body}');
//   } else {
//     print('Error: ${response.statusCode}');
//   }

// if (response.statusCode == 200) {

//   List<dynamic> jsonData = jsonDecode(response.body);
//   List<EnergyDataPoint> New_data_list = [] ;

// for (var i = 0; i < jsonData.length; i++) {
//   String dateString = jsonData[i]["timestamp"];

//   // Extract parts as substrings
//     String dayStr = dateString.substring(5, 7); // "05"
//     String monthStr = dateString.substring(8, 11); // "Mar"
//     String yearStr = dateString.substring(12, 16); // "2025"
//     String hourStr = dateString.substring(17, 19); // "13"

//     // Convert string numbers to integer without parse()
//     int day = int.parse(dayStr);
//     int year = int.parse(yearStr);
//     int hour = int.parse(hourStr);

//     // Convert month abbreviation to number
//     int month = _monthToNumber(monthStr);

//     print("Year: $year");
//     print("Month: $month");
//     print("Day: $day");
//     print("Hour: $hour");

//     EnergyDataPoint temp = EnergyDataPoint(
//       time: DateTime(year, month, day, hour),
//       energyUsage: double.parse(jsonData[i]["energy_consumed"]),
//     );

//     New_data_list.add(temp);
//   }

//   _currentData = New_data_list;
//   print(New_data_list);
//   // print(New_data_list[0]["time"]);
//   // print(New_data_list[0]["time"]);

//     // List<EnergyDataPoint> parsedData = jsonData.map((entry) {
//     //   return EnergyDataPoint(
//     //     time: DateTime.parse(entry["timestamp"]),
//     //     energyUsage: double.parse(entry["energy_consumed"]),
//     //   );
//     // }).toList();

//     // setState(() {
//     //   _currentData = parsedData;
//     // });

//   //   print('Parsed Data: $_currentData');
//   // } else {
//   //   print('Error: ${response.statusCode}');
//    }
  }

// Future<void> _fetchUsers() async {
//     var users =
//         await pool.execute(
//   "Select * from Homes where user_id=19"
//         );

//         for (var element in users.rows) {
//   Map data = element.assoc();
//   print(
//       data);
// }
//   }

  Future<List<EnergyDataPoint>> fetchEnergyData(
      DateTime startdatein, DateTime endatein) async {
    // DateTime startDate = DateTime.parse("2025-02-06 13:22:51");
    // DateTime endDate = DateTime.parse("2025-02-28 13:22:51");

    String startDateStr = startdatein.toIso8601String();
    String endDateStr = endatein.toIso8601String();

    String query =
        "SELECT timestamp, energy_consumed FROM energy_data WHERE home_id = $home_id AND timestamp BETWEEN '$startDateStr' AND '$endDateStr'; ";
    // print("Start Date: $startDate");

    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});
    print(uri);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
      return [];
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    List<EnergyDataPoint> newDataList = [];

    // for (var data in jsonData) {
    //   // print("THER ERRROR IS EHRE");
    //   String dateString = data["timestamp"];
    //   print(dateString.runtimeType);
    //   DateTime parsedDate = DateTime.parse(dateString);

    //   EnergyDataPoint temp = EnergyDataPoint(
    //     time: parsedDate,
    //     energyUsage: double.parse(data["energy_consumed"]),
    //   );
    //   newDataList.add(temp);
    // }

    for (var i = 0; i < jsonData.length; i++) {
      String dateString = jsonData[i]["timestamp"];

      // Extract parts as substrings
      String dayStr = dateString.substring(5, 7); // "05"
      String monthStr = dateString.substring(8, 11); // "Mar"
      String yearStr = dateString.substring(12, 16); // "2025"
      String hourStr = dateString.substring(17, 19); // "13"

      // Convert string numbers to integer without parse()
      int day = int.parse(dayStr);
      int year = int.parse(yearStr);
      int hour = int.parse(hourStr);

      // Convert month abbreviation to number
      int month = _monthToNumber(monthStr);

      // print("Year: $year");
      // print("Month: $month");
      // print("Day: $day");
      // print("Hour: $hour");

      EnergyDataPoint temp = EnergyDataPoint(
        time: DateTime(year, month, day, hour),
        energyUsage: double.parse(jsonData[i]["energy_consumed"]),
      );

      newDataList.add(temp);
    }

    return newDataList;
  }

  int _monthToNumber(String month) {
    const months = {
      "Jan": 1,
      "Feb": 2,
      "Mar": 3,
      "Apr": 4,
      "May": 5,
      "Jun": 6,
      "Jul": 7,
      "Aug": 8,
      "Sep": 9,
      "Oct": 10,
      "Nov": 11,
      "Dec": 12
    };
    return months[month] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _houseName,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ), // Set the app bar title
        backgroundColor: CustomColors.backgroundColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Energy used: \n${_calculateAverageEnergyUsage(_currentData).toStringAsFixed(2)} kWh",
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            EnergyUsageChart(
              data: _currentData,
              currentTime: selectedTime,
              selectedTimeRange: _selectedTimeRange,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMM dd, HH:mm')
                      .format(_currentData.first.time)),
                  Text(DateFormat('MMM dd, HH:mm')
                      .format(_currentData.last.time))
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTimeButton("6H"),
                    _buildTimeButton("24H"),
                    _buildTimeButton("1W"),
                    _buildTimeButton("1M"),
                    // _buildTimeButton("3M"),
                    // _buildTimeButton("1Y"),
                    // _buildTimeButton("2Y"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // _buildProfileOption(
                  //   context,
                  //   Icons.bar_chart_rounded,
                  //   "Energy Report",
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //           builder: (context) => const EnergyReport()),
                  //     );
                  //     print("hello");
                  //   },
                  // ),
                  _buildProfileOption(
                    context,
                    Icons.devices_rounded,
                    "Manage Appliances",
                    onTap: () {
                      // Navigate to Manage Appliances screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const Manageappliancepage()));
                    },
                  ),
                  // _buildProfileOption(
                  //   context,
                  //   Icons.support_agent_rounded,
                  //   "Support and Services",
                  //   onTap: () {
                  //     // Navigate to Support and Services screen
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String timeRange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: () {
          _updateChartData(timeRange);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          minimumSize: const Size(45, 25),
          textStyle: const TextStyle(fontSize: 14),
          backgroundColor: _selectedTimeRange == timeRange
              ? const Color(0xFFBB7752)
              : const Color.fromARGB(255, 234, 224, 218),
          foregroundColor:
              _selectedTimeRange == timeRange ? Colors.white : Colors.black,
        ),
        child: Text(timeRange),
      ),
    );
  }

  double _calculateAverageEnergyUsage(List<EnergyDataPoint> data) {
    if (data.isEmpty) return 0;
    double totalUsage = 0;
    for (var point in data) {
      totalUsage += point.energyUsage;
    }
    return totalUsage;
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
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

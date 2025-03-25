import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';
import 'package:watthome_app/Widgets/homeChart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:date_field/date_field.dart';
import 'package:path_provider/path_provider.dart';

// import 'dart:html' as html;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:watthome_app/ipaddress.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Reportspage extends StatefulWidget {
  const Reportspage({super.key});

  @override
  _ReportspageState createState() => _ReportspageState();
}

class _ReportspageState extends State<Reportspage> {
  String _selectedTimeRange = '1W';
  List<EnergyDataPoint> _currentData = dailyEnergyData;
  DateTime selectedTime = DateTime.now();
  String _houseName = "My House"; // Default house name
  DateTime? selectedstartDate = DateTime.now();
  DateTime? selectedendDate = DateTime.now();
  final _auth = FirebaseAuth.instance;

  get pool => null;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    _fetchHouseName();
    await fetchhomeid();
    await initNotifications();
    Datas();
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
    ;
    print("HOME ID SI SHERE ");
  }

  String startDateStr = "";
  String endDateStr = "";
  double solarRoofPower = 0.0; // kW
  double homeUsage = 1.0; // kW
  double powerwallPower = 3.0; // kW
  double powerwallPercentage = 79.0; // %
  double gridUsage = 0.0; // kW
  String home_id = "0";
  // String ip_address = "192.168.70.74:5000";

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Ensure this exists

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          // Open the downloaded file when notification is tapped
          OpenFilex.open(response.payload!);
        }
      },
    );
  }

  Future<void> downloadFile(
      String home_id, String? startDateStr, String? endDateStr) async {
    String fileName = "report.pdf";
    String url = 'http://$ip_address/generatereport';

    Uri uri = Uri.parse(url).replace(queryParameters: {
      "home_id": home_id,
      "start_date": startDateStr,
      "end_date": endDateStr
    });

    final response = await http.get(uri);
    Uint8List bytes = response.bodyBytes;

    Directory? downloadsDir;
    String? filePath;

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    if (Platform.isAndroid) {
      // Handle permission request for storage
      if (await Permission.storage.request().isDenied) {
        print("Storage permission denied");
        return;
      }

      // For Android 10 and above, use scoped storage
      if (Platform.isAndroid &&
          !await Permission.manageExternalStorage.isGranted) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          print("Permission to manage external storage denied");
          return;
        }
      }

      // Scoped storage or public external storage (Android 10 and above)
      downloadsDir = Directory(
          '/storage/emulated/0/Download'); // For devices without Scoped Storage access restrictions
      // Alternatively, use Scoped storage (Android 10+) for specific app directory:
      // downloadsDir = await getExternalStorageDirectory(); // Use this for scoped access
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null || !downloadsDir.existsSync()) {
      print("Downloads directory not found");
      return;
    }

    filePath = "${downloadsDir.path}/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    print("File saved to: $filePath");

    showDownloadNotification(filePath);
  }

  void showDownloadNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel',
      'Download Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      'Tap to open the file',
      platformChannelSpecifics,
      payload: filePath, // Attach file path as payload
    );
  }

// Future<void> initNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure this exists

//   final InitializationSettings initializationSettings =
//       InitializationSettings(android: initializationSettingsAndroid);

//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) {
//       if (response.payload != null) {
//         OpenFilex.open(response.payload!);
//       }
//     },
//   );
// }

// Future<void> downloadFile(String home_id, String? startDateStr, String? endDateStr) async {
//   String fileName = "report.pdf";
//   String url = 'http://$ip_address/generatereport';

//   Uri uri = Uri.parse(url).replace(queryParameters: {
//     "home_id": home_id,
//     "start_date": startDateStr,
//     "end_date": endDateStr
//   });

//   final response = await http.get(uri);
//   Uint8List bytes = response.bodyBytes;

//   Directory? downloadsDir;
//   String? filePath;

//   if (kIsWeb) {
//     final blob = html.Blob([bytes]);
//     final url = html.Url.createObjectUrlFromBlob(blob);
//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute("download", fileName)
//       ..click();
//     html.Url.revokeObjectUrl(url);
//     return;
//   }

//   if (Platform.isAndroid) {
//     if (await Permission.storage.request().isDenied) {
//       print("Storage permission denied");
//       return;
//     }
//     downloadsDir = Directory('/storage/emulated/0/Download');
//   } else if (Platform.isIOS) {
//     downloadsDir = await getApplicationDocumentsDirectory();
//   } else {
//     downloadsDir = await getDownloadsDirectory();
//   }

//   if (downloadsDir == null || !downloadsDir.existsSync()) {
//     print("Downloads directory not found");
//     return;
//   }

//   filePath = "${downloadsDir.path}/$fileName";
//   final file = File(filePath);
//   await file.writeAsBytes(bytes);

//   print("File saved to: $filePath");

//   showDownloadNotification(filePath);
// }

// void showDownloadNotification(String filePath) async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     'download_channel',
//     'Download Notifications',
//     importance: Importance.high,
//     priority: Priority.high,
//   );

//   const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'Download Complete',
//     'Tap to open the file',
//     platformChannelSpecifics,
//     payload: filePath,
//   );
// }

// Future<void> downloadFile(String home_id, String? startDateStr, String? endDateStr) async {
//   String fileName = "report.pdf";
//   String url = 'http://$ip_address/generatereport';

//   Uri uri = Uri.parse(url).replace(queryParameters: {
//     "home_id": home_id,
//     "start_date": startDateStr,
//     "end_date": endDateStr
//   });

//   final response = await http.get(uri);
//   Uint8List bytes = response.bodyBytes;

//   if (kIsWeb) {

//     final blob = html.Blob([bytes]);
//     final url = html.Url.createObjectUrlFromBlob(blob);
//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute("download", fileName)
//       ..click();
//     html.Url.revokeObjectUrl(url);
//   } else {

//     Directory? downloadsDir;

//     if (Platform.isAndroid) {

//       if (await Permission.storage.request().isDenied) {
//         print("Storage permission denied");
//         return;
//       }
//       downloadsDir = Directory('/storage/emulated/0/Download');
//     } else if (Platform.isIOS) {
//       downloadsDir = await getApplicationDocumentsDirectory();
//     } else {
//       downloadsDir = await getDownloadsDirectory();
//     }

//     if (downloadsDir == null || !downloadsDir.existsSync()) {
//       print("Downloads directory not found");
//       return;
//     }

//     final filePath = "${downloadsDir.path}/$fileName";
//     final file = File(filePath);
//     await file.writeAsBytes(bytes);

//     print("File saved to: $filePath");
//   }
// }

  Future<void> Datas() async {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    startDate = endDate.subtract(Duration(hours: 6));

    String startDateStr = startDate.toIso8601String();
    String endDateStr = endDate.toIso8601String();

    String query =
        """SELECT SUM(energy_generated) AS total_solar_power FROM energy_data where home_id = $home_id AND timestamp BETWEEN '$startDateStr' AND '$endDateStr' 

Union ALL

SELECT SUM(energy_consumed) AS total_energy_consumerd FROM energy_data where home_id = $home_id AND timestamp BETWEEN '$startDateStr' AND '$endDateStr';""";
    // print("Start Date: $startDate");

    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});
    print(uri);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    print(jsonData[0]["total_solar_power"]);
    print(jsonData[1]["total_solar_power"]);
    print((jsonData[0]["total_solar_power"]).runtimeType);

    solarRoofPower = double.parse(jsonData[0]["total_solar_power"]);
    homeUsage = double.parse(jsonData[1]["total_solar_power"]);

    if (solarRoofPower - homeUsage >= 0) {
      powerwallPower = (solarRoofPower - homeUsage).abs();
      // battery can hold 30KWH
      powerwallPercentage = ((solarRoofPower - homeUsage).abs() / 30.0) * 100;
      gridUsage = 0.0;
    } else {
      gridUsage = (solarRoofPower - homeUsage).abs();
      powerwallPercentage = 0.0;
      powerwallPower = 0.0;
    }
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
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "Energy used today: ${_calculateAverageEnergyUsage(_currentData).toStringAsFixed(2)} kWh",
                      style: const TextStyle(fontSize: 16),
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
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Energy Flow",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Solar Panel"),
                          Text(
                            solarRoofPower.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                      // Text("Solar Panel  30 watts"),
                      Row(
                        children: [
                          Text("Solar battery"),
                          Text(
                            powerwallPower.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                      Row(
                        children: [
                          Text("Grid"),
                          Text(gridUsage.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ))
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DateTimeFormField(
                decoration: const InputDecoration(
                  labelText: 'Enter Start Date',
                ),
                firstDate: DateTime.now().subtract(const Duration(days: 20)),
                lastDate: DateTime.now().add(const Duration(days: 40)),
                initialPickerDateTime: DateTime.now(),
                onChanged: (DateTime? value) {
                  selectedstartDate = value;
                  print("selectedstartDate $selectedstartDate");
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DateTimeFormField(
                decoration: const InputDecoration(
                  labelText: 'Enter End Date',
                ),
                firstDate: DateTime.now().subtract(const Duration(days: 20)),
                lastDate: DateTime.now().add(const Duration(days: 40)),
                initialPickerDateTime: DateTime.now(),
                onChanged: (DateTime? value) {
                  selectedendDate = value;
                },
              ),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryColor),
                  onPressed: () async {
                    downloadFile(home_id, selectedstartDate?.toIso8601String(),
                        selectedendDate?.toIso8601String());
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Download Report',
                        style: TextStyle(color: Colors.white)),
                  )),
            )),
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

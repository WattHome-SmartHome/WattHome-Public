import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/homeChart.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';
import 'package:draggable_home/draggable_home.dart';
import 'package:watthome_app/Models/availableDevices.dart';
import 'package:watthome_app/Dweller/Screens/Rooms/ApplicationScreen.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/ipaddress.dart';

class RoomPage extends StatefulWidget {
  final String roomName;
  final List<dynamic> devices;
  final String imageNum;

  const RoomPage({
    required this.roomName,
    required this.devices,
    required this.imageNum,
    Key? key,
  }) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<EnergyDataPoint> dataList = []; // Declare class variable

  //  List<EnergyDataPoint> placeholderData = [
  //   EnergyDataPoint(
  //       time: DateTime.now().subtract(Duration(hours: 5)), energyUsage: 1.5),
  //   EnergyDataPoint(
  //       time: DateTime.now().subtract(Duration(hours: 4)), energyUsage: 2.0),
  //   EnergyDataPoint(
  //       time: DateTime.now().subtract(Duration(hours: 3)), energyUsage: 1.8),
  //   EnergyDataPoint(
  //       time: DateTime.now().subtract(Duration(hours: 2)), energyUsage: 2.2),
  //   EnergyDataPoint(
  //       time: DateTime.now().subtract(Duration(hours: 1)), energyUsage: 1.9),
  //   EnergyDataPoint(time: DateTime.now(), energyUsage: 2.5),
  // ];

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

  Future<List<EnergyDataPoint>> fetchEnergyData(
      String home_id, List<int> appliance_id, List<int> deviceId) async {
    DateTime end_date = DateTime.now();
    DateTime start_date = DateTime.now();
    String query = "";

    print("fesfesfesf  $deviceId");

    start_date = end_date.subtract(Duration(days: 7));

    String startDateStr = start_date.toIso8601String();
    String endDateStr = end_date.toIso8601String();

// query = """ SELECT
//     timestamp,
//     SUM(energy_consumed) AS energy_consumed
// FROM (
//     SELECT
//         timestamp,
//         energy_consumed
//     FROM appliancecontrolenergy_data
//     WHERE device_number = 1
//       AND home_id = 1
//       AND appliance_id = 1
//       -- AND timestamp BETWEEN '2025-02-20 00:55:18' AND '2025-02-15 20:55:18'
//       AND timestamp BETWEEN  '2025-02-15 20:55:18' AND '2025-02-20 00:55:18'
//     UNION ALL

//     SELECT
//         timestamp,
//         energy_consumed
//     FROM appliancecontrolenergy_data
//     WHERE device_number = 2
//       AND home_id = 1
//       AND appliance_id = 2
//      AND timestamp BETWEEN  '2025-02-15 20:55:18' AND '2025-02-20 00:55:18'
// ) AS combined
// GROUP BY timestamp
// ORDER BY timestamp;""";

    query = """
    SELECT 
        timestamp,  
        SUM(energy_consumed) AS energy_consumed  
    FROM ( 
  """;

    StringBuffer temp = StringBuffer();

    for (int i = 0; i < appliance_id.length; i++) {
      if (i > 0) {
        temp.write(" UNION ALL ");
      }

      temp.write("""
      SELECT timestamp, energy_consumed FROM appliancecontrolenergy_data 
      WHERE device_number = 1 AND home_id = 1 AND appliance_id = ${appliance_id[i]} 
      AND timestamp BETWEEN '$startDateStr' AND '$endDateStr' 
    """);
    }

    query += temp.toString() +
        ") AS combined GROUP BY timestamp ORDER BY timestamp;";

    // Replace newlines with spaces for cleaner output
    query = query.replaceAll('\n', ' ');

    print(query);

    //String query = "SELECT timestamp, energy_consumed FROM appliancecontrolenergy_data WHERE home_id = $home_id AND appliance_id =$appliance_id And timestamp BETWEEN '$startDateStr' AND '$endDateStr'";
    // print("Start Date: $startDate");

    // query = "SELECT * From ChallengeParticipants";
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

      String dayStr = dateString.substring(5, 7); // "05"
      String monthStr = dateString.substring(8, 11); // "Mar"
      String yearStr = dateString.substring(12, 16); // "2025"
      String hourStr = dateString.substring(17, 19); // "13"

      int day = int.parse(dayStr);
      int year = int.parse(yearStr);
      int hour = int.parse(hourStr);

      int month = _monthToNumber(monthStr);

      EnergyDataPoint temp = EnergyDataPoint(
        time: DateTime(year, month, day, hour),
        // energyUsage: double.parse(jsonData[i]["energy_consumed"]),
        energyUsage: (jsonData[i]["energy_consumed"] is String)
            ? double.tryParse(jsonData[i]["energy_consumed"]) ?? 0.0
            : jsonData[i]["energy_consumed"] as double,
      );
      // print(temp.energyUsage);
      // print(temp.energyUsage.runtimeType);
      newDataList.add(temp);
    }

    //      setState(() {
    //    _selectedTimeRange = timeRange;

    //   _currentData = newEnergyData;

    // });
    dataList = newDataList;
    print(newDataList);
    return newDataList;
  }

  bool isLoading = true; // Track loading state
  @override
  // void initState() {
  //   super.initState();
  //   Datalist = fetchEnergyData("1",[1,2,3,4],[1,2,3,4]);

  // }

  void initState() {
    super.initState();

    _initialize();
    print(dataList);
  }

  Future<void> _initialize() async {
    // Ensures fetchhomeid runs first, even if it's synchronous
    List<EnergyDataPoint> fetchedData =
        await fetchEnergyData("1", [1, 2, 3, 4], [1, 2, 3, 4]);

    setState(() {
      dataList = fetchedData; // Update UI with fetched data
    });

    print(dataList);
  }

  Widget _getDeviceImage(String deviceName) {
    final device = availableDevices.firstWhere(
      (device) => device.name.toLowerCase() == deviceName.toLowerCase(),
      orElse: () =>
          Device(name: 'Unknown', imageUrl: 'assets/Images/unknown.png'),
    );
    return Image.asset(device.imageUrl, width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();
    double appBarHeight = 100.0;

    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && appBarHeight > 100.0) {
        appBarHeight -= _scrollController.offset / 10;
      } else if (_scrollController.offset <= 0 && appBarHeight < 200.0) {
        appBarHeight = 200.0;
      }
    });

    //----------------------------------------------------------------------------------------------------------
    // placeholder data for the energy usage chart

    //----------------------------------------------------------------------------------------------------------

    return DraggableHome(
      title: Text(
        widget.roomName,
        style: TextStyle(
            color: CustomColors.textColor,
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal-Bold'),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 19, 0),
          child: Text(
            '${widget.devices.length} devices',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
      headerWidget: headerWidget(context),
      appBarColor: CustomColors.primaryAccentColor.withOpacity(0.5),
      headerExpandedHeight: 0.30,
      body: [
        EnergyUsageChart(
          data: dataList,
          currentTime: DateTime.now(),
          selectedTimeRange: 'Last 24 Hours',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Devices',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: CustomColors.primaryColor,
              ),
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.devices.length,
              itemBuilder: (context, index) {
                final device = widget.devices[index];
                final deviceName = device['name'] ?? 'Unknown Device';
                final customName = device['customName'] ?? deviceName;

                print("Device Name: $deviceName | Custom Name: $customName");

                return GestureDetector(
                  onTap: () {
                    print(device);
                    print(
                        "Clicked Device: Index = $index, Name = $deviceName, ID = ${device['deviceId']}");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicationScreen(
                          item: deviceName,
                          deviceid: device['deviceId'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: CustomColors.textboxColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    shadowColor: Colors.grey.withOpacity(0.5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: _getDeviceImage(deviceName),
                      ),
                      title: Text(
                        customName,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: CustomColors.primaryColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: CustomColors.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            )),
      ],
      fullyStretchable: true,
      expandedBody: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Images/rooms/${widget.imageNum}.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget headerWidget(BuildContext context) {
    return Container(
      height: 200.0,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Images/rooms/${widget.imageNum}.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Hero(
        tag:
            'roomImage_${widget.imageNum}_${widget.roomName}', // Unique tag for each room image
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color.fromARGB(255, 0, 0, 0), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            centerTitle: true,
            title: Text(
              widget.roomName,
              style: TextStyle(
                  color: CustomColors.backgroundColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal-Bold',
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ]),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: IconButton(
                iconSize: 35.0,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: CustomColors.backgroundColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

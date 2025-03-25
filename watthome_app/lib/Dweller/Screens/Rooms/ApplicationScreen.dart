import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';
import '/Models/availableDevices.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/ipaddress.dart';

class ApplicationScreen extends StatefulWidget {
  final String item;
  final Map<String, dynamic>? device;
  
  final dynamic deviceid;

  // Constructor to accept parameters
  const ApplicationScreen({super.key, required this.item, this.deviceid, this.device});

  @override
  _ApplicationScreenState createState() => _ApplicationScreenState();
}

Future<List<EnergyDataPoint>> fetchEnergyData(String home_id, String value, String appliance_id, String deviceId) async {
  DateTime end_date = DateTime.now();
  DateTime start_date = DateTime.now();
  String query = "";

  print("fesfesfesf  $deviceId");
  if (value == "This week") {
    start_date = end_date.subtract(Duration(days: 7));

    String startDateStr = start_date.toIso8601String();
    String endDateStr = end_date.toIso8601String();
    query =
        "SELECT timestamp, energy_consumed FROM appliancecontrolenergy_data WHERE device_number = $deviceId AND home_id = $home_id AND appliance_id = $appliance_id And timestamp BETWEEN '$startDateStr' AND '$endDateStr'";
  }

  if (value == "This Month") {
    start_date = end_date.subtract(Duration(days: 30));

    String startDateStr = start_date.toIso8601String();
    String endDateStr = end_date.toIso8601String();

    // print(startDateStr);
    // print(endDateStr);

    query = """
SELECT
    DATE(timestamp) AS timestamp,  
    ROUND(AVG(energy_consumed), 3) AS energy_consumed  
FROM appliancecontrolenergy_data
WHERE timestamp BETWEEN '$startDateStr' AND '$endDateStr'
GROUP BY DATE(timestamp)
ORDER BY DATE(timestamp);
  """;
  }

  if (value == "Past 24H") {
    start_date = end_date.subtract(Duration(hours: 24));
    String startDateStr = start_date.toIso8601String();
    String endDateStr = end_date.toIso8601String();
    query =
        "SELECT timestamp, energy_consumed FROM appliancecontrolenergy_data WHERE device_number = $deviceId AND home_id = $home_id AND appliance_id =$appliance_id And timestamp BETWEEN '$startDateStr' AND '$endDateStr'";
        print(query);
  }

  // DateTime startDate = DateTime.parse("2025-02-06 13:22:51");
  // DateTime endDate = DateTime.parse("2025-02-28 13:22:51");

  String startDateStr = start_date.toIso8601String();
  String endDateStr = end_date.toIso8601String();

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

double _sliderValue = 0.0; // Default value

class _ApplicationScreenState extends State<ApplicationScreen> {
  bool power = false; // Initial state for the Air Conditioner switch
  String home_id = "0";

  List<EnergyDataPoint> _currentData = []; // Initially empty list
  String selectedTimeScale = "This week"; // Track the selected time scale
  String applianceid = "Null"; // Move applianceid to class level

  void updateSlider(double value, String home_id, String appliance_id,String deviceId) {
    setState(() {
      _sliderValue = value; // UI UPDATE happens immediately
    });

    _sendSliderUpdate(value, home_id, appliance_id,widget.deviceid.toString().toString());
  }

  Future<void> _sendSliderUpdate(
      double value, String home_id, String appliance_id,String deviceId) async {
    print("qurety time");
    print(value);
    // String query ="UPDATE appliancecontrolenergy_data SET slider_state = $value WHERE home_id = $home_id AND appliance_id = $appliance_id;";
    String query =
        " UPDATE appliancecontrolenergy_data SET slider_state = $value WHERE device_number = $deviceId AND home_id = $home_id AND appliance_id = $appliance_id;";
    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});

    print(uri);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      String query =
          "SELECT * from appliancecontrolenergy_data WHERE device_number = $deviceId AND home_id = $home_id AND appliance_id = $appliance_id;";
      Uri uri = Uri.parse("http://$ip_address/connection")
          .replace(queryParameters: {'statm': query});
      final response = await http.get(uri);
      //print(response.body);
    }
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }
  }

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

    home_id = jsonData[0]["home_id"];
    print("HOME ID IS EAQUAL TO $home_id");
  }

  // String ip_address = "192.168.70.74:5000";
  @override
  void initState() {
    super.initState();
    _initialize();
    // _setApplianceId();
    // SetSliderval(home_id , applianceid);
    // SetPoweronoff(home_id,applianceid);
    // _fetchAndUpdateData();
    print(ip_address);
  }

  Future<void> _initialize() async {
    // Ensures fetchhomeid runs first, even if it's synchronous
    await fetchhomeid(); // Ensure this runs first
    // print("homeid is this : $home_id");

    _setApplianceId();
    SetSliderval(home_id, applianceid,widget.deviceid.toString());
    SetPoweronoff(home_id, applianceid,widget.deviceid.toString());
    _fetchAndUpdateData();
  }

  void SetSliderval(String home_id, String applianceid,String deviceId) async {
    // Uri uri = Uri.parse("http://127.0.0.1:5000/");
    // final response = await http.get(uri);

    // if (response.statusCode != 200) {
    //  print('Error: ${response.statusCode}');
    // }

    Uri uri =
        Uri.parse("http://$ip_address/connection").replace(queryParameters: {
      'statm':
          "SELECT slider_state FROM appliancecontrolenergy_data WHERE device_number = $deviceId AND home_id = $home_id AND appliance_id = $applianceid;"
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    print(jsonData[0]["slider_state"]);
    _sliderValue = jsonData[0]["slider_state"];
  }

  void _setApplianceId() {
    switch (widget.item) {
      case "Smart Light":
        applianceid = "1";
        break;
      case "Air Conditioner":
        applianceid = "2";
        break;
      case "Smart Speaker":
        applianceid = "3";
        break;
      case "Smart TV":
        applianceid = "4";
        break;
      default:
        applianceid = "Null";
    }

    SetSliderval(home_id, applianceid,widget.deviceid.toString());
  }

  void _fetchAndUpdateData() async {
    if (applianceid == "Null")
      return; // Avoid fetching if appliance ID is invalid
    List<EnergyDataPoint> newData =
        await fetchEnergyData(home_id, selectedTimeScale, applianceid, widget.deviceid.toString().toString());
    setState(() {
      _currentData = newData;
    });
  }

  Widget _getDeviceImage(String deviceName) {
    final device = availableDevices.firstWhere(
      (device) => device.name.toLowerCase() == deviceName.toLowerCase(),
      orElse: () =>
          Device(name: 'Unknown', imageUrl: 'assets/Images/unknown.png'),
    );
    return Image.asset(device.imageUrl, width: 70, height: 70);
  }

  void SetPoweronoff(String home_id, String applianceid, String deviceId) async {
    Uri uri =
        Uri.parse("http://$ip_address/connection").replace(queryParameters: {
      'statm':
          "SELECT power from appliancecontrolenergy_data where device_number = $deviceId AND home_id = $home_id and appliance_id=$applianceid;"
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }

    //print(response.body);
    List<dynamic> jsonData = jsonDecode(response.body);

    power = (jsonData[0]["power"]) != 0;
  }

  void updatepower(bool value, String home_id, String appliance_id,String deviceId) {
    setState(() {
      power = value; // UI UPDATE happens immediately
    });

    _sendpowerUpdate(value, home_id, appliance_id,widget.deviceid.toString());
  }

  Future<void> _sendpowerUpdate(
      bool value, String home_id, String appliance_id, String deviceId) async {
    String query =
        "UPDATE appliancecontrolenergy_data set power = $value where device_number = $deviceId AND home_id = $home_id and appliance_id = $appliance_id;;";
    Uri uri = Uri.parse("http://$ip_address/connection")
        .replace(queryParameters: {'statm': query});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    String GraphTXT = "NULL";
    String option1 = "NULL";
    String option2 = "NULL";
    String SliderTXT = "NULL";

    switch (widget.item) {
      case "Air Conditioner":
        GraphTXT = "Air Conditioner";
        option1 = "Swing";
        SliderTXT = "Temperature";
        break;
      case "Smart Light":
        GraphTXT = "Smart Light";
        option1 = "Lamp Lifespan";
        option2 = "Color Change";
        SliderTXT = "Lamp Brightness";
        break;
      case "Smart Speaker":
        GraphTXT = "Smart Speaker";
        option1 = "Turn off";
        SliderTXT = "Volume";
        break;
      case "Smart TV":
        GraphTXT = "Smart TV";
        option1 = "Turn OFF";
        option2 = "Parental Controls";
        SliderTXT = "Volume";
        break;
    }

// void _fetchAndUpdateData() async {
//     List<EnergyDataPoint> newData = await fetchEnergyData("This week", applianceid);
//     setState(() {
//       _currentData = newData;
//     });
// }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Living Room",
          style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Info Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _getDeviceImage(widget.item),
                            SizedBox(height: 20),
                            Text(
                              widget.item,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "inter"),
                            ),
                            Text(
                              "1 Device",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "inter"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      activeColor: CustomColors.primaryColor,
                      activeTrackColor: CustomColors.primaryAccentColor,
                      thumbColor: WidgetStateProperty.all(Theme.of(context)
                          .switchTheme
                          .thumbColor
                          ?.resolve({WidgetState.selected})),
                      value: power, // Set the value to the current state
                      onChanged: (val) {
                        setState(() {
                          updatepower(val, home_id, applianceid, widget.deviceid.toString());
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),

            // Time Scale and Graph Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: EdgeInsets.only(left: 12.0, bottom: 12.0, right: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.item,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          underline: SizedBox(),
                          value: selectedTimeScale,
                          items: ["Past 24H", "This week", "This Month"]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child:
                                  Text(value, style: TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTimeScale = value!;
                              // Call the fetchEnergyData method with updated time scale
                              fetchEnergyData(
                                      home_id, selectedTimeScale, applianceid,widget.deviceid.toString().toString())
                                  .then((newData) {
                                setState(() {
                                  _currentData = newData;
                                });
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text("Energy Used", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              spots: _currentData.map((dataPoint) {
                                return FlSpot(
                                  dataPoint.time.millisecondsSinceEpoch
                                      .toDouble(),
                                  dataPoint.energyUsage,
                                  // myDouble,
                                );
                              }).toList(),
                              barWidth: 2.5,
                              isStrokeCapRound: false,
                              dotData: FlDotData(show: true),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Temperature Control
            Text(SliderTXT,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                )),
            SizedBox(height: 6),

            Card(
              color: Theme.of(context).cardColor,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InteractiveSlider(
                controller: InteractiveSliderController(_sliderValue),
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                unfocusedOpacity: 1,
                unfocusedHeight: 40,
                focusedHeight: 60,
                foregroundColor: Color(0xFF275054),
                backgroundColor:
                    Theme.of(context).sliderTheme.inactiveTrackColor,
                startIcon: Text("0",
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                startIconBuilder: (context, temp, child) => Text(
                    ((temp * 100).truncate()).toString(),
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                onProgressUpdated: (value) =>
                    updateSlider(value, home_id, applianceid,widget.deviceid.toString()),
              ),
            ),

            SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  elevation: 5, // Add some elevation for a shadow effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        15), // Round the corners of the card
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Icon(Icons.arrow_downward, size: 28),
                  ),
                ),
                Card(
                  elevation: 5, // Add some elevation for a shadow effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        15), // Round the corners of the card
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Icon(Icons.arrow_upward, size: 28),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // Replace Spacer with SizedBox
          ],
        ),
      ),
    );
  }
}

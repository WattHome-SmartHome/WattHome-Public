import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:watthome_app/Dweller/Screens/Profile/myFamily.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Dweller/Screens/DashBoard/widgets/family_row.dart';
import 'package:watthome_app/Dweller/Screens/DashBoard/widgets/info_card.dart';
import 'package:watthome_app/Dweller/Screens/DashBoard/widgets/pie_chart_card.dart';
import 'package:watthome_app/Dweller/Screens/DashBoard/widgets/frequently_used_devices.dart';
import 'package:http/http.dart' as http;
import 'package:watthome_app/Widgets/navbar-dweller.dart';
import 'package:watthome_app/ipaddress.dart';
import 'package:draggable_home/draggable_home.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:geolocator/geolocator.dart';

class DwellerHomeScreen extends StatefulWidget {
  const DwellerHomeScreen({super.key});

  @override
  State<DwellerHomeScreen> createState() => DwellerHomeScreenState();
}

class DwellerHomeScreenState extends State<DwellerHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bobbingAnimation;
  late ScrollController _scrollController;
  String homeName = 'Home'; // Default home name
  final _auth = FirebaseAuth.instance;
  double _scrollOffset = 0.0;
  bool _isExpanded = false;
  bool _isInfoCardSticky = false;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _frequentlyUsedDevices = [];
  WeatherScene _weatherType = WeatherScene.weatherEvery;
  String? apikey = '82df7d570ef72b5ac302370458b46a6f';
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Placeholder data - replace with your actual data fetching
  double solarRoofPower = 0.0; // kW
  double homeUsage = 0.0; // kW
  double powerwallPower = 0.0; // kW
  double powerwallPercentage = 100.0; // %
  double gridUsage = 0.0; // kW
  String home_id = "0";
  // String ip_address = "192.168.70.74:5000";

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
  }

  Future<void> Datas() async {
    await fetchhomeid();

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    startDate = endDate.subtract(Duration(hours: 6));

    String startDateStr = startDate.toIso8601String();
    String endDateStr = endDate.toIso8601String();

    print(startDate);
    print(endDate);

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
      powerwallPower = double.parse((solarRoofPower - homeUsage).abs().toStringAsFixed(2));
      // battery can hold 30KWH
      powerwallPercentage = double.parse(
          (((solarRoofPower - homeUsage).abs() / 30.0) * 100)
              .toStringAsFixed(2));
             print( "powerwall percentage $powerwallPercentage");
      gridUsage = 0.0;
    } else {
      gridUsage = double.parse(
          (solarRoofPower - homeUsage).abs().toStringAsPrecision(2));
      powerwallPercentage = 0.0;
      powerwallPower = 0.0;
    }
  }

  @override
  void initState() {
    Datas();
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _bobbingAnimation = Tween<double>(begin: 0, end: 10)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _controller.forward();
    _fetchHomeName();
    _loadFamilyMembers();
    loadFrequentlyUsedDevices();
    _getLocation();
    // Fetch your actual data here (e.g., from Firebase)
    // _fetchEnergyData();
  }

  void _scrollListener() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isInfoCardSticky = _scrollOffset >= 250;
    });
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      _controller.reverse();
      (context.findAncestorStateOfType<NavbarDwellerState>())
          ?.toggleNavBarVisibility(false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _controller.forward();
      (context.findAncestorStateOfType<NavbarDwellerState>())
          ?.toggleNavBarVisibility(true);
    }
  }

  Future<void> _fetchHomeName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final homeId = userDoc['homeId'];
        final homeDoc = await FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .get();
        if (homeDoc.exists) {
          setState(() {
            homeName = homeDoc['name'];
          });
        }
      }
    }
  }

  Future<void> _refresh() async {
    _controller.reset();
    _controller.forward();
    // Fetch updated data if needed
    await _fetchHomeName();
    await _loadFamilyMembers();
    await loadFrequentlyUsedDevices();
    // _fetchEnergyData();
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
            final membersSnapshot = await FirebaseFirestore.instance
                .collection('homes')
                .doc(homeId)
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

  Future<void> loadFrequentlyUsedDevices() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final homeId = userDoc['homeId'];
      if (homeId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('frequentlyUsedDevices')
            .get();
        if (mounted) {
          setState(() {
            _frequentlyUsedDevices =
                snapshot.docs.map((doc) => doc.data()).toList();
          });
        }
      }
    }
  }

  void _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _fetchWeather();
    } catch (e) {
      if (e is PermissionDeniedException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission denied to access location.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
          ),
        );
      }
    }
  }

  WeatherScene _mapWeatherConditionToWeatherScene(int condition) {
    if (condition < 300) {
      return WeatherScene.stormy; // Thunderstorm
    } else if (condition < 400) {
      return WeatherScene.rainyOvercast; // Light rain
    } else if (condition < 600) {
      return WeatherScene.rainyOvercast; // Rain
    } else if (condition < 700) {
      return WeatherScene.snowfall; // Snow
    } else if (condition < 800) {
      return WeatherScene.showerSleet; // Mist, Fog, Haze
    } else if (condition == 800) {
      return WeatherScene.scorchingSun; // Clear sky
    } else if (condition <= 804) {
      return WeatherScene.snowfall; // Cloudy
    } else {
      return WeatherScene.weatherEvery; // Default to cloudy
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http
          .get(Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$_latitude&lon=$_longitude&appid=$apikey'))
          .timeout(Duration(seconds: 10)); // Add timeout duration

      if (response.statusCode == 200) {
        String data = response.body;
        var decodedData = jsonDecode(data);
        setState(() {
          int weatherCondition = decodedData['weather'][0]['id']; // Weather ID
          _weatherType = _mapWeatherConditionToWeatherScene(weatherCondition);
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch weather data: Timeout'),
        ),
      );
    } on SocketException catch (e) {
      print('Socket Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch weather data: Network issue'),
        ),
      );
    } catch (e) {
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch weather data: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableHome(
      appBarColor: CustomColors.primaryColor,
      title: Text(
        "$homeName",
        style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: CustomColors.backgroundColor),
      ),
      headerWidget: _buildHeaderWidget(),
      body: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InfoCard(
            isExpanded: _isExpanded,
            solarRoofPower: solarRoofPower,
            homeUsage: homeUsage,
            powerwallPower: powerwallPower,
            gridUsage: gridUsage,
            powerwallPercentage: powerwallPercentage,
            onExpandToggle: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        PieChartCard(
          solarRoofPower: solarRoofPower,
          homeUsage: homeUsage,
          powerwallPower: powerwallPower,
          gridUsage: gridUsage,
        ),
        FrequentlyUsedDevices(
          frequentlyUsedDevices: _frequentlyUsedDevices,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Family',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.primaryColor,
                ),
                textAlign: TextAlign.left,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyFamily()),
                  );
                },
                icon: Icon(Icons.family_restroom_rounded),
              ),
            ],
          ),
        ),
        FamilyRow(members: _members),
      ],
      fullyStretchable: true,
      expandedBody: _buildHeaderWidget(),
      stretchTriggerOffset: 100,
    );
  }

  Widget _buildHeaderWidget() {
    return Stack(
      children: [
        Positioned.fill(
          child: _weatherType.sceneWidget,
          // child: WeatherScene.rainyOvercast.sceneWidget,
        ),
        Padding(
          padding: const EdgeInsets.all(25.0),
          child: AnimatedBuilder(
            animation: _bobbingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bobbingAnimation.value),
                child: child,
              );
            },
            child: Stack(
              children: [
                Image.asset(
                  'assets/Images/dwellerHouse.png',
                  width: 600,
                  height: 600,
                ),
                // Text(
                //   'Relax!, Everything looks good!',
                //   style: TextStyle(
                //     color: CustomColors.primaryColor,
                //     fontSize: 20.0,
                //     fontWeight: FontWeight.bold,
                //     fontFamily: 'Tajawal-Bold',
                //     shadows: [
                //       Shadow(
                //         offset: Offset(1.0, 1.0),
                //         blurRadius: 5.0,
                //         color: Colors.black.withOpacity(0.5),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 32.0,
          left: 16.0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              homeName,
              style: TextStyle(
                  color: CustomColors.primaryColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal-Bold',
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ]),
            ),
          ),
        ),
        Positioned(
          top: 32.0,
          right: 16.0,
          child: Image.asset(
            'assets/Images/LogoHouse.png', // Path to your logo image
            height: 40.0,
          ),
        ),
      ],
    );
  }
}

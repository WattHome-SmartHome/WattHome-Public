import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _city = "";
  String _temperature = "";
  String _weatherDescription = "";
  double _latitude = 0.0;
  double _longitude = 0.0;
  String? apikey = ''; // Replace with your actual API Key
  WeatherScene _weatherType = WeatherScene.weatherEvery;

  @override
  void initState() {
    super.initState();
    _getLocation();
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
    print("WEATHER CODE::: $condition");
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
    print(
        "LATITUDE:----------------------------------------------------- $_latitude");
    print(
        "LONGITUDE:------------------------------------------------------ $_longitude");
    try {
      http.Response response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$_latitude&lon=$_longitude&appid=$apikey'));
      print(response.statusCode);
      if (response.statusCode == 200) {
        String data = response.body;
        var decodedData = jsonDecode(data);
        setState(() {
          _city = decodedData['name'];
          double temp = decodedData['main']['temp'];
          _temperature = (temp - 273.15).toStringAsFixed(1) + '°C';
          _weatherDescription = decodedData['weather'][0]['description'];

          int weatherCondition = decodedData['weather'][0]['id']; // Weather ID
          _weatherType = _mapWeatherConditionToWeatherScene(weatherCondition);
        });
      }
    } catch (e) {
      if (e is http.ClientException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch weather data: $e'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 75,
              child: Stack(
                children: [
                  //WeatherScene.frosty.sceneWidget,
                  _weatherType.sceneWidget,
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _city,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$_temperature $_weatherDescription",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

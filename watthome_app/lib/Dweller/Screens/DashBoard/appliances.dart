import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';




class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Appliances(),
    );
  }
}


class Appliances extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My House", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.add))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnergyUsageCard(),
            SizedBox(height: 20),
            Text("Frequently Used", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  DeviceCard("Smart TV", Icons.tv, true),
                  DeviceCard("Air Conditioner", Icons.ac_unit, true),
                  DeviceCard("Air Purifier", Icons.air, false),
                  DeviceCard("Smart Light", Icons.lightbulb, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEnergyUsageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My House", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("5000 KwH", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(height: 150, child: LineChart(_buildChart())),
        ],
      ),
    );
  }


  LineChartData _buildChart() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(0, 20), FlSpot(1, 30), FlSpot(2, 50), FlSpot(3, 40), FlSpot(4, 60), FlSpot(5, 55),
          ],
          isCurved: true,
          color: Colors.blue,
          dotData: FlDotData(show: false),
        )
      ],
    );
  }
}


class DeviceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool initialState;


  DeviceCard(this.title, this.icon, this.initialState);


  @override
  _DeviceCardState createState() => _DeviceCardState();
}


class _DeviceCardState extends State<DeviceCard> {
  late bool isOn;


  @override
  void initState() {
    super.initState();
    isOn = widget.initialState;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 30, color: isOn ? Colors.blue : Colors.grey),
            SizedBox(height: 5),
            Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Switch(value: isOn, onChanged: (value) => setState(() => isOn = value)),
          ],
        ),
      ),
    );
  }
}






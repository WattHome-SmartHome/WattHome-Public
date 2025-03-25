import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartCard extends StatelessWidget {
  final double solarRoofPower;
  final double homeUsage;
  final double powerwallPower;
  final double gridUsage;

  const PieChartCard({
    required this.solarRoofPower,
    required this.homeUsage,
    required this.powerwallPower,
    required this.gridUsage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solar Roof: ${solarRoofPower.toStringAsFixed(1)} kW',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 241, 143, 1),
                      fontWeight: FontWeight.bold,
                    )),
                Text('Home Usage: ${homeUsage.toStringAsFixed(1)} kW',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 153, 194, 77),
                      fontWeight: FontWeight.bold,
                    )),
                Text('Powerwall: ${powerwallPower.toStringAsFixed(1)} kW',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 65, 187, 217),
                      fontWeight: FontWeight.bold,
                    )),
                Text('Grid Usage: ${gridUsage.toStringAsFixed(1)} kW',
                    style: TextStyle(
                      color: const Color(0xFF006E90),
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            SizedBox(width: 16),
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      showTitle: false,
                      value: solarRoofPower,
                      color: const Color.fromARGB(255, 241, 143, 1),
                    ),
                    PieChartSectionData(
                      showTitle: false,
                      value: homeUsage,
                      color: const Color.fromARGB(255, 153, 194, 77),
                    ),
                    PieChartSectionData(
                      showTitle: false,
                      value: powerwallPower,
                      color: const Color.fromARGB(255, 65, 187, 217),
                    ),
                    PieChartSectionData(
                      showTitle: false,
                      value: gridUsage,
                      color: const Color(0xFF006E90),
                    ),
                  ],
                  sectionsSpace: 3,
                  centerSpaceRadius:
                      40, // Increase the center space radius to make the chart thinner
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

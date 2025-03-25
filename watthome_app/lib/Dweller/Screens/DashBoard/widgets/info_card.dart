import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';

class InfoCard extends StatelessWidget {
  final bool isExpanded;
  final double solarRoofPower;
  final double homeUsage;
  final double powerwallPower;
  final double gridUsage;
  final double powerwallPercentage;
  final VoidCallback onExpandToggle;

  const InfoCard({
    required this.isExpanded,
    required this.solarRoofPower,
    required this.homeUsage,
    required this.powerwallPower,
    required this.gridUsage,
    required this.powerwallPercentage,
    required this.onExpandToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalPower = solarRoofPower + homeUsage + powerwallPower + gridUsage;
    return Card(
      color: Colors.transparent,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconWithIndicator(
                tag: 'solar',
                icon: Icons.wb_sunny,
                percentage:
                    totalPower > 0 ? (solarRoofPower / totalPower) * 100 : 0,
                color: const Color.fromARGB(255, 241, 143, 1),
              ),
              _buildIconWithIndicator(
                tag: 'home',
                icon: Icons.home,
                percentage: totalPower > 0 ? (homeUsage / totalPower) * 100 : 0,
                color: const Color.fromARGB(255, 153, 194, 77),
              ),
              _buildIconWithIndicator(
                tag: 'powerwall',
                icon: Icons.battery_charging_full,
                percentage:
                    totalPower > 0 ? (powerwallPower / totalPower) * 100 : 0,
                color: const Color.fromARGB(255, 65, 187, 217),
              ),
              _buildIconWithIndicator(
                tag: 'grid',
                icon: Icons.electrical_services,
                percentage: totalPower > 0 ? (gridUsage / totalPower) * 100 : 0,
                color: const Color(0xFF006E90),
              ),
              IconButton(
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: onExpandToggle,
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Divider(),
                  _buildInfoRow(
                    tag: 'solar',
                    icon: Icons.wb_sunny,
                    text: "$solarRoofPower kW - SOLAR ROOF",
                    percentage: totalPower > 0
                        ? (solarRoofPower / totalPower) * 100
                        : 0,
                    color: const Color.fromARGB(255, 241, 143, 1),
                  ),
                  Divider(),
                  _buildInfoRow(
                    tag: 'home',
                    icon: Icons.home,
                    text: "$homeUsage kW - HOME",
                    percentage:
                        totalPower > 0 ? (homeUsage / totalPower) * 100 : 0,
                    color: const Color.fromARGB(255, 153, 194, 77),
                  ),
                  Divider(),
                  _buildInfoRow(
                    tag: 'powerwall',
                    icon: Icons.battery_charging_full,
                    text:
                        "$powerwallPower kW ${powerwallPercentage.toInt()}% POWERWALL-3",
                    percentage: totalPower > 0
                        ? (powerwallPower / totalPower) * 100
                        : 0,
                    color: const Color.fromARGB(255, 65, 187, 217),
                  ),
                  Divider(),
                  _buildInfoRow(
                    tag: 'grid',
                    icon: Icons.electrical_services,
                    text: "$gridUsage kW GRID",
                    percentage:
                        totalPower > 0 ? (gridUsage / totalPower) * 100 : 0,
                    color: const Color(0xFF006E90),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithIndicator(
      {required String tag,
      required IconData icon,
      required double percentage,
      required Color color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4.0,
            backgroundColor: CustomColors.tileColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Icon(icon, size: 24.0),
      ],
    );
  }

  Widget _buildInfoRow(
      {required String tag,
      required IconData icon,
      required String text,
      required double percentage,
      required Color color}) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 4.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, size: 24.0),
          ],
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.black, fontSize: 12.0),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class EnergyFlowCard extends StatelessWidget {
  final double solarPanelWatts;
  final double solarBatteryKwh;
  final double gridKwh;

  const EnergyFlowCard({
    super.key,
    required this.solarPanelWatts,
    required this.solarBatteryKwh,
    required this.gridKwh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      elevation: 1,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Energy Flow",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 10),
            _buildFlowRow(
                icon: Icons.wb_sunny,
                label: 'Solar Panel (estimate)',
                value: '${solarPanelWatts.toInt()} watts'),
            _buildFlowRow(
                icon: Icons.battery_charging_full,
                label: 'Solar battery',
                value: '${solarBatteryKwh.toInt()} kwh'),
            _buildFlowRow(
                icon: Icons.grid_on,
                label: 'Grid (estimate)',
                value: '${gridKwh.toInt()} kwh'),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600),
              const SizedBox(width: 8.0),
              Text(label, style: const TextStyle(fontSize: 14))
            ],
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

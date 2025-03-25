import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:watthome_app/Models/enegryReportModel.dart';

class EnergyChart extends StatelessWidget {
  final EnergyData energyData;

  const EnergyChart({super.key, required this.energyData});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
              ),
              leftTitles: AxisTitles(
                sideTitles: _leftTitles,
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                bottom: BorderSide(color: Colors.grey),
                left: BorderSide(color: Colors.grey),
              ),
            ),
            lineBarsData: [
              _getLineChartBar(
                energyData.monthlyUsages
                    .asMap()
                    .entries
                    .map((entry) =>
                        FlSpot(entry.key.toDouble(), entry.value.kwh))
                    .toList(),
                Colors.blue,
                'Energy Used in Home',
              ),
              _getLineChartBar(
                energyData.monthlyUsages
                    .asMap()
                    .entries
                    .map((entry) =>
                        FlSpot(entry.key.toDouble(), energyData.gridKwh))
                    .toList(),
                Colors.red,
                'Energy Used from Grid',
              ),
              _getLineChartBar(
                energyData.monthlyUsages
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(
                        entry.key.toDouble(), energyData.solarPanelWatts))
                    .toList(),
                Colors.green,
                'Energy Generated',
              ),
            ],
            minY: 0,
            maxY: 90,
          ),
        ),
      ),
    );
  }

  LineChartBarData _getLineChartBar(
      List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      belowBarData: BarAreaData(show: false),
      dotData: const FlDotData(show: false),
      // Add label to the chart bar
    );
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 25,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < energyData.monthlyUsages.length) {
            final monthYear = energyData.monthlyUsages[index].monthYear;
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(monthYear, style: const TextStyle(fontSize: 12)),
            );
          }
          return Container();
        },
      );

  SideTitles get _leftTitles => SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 9,
        getTitlesWidget: (value, meta) {
          return Text(value.toString(), textAlign: TextAlign.right);
        },
      );
}

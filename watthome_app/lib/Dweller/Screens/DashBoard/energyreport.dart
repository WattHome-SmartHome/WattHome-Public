import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class EnergyReportScreen extends StatefulWidget {
    @override
    _EnergyReportScreenState createState() => _EnergyReportScreenState();
}


class _EnergyReportScreenState extends State<EnergyReportScreen> {
    String selectedTimeFrame = 'This Year';
    final List<String> timeFrames = ['This Year', 'Last Year', 'This Month', 'This Week', 'Today'];


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFF7F1E9), // Updated background color
            appBar: AppBar(
                title: const Text(
                    'My House',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                    ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {},
                ),
            ),
            body: SingleChildScrollView( // Wrap body in SingleChildScrollView for better scrolling behavior
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    const Text(
                                        'Total used: 20 Kwh',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    DropdownButton<String>(
                                        value: selectedTimeFrame,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                        onChanged: (String? newValue) {
                                            setState(() {
                                                selectedTimeFrame = newValue!;
                                            });
                                        },
                                        items: timeFrames.map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                                            );
                                        }).toList(),
                                    ),
                                ],
                            ),
                            SizedBox(
                                height: 200, // Smaller height for the graph
                                child: LineChart(
                                    LineChartData(
                                        gridData: FlGridData(
                                            show: true, // Enable grid lines
                                            drawHorizontalLine: true, // Horizontal grid lines
                                            drawVerticalLine: true, // Vertical grid lines
                                            getDrawingHorizontalLine: (value) {
                                                return FlLine(
                                                    color: Colors.black12, // Color for horizontal grid lines
                                                    strokeWidth: 0.8,
                                                );
                                            },
                                            getDrawingVerticalLine: (value) {
                                                return FlLine(
                                                    color: Colors.black12, // Color for vertical grid lines
                                                    strokeWidth: 0.8,
                                                );
                                            },
                                        ),
                                        titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 50, // Increased reserved size for better visibility
                                                    getTitlesWidget: (value, meta) {
                                                        if (value % 20 == 0) { // Display values every 20 units
                                                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
                                                        }
                                                        return const Text('');
                                                    },
                                                ),
                                            ),
                                            bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: true,
                                                    interval: 1,
                                                    getTitlesWidget: (value, meta) {
                                                        switch (value.toInt()) {
                                                            case 1:
                                                                return const Text('Jan');
                                                            case 2:
                                                                return const Text('Feb');
                                                            case 3:
                                                                return const Text('Mar');
                                                            case 4:
                                                                return const Text('Apr');
                                                            case 5:
                                                                return const Text('May');
                                                            case 6:
                                                                return const Text('Jun');
                                                            default:
                                                                return const Text('');
                                                        }
                                                    },
                                                ),
                                            ),
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border.all(color: Colors.black),
                                        ),
                                        lineBarsData: [
                                            LineChartBarData(
                                                spots: [
                                                    FlSpot(1, 10),
                                                    FlSpot(2, 50),
                                                    FlSpot(3, 30),
                                                    FlSpot(4, 70),
                                                    FlSpot(5, 90),
                                                    FlSpot(6, 85),
                                                ],
                                                isCurved: true,
                                                color: Colors.blue,
                                                dotData: FlDotData(show: false),
                                                belowBarData: BarAreaData(show: false),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                        Text(
                                            'Energy Flow',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 10),
                                        Text('☀️ Solar Panel: 30 watts', style: TextStyle(fontSize: 14)),
                                        Text('🔋 Solar Battery: 544 kWh', style: TextStyle(fontSize: 14)),
                                        Text('⚡ Grid: 544 kWh', style: TextStyle(fontSize: 14)),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                ),
                                child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    child: Text(
                                        'Download Report',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 20), // Ensure bottom spacing is good
                        ],
                    ),
                ),
            ),
        );
    }
}


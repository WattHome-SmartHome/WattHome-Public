import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Models/enegryReportModel.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/EnergyReport/energyFlowCard.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/EnergyReport/energyReportChart.dart';

class EnergyReport extends StatefulWidget {
  const EnergyReport({super.key});

  @override
  _EnergyReportState createState() => _EnergyReportState();
}

class _EnergyReportState extends State<EnergyReport> {
  final energyData = EnergyData(
    monthlyUsages: [
      EnergyUsage(date: DateTime(2024, 1, 1), kwh: 10),
      EnergyUsage(date: DateTime(2024, 2, 1), kwh: 48),
      EnergyUsage(date: DateTime(2024, 3, 1), kwh: 18),
      EnergyUsage(date: DateTime(2024, 4, 1), kwh: 56),
      EnergyUsage(date: DateTime(2024, 5, 1), kwh: 65),
      EnergyUsage(date: DateTime(2024, 6, 1), kwh: 80)
    ],
    solarPanelWatts: 30,
    solarBatteryKwh: 544,
    gridKwh: 544,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("My House", style: TextStyle(color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey.shade100,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      backgroundColor: Colors.grey.shade100,
      body: ListView(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
                "Total used: ${energyData.totalUsedKwh.toStringAsFixed(0)} Kwh",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ),
          EnergyChart(energyData: energyData),
          EnergyFlowCard(
            solarPanelWatts: energyData.solarPanelWatts,
            solarBatteryKwh: energyData.solarBatteryKwh,
            gridKwh: energyData.gridKwh,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primaryColor),
                onPressed: () {},
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Download Report',
                      style: TextStyle(color: Colors.white)),
                )),
          )
        ],
      ),
    );
  }
}

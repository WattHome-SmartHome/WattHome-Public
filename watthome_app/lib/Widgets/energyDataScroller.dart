import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';

class EnergyDataScroller extends StatelessWidget {
  final double chartWidth;
  final List<EnergyDataPoint> data;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;

  const EnergyDataScroller({
    super.key,
    required this.chartWidth,
    required this.data,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      child: Container(
        width: 50, // Increased width for pill shape
        height: 20, // Height for pill shape
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15), // Pill shape
          border: Border.all(color: CustomColors.primaryColor, width: 2),
        ),
        child: const Center(
          child: Icon(
            Icons.code_sharp,
            color: CustomColors.primaryColor,
            size: 15,
          ),
        ),
      ),
    );
  }
}

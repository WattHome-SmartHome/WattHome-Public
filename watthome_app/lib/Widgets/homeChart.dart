import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Models/energyDashBoardModel.dart';
import 'package:watthome_app/Widgets/energyDataScroller.dart';

class EnergyUsageChart extends StatefulWidget {
  final List<EnergyDataPoint> data;
  final DateTime currentTime;
  final String selectedTimeRange;

  const EnergyUsageChart({
    super.key,
    required this.data,
    required this.currentTime,
    required this.selectedTimeRange,
  });

  @override
  _EnergyUsageChartState createState() => _EnergyUsageChartState();
}

class _EnergyUsageChartState extends State<EnergyUsageChart> {
  double _calculateMaxValue() {
    double max = 0;
    for (var point in widget.data) {
      if (point.energyUsage > max) {
        max = point.energyUsage;
      }
    }
    return max * 1.3;
  }

  double _calculateMinValue() {
    double min = 0;
    for (var point in widget.data) {
      if (point.energyUsage < min) {
        min = point.energyUsage;
      }
    }
    return min * 0.8;
  }

  double _dragPosition = 0;
  int _selectedDataIndex = -1;
  double _chartWidth = 0;
  double _tempDragPosition = 0;
  bool _layoutBuilt = false;

  @override
  void initState() {
    super.initState();
    // Initially position the draggable marker at the center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerDragPosition();
      }
    });
  }

  void _centerDragPosition() {
    // Calculate the initial index that is closest to the center of the chart
    int centerIndex = (widget.data.length / 2).round();
    if (centerIndex >= widget.data.length) {
      centerIndex = widget.data.length - 1;
    }
    // Calculate the x position that corresponds with the center of the chart.

    final initialDragPosition =
        centerIndex * (_chartWidth / (widget.data.length - 1));

    setState(() {
      _dragPosition = initialDragPosition;
      _tempDragPosition = initialDragPosition;
      _selectedDataIndex = centerIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _chartWidth = constraints.maxWidth;
      _layoutBuilt = true;
      return Stack(
        children: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineBarsData: _lineBarsData(),
                    minY: _calculateMinValue(),
                    maxY: _calculateMaxValue(),
                    titlesData: _titlesData(),
                    gridData: _gridData(),
                    borderData: _borderData(),
                    lineTouchData: const LineTouchData(
                      enabled: false, // This disables the default tooltip
                    ),
                  ),
                ),
              ),
              Container(
                height: 50,
                color: Colors.transparent,
              ),
            ],
          ),
          _buildHighlightVerticalLine(),
          Positioned(
            left: _tempDragPosition - 25, // Adjusted to center the button
            bottom: 40, // Positioned at the bottom border of the chart
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  if (_layoutBuilt) {
                    _tempDragPosition += details.delta.dx;
                    _tempDragPosition = _tempDragPosition.clamp(0, _chartWidth);
                    int index = (_tempDragPosition /
                            (_chartWidth / (widget.data.length - 1)))
                        .round();
                    index = index.clamp(0, widget.data.length - 1);
                    _selectedDataIndex = index;
                  }
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _dragPosition = _tempDragPosition;
                  int index =
                      (_dragPosition / (_chartWidth / (widget.data.length - 1)))
                          .round();
                  index = index.clamp(0, widget.data.length - 1);
                  _dragPosition =
                      index * (_chartWidth / (widget.data.length - 1));
                  _selectedDataIndex = index;
                  _tempDragPosition = _dragPosition;
                });
              },
              child: EnergyDataScroller(
                chartWidth: _chartWidth,
                data: widget.data,
                onDragUpdate: (details) {
                  setState(() {
                    if (_layoutBuilt) {
                      _tempDragPosition += details.delta.dx;
                      _tempDragPosition =
                          _tempDragPosition.clamp(0, _chartWidth);
                      int index = (_tempDragPosition /
                              (_chartWidth / (widget.data.length - 1)))
                          .round();
                      index = index.clamp(0, widget.data.length - 1);
                      _selectedDataIndex = index;
                    }
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    _dragPosition = _tempDragPosition;
                    int index = (_dragPosition /
                            (_chartWidth / (widget.data.length - 1)))
                        .round();
                    index = index.clamp(0, widget.data.length - 1);
                    _dragPosition =
                        index * (_chartWidth / (widget.data.length - 1));
                    _selectedDataIndex = index;
                    _tempDragPosition = _dragPosition;
                  });
                },
              ),
            ),
          ),
          Positioned(
            left: _tempDragPosition - 50,
            bottom: 80,
            child: _selectedDataIndex != -1 &&
                    _selectedDataIndex < widget.data.length
                ? Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      '${DateFormat('MMM dd, HH:mm').format(widget.data[_selectedDataIndex].time)}\n${widget.data[_selectedDataIndex].energyUsage.toStringAsFixed(2)} KWh',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : Container(),
          ),
        ],
      );
    });
  }

  List<LineChartBarData> _lineBarsData() {
    return [
      _getLineChartBar(
          widget.data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.energyUsage))
              .toList(),
          CustomColors.primaryColor),
    ];
  }

  LineChartBarData _getLineChartBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withAlpha((0.6 * 255).toInt()),
            color.withAlpha((0.0 * 255).toInt()),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  FlTitlesData _titlesData() {
    return const FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _gridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) => FlLine(
        color: CustomColors.textAccentColor.withOpacity(0.2),
        strokeWidth: 0.8,
      ),
    );
  }

  FlBorderData _borderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
            color: const Color.fromARGB(255, 39, 80, 84).withOpacity(0.5),
            width: 1.5),
        left: const BorderSide(color: Colors.transparent),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHighlightVerticalLine() {
    int index = _selectedDataIndex;
    if (index != -1) {
      return Positioned(
        left: _tempDragPosition - 1, // Adjusted to align the vertical line
        top: 0,
        bottom: 50, // Adjusted to align with the chart height
        child: Container(
          width: 1.5,
          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
        ),
      );
    }
    return Container();
  }
}

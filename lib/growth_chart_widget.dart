/* import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'child_model.dart'; // For Child class or relevant model import

class GrowthChartWidget extends StatelessWidget {
  final Map<int, double> weightData;
  final Map<int, DateTime> dayToDateMap;
  final Map<String, List<FlSpot>> whoStandardLines;
  final bool isKgUnit;
  final Map<int, Map<String, dynamic>> dayData;
  final Child? child;

  const GrowthChartWidget({
    Key? key,
    required this.weightData,
    required this.dayToDateMap,
    required this.whoStandardLines,
    required this.isKgUnit,
    required this.dayData,
    required this.child,
  }) : super(key: key);

  Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 400,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 8,
              offset: Offset(2, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No weight data available yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Prepare and sort data points with dates
    List<MapEntry<int, double>> sortedEntries = [];
    for (var entry in weightData.entries) {
      if (dayToDateMap.containsKey(entry.key)) {
        sortedEntries.add(entry);
      }
    }
    sortedEntries.sort(
      (a, b) => dayToDateMap[a.key]!.compareTo(dayToDateMap[b.key]!),
    );

    List<FlSpot> spots = [];
    List<Color> spotColors = [];

    for (var entry in sortedEntries) {
      final dayNumber = entry.key;
      final date = dayToDateMap[dayNumber]!;
      final birthDate = child!.dateOfBirth;
      final daysSinceBirth = date.difference(birthDate).inDays;

      final weightValue = entry.value / 1000; // Always in kg for chart

      spots.add(FlSpot(daysSinceBirth.toDouble(), weightValue));

      Color spotColor = const Color(0xFF1873EA);
      if (dayData.containsKey(dayNumber) &&
          dayData[dayNumber]!.containsKey('color')) {
        spotColor = hexToColor(dayData[dayNumber]!['color']);
      }
      spotColors.add(spotColor);
    }

    if (spots.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        child: Center(
          child: Text(
            'No weight data with dates available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final minX = spots.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    double finalMinY = minY;
    double finalMaxY = maxY;

    // Adjust y-axis range based on WHO standard lines
    if (whoStandardLines.isNotEmpty) {
      for (var line in whoStandardLines.values) {
        if (line.isNotEmpty) {
          var filteredLine =
              line
                  .where(
                    (spot) => spot.x >= (minX - 30) && spot.x <= (maxX + 60),
                  )
                  .toList();
          if (filteredLine.isNotEmpty) {
            final lineMinY = filteredLine
                .map((e) => e.y)
                .reduce((a, b) => a < b ? a : b);
            final lineMaxY = filteredLine
                .map((e) => e.y)
                .reduce((a, b) => a > b ? a : b);
            finalMinY = finalMinY < lineMinY ? finalMinY : lineMinY;
            finalMaxY = finalMaxY > lineMaxY ? finalMaxY : lineMaxY;
          }
        }
      }
    }

    final yInterval = (finalMaxY - finalMinY) / 4;
    final xInterval = (maxX - minX) / 5;

    return Container(
      width: double.infinity,
      height: 300,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(2, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: 30,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
            getDrawingVerticalLine:
                (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return SizedBox();
                  final birthDate = child!.dateOfBirth;
                  final date = birthDate.add(Duration(days: value.toInt()));
                  final month = DateFormat('MMM').format(date);
                  final day = DateFormat('d').format(date);
                  return SideTitleWidget(
                    angle: 0,
                    space: 8,
                    meta: meta,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          month,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                interval: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return SizedBox();

                  // Show only integer values if kg unit
                  if (isKgUnit && value.round() != value) return SizedBox();

                  String valueText =
                      isKgUnit
                          ? value.toInt().toString()
                          : value.toInt().toString();

                  return SideTitleWidget(
                    angle: 0,
                    space: 8,
                    meta: meta,
                    child: Text(
                      valueText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
                interval: isKgUnit ? 1.0 : 1000,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: minX - 5,
          maxX: maxX + 30,
          minY: finalMinY,
          maxY: finalMaxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  for (var entry in whoStandardLines.entries) {
                    final lineType = entry.key;
                    final line = entry.value;
                    bool isWHOLine = line.any(
                      (s) =>
                          (s.x - spot.x).abs() < 0.1 &&
                          (s.y - spot.y).abs() < 0.1,
                    );
                    if (isWHOLine) {
                      String lineLabel =
                          {
                            'minus3SD': "SD -3",
                            'minus2SD': "SD -2",
                            'median': "WHO Median",
                            'plus2SD': "SD +2",
                            'plus3SD': "SD +3",
                          }[lineType] ??
                          lineType;

                      String weightText = '${spot.y.toStringAsFixed(1)} kg';

                      return LineTooltipItem(
                        '$lineLabel: $weightText',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  }

                  // Not WHO line - find dayNumber & display info
                  int dayNumber = -1;
                  for (var entry in sortedEntries) {
                    final days =
                        dayToDateMap[entry.key]!
                            .difference(child!.dateOfBirth)
                            .inDays;
                    final weight = entry.value / 1000;
                    if ((days.toDouble() - spot.x).abs() < 0.1 &&
                        (weight - spot.y).abs() < 0.1) {
                      dayNumber = entry.key;
                      break;
                    }
                  }

                  if (dayNumber > 0) {
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                    ).format(dayToDateMap[dayNumber]!);
                    String? category = "Normal";
                    if (dayData.containsKey(dayNumber) &&
                        dayData[dayNumber]!.containsKey('category')) {
                      switch (dayData[dayNumber]!['category']) {
                        case 'minus3SD':
                          category = "Severely Underweight";
                          break;
                        case 'minus2SD':
                          category = "Underweight";
                          break;
                        case 'normal':
                          category = "Normal";
                          break;
                        case 'plus2SD':
                          category = "Overweight";
                          break;
                        case 'plus3SD':
                          category = "Extremely Overweight";
                          break;
                      }
                    }
                    String weightText = '${spot.y.toStringAsFixed(2)} kg';

                    return LineTooltipItem(
                      'Day $dayNumber\n$dateStr\n$weightText\nStatus: $category',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  return LineTooltipItem(
                    'Unknown point',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1873EA),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color dotColor =
                      index < spotColors.length
                          ? spotColors[index]
                          : const Color(0xFF1873EA);
                  return FlDotCirclePainter(
                    radius: 5,
                    color: dotColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1873EA).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Make sure to import your Child model or relevant class here
import 'child_model.dart';

class GrowthChartWidget extends StatelessWidget {
  final Map<int, double> weightData;
  final Map<int, DateTime> dayToDateMap;
  final Map<String, List<FlSpot>> whoStandardLines;
  final bool isKgUnit;
  final Map<int, Map<String, dynamic>> dayData;
  final Child? child;

  const GrowthChartWidget({
    Key? key,
    required this.weightData,
    required this.dayToDateMap,
    required this.whoStandardLines,
    required this.isKgUnit,
    required this.dayData,
    required this.child,
  }) : super(key: key);

  Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 400,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 8,
              offset: Offset(2, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No weight data available yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Prepare and sort data points with dates
    List<MapEntry<int, double>> sortedEntries = [];
    for (var entry in weightData.entries) {
      if (dayToDateMap.containsKey(entry.key)) {
        sortedEntries.add(entry);
      }
    }
    sortedEntries.sort(
      (a, b) => dayToDateMap[a.key]!.compareTo(dayToDateMap[b.key]!),
    );

    List<FlSpot> spots = [];
    List<Color> spotColors = [];

    for (var entry in sortedEntries) {
      final dayNumber = entry.key;
      final date = dayToDateMap[dayNumber]!;
      final birthDate = child!.dateOfBirth;
      final daysSinceBirth = date.difference(birthDate).inDays;

      final weightValue = entry.value / 1000; // Always in kg for chart

      spots.add(FlSpot(daysSinceBirth.toDouble(), weightValue));

      Color spotColor = const Color(0xFF1873EA);
      if (dayData.containsKey(dayNumber) &&
          dayData[dayNumber]!.containsKey('color')) {
        spotColor = hexToColor(dayData[dayNumber]!['color']);
      }
      spotColors.add(spotColor);
    }

    if (spots.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        child: Center(
          child: Text(
            'No weight data with dates available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final minX = spots.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    double finalMinY = minY;
    double finalMaxY = maxY;

    // Adjust y-axis range based on WHO standard lines
    if (whoStandardLines.isNotEmpty) {
      for (var line in whoStandardLines.values) {
        if (line.isNotEmpty) {
          var filteredLine =
              line
                  .where(
                    (spot) => spot.x >= (minX - 30) && spot.x <= (maxX + 60),
                  )
                  .toList();
          if (filteredLine.isNotEmpty) {
            final lineMinY = filteredLine
                .map((e) => e.y)
                .reduce((a, b) => a < b ? a : b);
            final lineMaxY = filteredLine
                .map((e) => e.y)
                .reduce((a, b) => a > b ? a : b);
            finalMinY = finalMinY < lineMinY ? finalMinY : lineMinY;
            finalMaxY = finalMaxY > lineMaxY ? finalMaxY : lineMaxY;
          }
        }
      }
    }

    final yInterval = (finalMaxY - finalMinY) / 4;
    final xInterval = (maxX - minX) / 5;

    // Generate LineChartBarData for WHO lines
    final whoLineBars =
        whoStandardLines.entries.map((entry) {
          Color lineColor;
          double lineWidth = 2;

          switch (entry.key) {
            case 'median':
              lineColor = Colors.green;
              lineWidth = 3;
              break;
            case 'minus3SD':
            case 'plus3SD':
              lineColor = Colors.red;
              break;
            case 'minus2SD':
            case 'plus2SD':
              lineColor = Colors.orange;
              break;
            default:
              lineColor = Colors.grey;
          }

          return LineChartBarData(
            spots: entry.value,
            isCurved: true,
            color: lineColor,
            barWidth: lineWidth,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false), // no dots on WHO lines
            belowBarData: BarAreaData(show: false),
          );
        }).toList();

    return Container(
      width: double.infinity,
      height: 300,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(2, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: 30,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
            getDrawingVerticalLine:
                (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return SizedBox();
                  final birthDate = child!.dateOfBirth;
                  final date = birthDate.add(Duration(days: value.toInt()));
                  final month = DateFormat('MMM').format(date);
                  final day = DateFormat('d').format(date);
                  return SideTitleWidget(
                    angle: 0,
                    space: 8,
                    meta: meta,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          month,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                interval: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return SizedBox();

                  // Show only integer values if kg unit
                  if (isKgUnit && value.round() != value) return SizedBox();

                  String valueText =
                      isKgUnit
                          ? value.toInt().toString()
                          : value.toInt().toString();

                  return SideTitleWidget(
                    angle: 0,
                    space: 8,
                    meta: meta,
                    child: Text(
                      valueText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
                interval: isKgUnit ? 1.0 : 1000,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: minX - 5,
          maxX: maxX + 30,
          minY: finalMinY,
          maxY: finalMaxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  for (var entry in whoStandardLines.entries) {
                    final lineType = entry.key;
                    final line = entry.value;
                    bool isWHOLine = line.any(
                      (s) =>
                          (s.x - spot.x).abs() < 0.1 &&
                          (s.y - spot.y).abs() < 0.1,
                    );
                    if (isWHOLine) {
                      String lineLabel =
                          {
                            'minus3SD': "SD -3",
                            'minus2SD': "SD -2",
                            'median': "WHO Median",
                            'plus2SD': "SD +2",
                            'plus3SD': "SD +3",
                          }[lineType] ??
                          lineType;

                      String weightText = '${spot.y.toStringAsFixed(1)} kg';

                      return LineTooltipItem(
                        '$lineLabel: $weightText',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  }

                  // Not WHO line - find dayNumber & display info
                  int dayNumber = -1;
                  for (var entry in sortedEntries) {
                    final days =
                        dayToDateMap[entry.key]!
                            .difference(child!.dateOfBirth)
                            .inDays;
                    final weight = entry.value / 1000;
                    if ((days.toDouble() - spot.x).abs() < 0.1 &&
                        (weight - spot.y).abs() < 0.1) {
                      dayNumber = entry.key;
                      break;
                    }
                  }

                  if (dayNumber > 0) {
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                    ).format(dayToDateMap[dayNumber]!);
                    String? category = "Normal";
                    if (dayData.containsKey(dayNumber) &&
                        dayData[dayNumber]!.containsKey('category')) {
                      switch (dayData[dayNumber]!['category']) {
                        case 'minus3SD':
                          category = "Severely Underweight";
                          break;
                        case 'minus2SD':
                          category = "Underweight";
                          break;
                        case 'normal':
                          category = "Normal";
                          break;
                        case 'plus2SD':
                          category = "Overweight";
                          break;
                        case 'plus3SD':
                          category = "Extremely Overweight";
                          break;
                      }
                    }
                    String weightText = '${spot.y.toStringAsFixed(2)} kg';

                    return LineTooltipItem(
                      'Day $dayNumber\n$dateStr\n$weightText\nStatus: $category',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  return LineTooltipItem(
                    'Unknown point',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          lineBarsData: [
            // Child's weight line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1873EA),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color dotColor =
                      index < spotColors.length
                          ? spotColors[index]
                          : const Color(0xFF1873EA);
                  return FlDotCirclePainter(
                    radius: 5,
                    color: dotColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1873EA).withOpacity(0.1),
              ),
            ),

            // WHO standard lines
            ...whoLineBars,
          ],
        ),
      ),
    );
  }
}

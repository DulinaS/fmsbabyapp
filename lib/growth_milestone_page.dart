/* 
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GrowthMilestonePage extends StatefulWidget {
  const GrowthMilestonePage({super.key});

  @override
  State<GrowthMilestonePage> createState() => _GrowthMilestonePageState();
}

class _GrowthMilestonePageState extends State<GrowthMilestonePage> {
  int selectedDay = 4;
  final ScrollController _daysScrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();

  final Map<int, Map<String, String>> dayData = {
    1: {
      'weight': '95 grams',
      'height': '45 cm',
      'circumference': '40cm',
      'gender': 'Male'
    },
    2: {
      'weight': '100 grams',
      'height': '47 cm',
      'circumference': '41cm',
      'gender': 'Male'
    },
    3: {
      'weight': '105 grams',
      'height': '48 cm',
      'circumference': '42cm',
      'gender': 'Male'
    },
    4: {
      'weight': '110 grams',
      'height': '50 cm',
      'circumference': '44cm',
      'gender': 'Male'
    },
    5: {
      'weight': '115 grams',
      'height': '51 cm',
      'circumference': '45cm',
      'gender': 'Male'
    },
    6: {
      'weight': '120 grams',
      'height': '52 cm',
      'circumference': '46cm',
      'gender': 'Male'
    },
    7: {
      'weight': '125 grams',
      'height': '53 cm',
      'circumference': '47cm',
      'gender': 'Male'
    },
  };

  Map<int, double> weightData = {
    1: 95,
    2: 100,
    3: 105,
    4: 110,
    5: 115,
    6: 120,
    7: 125,
  };

  @override
  void initState() {
    super.initState();

    // Initialize scroll position to show selected day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToSelectedDay();

      // Set initial weight value in controller
      if (dayData.containsKey(selectedDay)) {
        String weightStr = dayData[selectedDay]!['weight']!;
        _weightController.text =
            weightStr.split(' ')[0]; // Extract just the number
      }
    });
  }

  void scrollToSelectedDay() {
    final index = selectedDay - 1;
    final itemWidth = 50.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    _daysScrollController.animateTo(
      offset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void updateWeight(String weight) {
    if (weight.isEmpty) return;

    setState(() {
      // Update the text data
      if (dayData.containsKey(selectedDay)) {
        dayData[selectedDay]!['weight'] = '$weight grams';
      } else {
        dayData[selectedDay] = {
          'weight': '$weight grams',
          'height': 'No data',
          'circumference': 'No data',
          'gender': 'Male',
        };
      }

      // Update the numeric data for chart
      double weightValue = double.tryParse(weight) ?? 0;
      weightData[selectedDay] = weightValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                // Add this to make content scrollable
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      _buildDaysScroller(),
                      SizedBox(height: 24),
                      _buildBabyImage(),
                      SizedBox(height: 24),
                      _buildInfoCard(),
                      SizedBox(height: 24),
                      _buildGrowthChart(),
                      SizedBox(
                          height: 24), // Replace Spacer() with fixed height
                      _buildWeightInput(),
                      SizedBox(height: 16), // Add bottom padding
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              // Back button functionality
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, size: 24),
            ),
          ),
          Text(
            'Growth Milestone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            onTap: () {
              // Settings functionality
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Settings pressed')));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysScroller() {
    return Container(
      height: 50,
      child: ListView.builder(
        controller: _daysScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 200, // Limiting to 200 days for performance
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final isSelected = dayNumber == selectedDay;
          final hasData = dayData.containsKey(dayNumber);

          return Padding(
            padding: EdgeInsets.only(right: 15),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedDay = dayNumber;

                  // Update text field when day changes
                  if (dayData.containsKey(selectedDay)) {
                    String weightStr = dayData[selectedDay]!['weight']!;
                    if (weightStr != 'No data') {
                      _weightController.text =
                          weightStr.split(' ')[0]; // Extract number
                    } else {
                      _weightController.text = '';
                    }
                  } else {
                    _weightController.text = '';
                  }
                });
              },
              child: Container(
                width: 35,
                height: 35,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: ShapeDecoration(
                        color: isSelected
                            ? const Color(0xFF1873EA)
                            : hasData
                                ? const Color(0x7FD9D9D9)
                                : const Color(0x4FD9D9D9),
                        shape: OvalBorder(),
                      ),
                    ),
                    Text(
                      dayNumber.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : hasData
                                ? const Color(0xFF8C8A8A)
                                : const Color(0xFFBBBBBB),
                        fontSize: 12,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBabyImage() {
    return Hero(
      tag: 'baby-image-$selectedDay',
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            // Replace with your actual image path
            image: AssetImage('assets/images/baby.png'),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) =>
                NetworkImage("https://placehold.co/100x100"),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    // Get data for selected day
    final data = dayData[selectedDay] ??
        {
          'weight': 'No data',
          'height': 'No data',
          'circumference': 'No data',
          'gender': 'No data'
        };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFF1873EA),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(2, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Baby Weight', data['weight']!),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem('Circumference', data['circumference']!),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Baby Height', data['height']!),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem('Gender', data['gender']!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF1873EA),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthChart() {
    // Filter out days with no weight data and sort them
    List<MapEntry<int, double>> filteredData = weightData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Get min and max values for scaling
    final minDay = filteredData
        .map((e) => e.key)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxDay = filteredData
        .map((e) => e.key)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final minWeight =
        filteredData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        filteredData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Create spot data for line chart
    final spots = filteredData
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFF1873EA),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(2, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    color: const Color(0xFF1873EA),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFF1873EA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Weight (grams)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        interval: (maxDay - minDay) / 5,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: (maxWeight - minWeight) / 4,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: minDay - 0.5,
                  maxX: maxDay + 0.5,
                  minY: minWeight - 5,
                  maxY: maxWeight + 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      //tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}: ${spot.y.toInt()} g',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {
                      // Optional: Add callback for touch events
                      if (response != null &&
                          response.lineBarSpots != null &&
                          response.lineBarSpots!.isNotEmpty) {
                        final spot = response.lineBarSpots!.first;
                        // You can do something when a point is touched, like:
                        // setState(() {
                        //   selectedDay = spot.x.toInt();
                        //   // Update other state variables
                        // });
                      }
                    },
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Color(0xFF1873EA),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Color(0xFF1873EA),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF1873EA).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (grams)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              // Save the entered weight
              updateWeight(_weightController.text);

              // Hide keyboard
              FocusScope.of(context).unfocus();

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Weight saved for day $selectedDay')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1873EA),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x99E5EAED),
            blurRadius: 20,
            offset: Offset(0, -2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, true),
          _buildNavItem(Icons.search, false),
          _buildNavItem(Icons.favorite_border, false),
          _buildNavItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${icon.toString()} pressed')));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Color(0xFF1873EA).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isActive ? Color(0xFF1873EA) : Colors.grey,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
 */
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_service.dart';
import 'child_model.dart';

class GrowthMilestonePage extends StatefulWidget {
  final String childId; // Add this to track which child's data to display

  const GrowthMilestonePage({super.key, required this.childId});

  @override
  State<GrowthMilestonePage> createState() => _GrowthMilestonePageState();
}

class _GrowthMilestonePageState extends State<GrowthMilestonePage> {
  int selectedDay = 1; // Default to day 1
  final ScrollController _daysScrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late ChildService _childService;
  Map<int, Map<String, String>> dayData = {};
  Map<int, double> weightData = {};
  bool _isLoading = true;
  int _lastUpdatedDay = 0;
  Child? _child;

  @override
  void initState() {
    super.initState();

    // Initialize the child service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _childService = ChildService(currentUser.uid);
      _loadChildData();
    } else {
      // Handle not logged in case (redirect to login or show error)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /* Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the child data
      final childData = await _childService.getChild(widget.childId);
      if (childData == null) {
        throw Exception('Child not found');
      }
      _child = childData;

      // Get the last updated day
      _lastUpdatedDay = await _childService.getLastUpdatedDay(widget.childId);

      // Subscribe to daily weights
      _childService.getDailyWeights(widget.childId).listen((snapshot) {
        if (mounted) {
          setState(() {
            // Clear previous data
            dayData.clear();
            weightData.clear();

            // Process each document
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final dayNumber = data['dayNumber'] as int;
              final weight = data['weight'] as double;

              // Add to weight data for chart
              weightData[dayNumber] = weight;

              // Add to day data for display
              dayData[dayNumber] = {
                'weight': '$weight grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
              };
            }

            // If we have data, select the most recent day or the next day to be updated
            if (_lastUpdatedDay > 0) {
              selectedDay = _lastUpdatedDay + 1;
            }

            _isLoading = false;
          });

          // Initialize weight controller
          if (dayData.containsKey(selectedDay)) {
            String weightStr = dayData[selectedDay]!['weight']!;
            _weightController.text =
                weightStr.split(' ')[0]; // Extract just the number
          } else {
            _weightController.text = '';
          }

          // Scroll to selected day
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToSelectedDay();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading child data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  } */

  Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the child data
      final childData = await _childService.getChild(widget.childId);
      if (childData == null) {
        throw Exception('Child not found');
      }
      _child = childData;

      // Get the last updated day
      _lastUpdatedDay = await _childService.getLastUpdatedDay(widget.childId);

      // If no days have been updated yet but we have birth weight, handle day 1
      if (_lastUpdatedDay == 0 && _child!.weight != null) {
        // Set up day 1 with birth weight from child data
        dayData[1] = {
          'weight': '${_child!.weight} grams',
          'height': _child!.height?.toString() ?? 'No data',
          'circumference': _child!.headCircumference?.toString() ?? 'No data',
          'gender': _child!.gender,
        };
        weightData[1] = _child!.weight!;

        // Set last updated day to 1 since we have day 1 data
        _lastUpdatedDay = 1;

        // Select day 2 for the next entry
        selectedDay = 2;
      } else if (_lastUpdatedDay > 0) {
        // If we have data, select the next day after the last updated
        selectedDay = _lastUpdatedDay + 1;
      }

      // Subscribe to daily weights
      _childService.getDailyWeights(widget.childId).listen((snapshot) {
        if (mounted) {
          setState(() {
            // Clear previous data
            dayData.clear();
            weightData.clear();

            // Process each document
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final dayNumber = data['dayNumber'] as int;
              final weight = data['weight'] as double;

              // Add to weight data for chart
              weightData[dayNumber] = weight;

              // Add to day data for display
              dayData[dayNumber] = {
                'weight': '$weight grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
              };
            }

            // If we have day 1 data from baby creation but it's not in the daily weights collection
            if (!dayData.containsKey(1) && _child!.weight != null) {
              weightData[1] = _child!.weight!;
              dayData[1] = {
                'weight': '${_child!.weight} grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
              };
            }

            _isLoading = false;
          });

          // Initialize weight controller for the selected day
          if (dayData.containsKey(selectedDay)) {
            String weightStr = dayData[selectedDay]!['weight']!;
            _weightController.text =
                weightStr.split(' ')[0]; // Extract just the number
          } else {
            _weightController.text = '';
          }

          // Scroll to selected day
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToSelectedDay();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading child data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void scrollToSelectedDay() {
    if (!_daysScrollController.hasClients) return;

    final index = selectedDay - 1;
    final itemWidth = 50.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    _daysScrollController.animateTo(
      offset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  DateTime calculateDateFromDayNumber(DateTime birthDate, int dayNumber) {
    // Subtract 1 from dayNumber because day 1 is the birth date itself
    return birthDate.add(Duration(days: dayNumber - 1));
  }

  /* Future<void> updateWeight(String weight) async {
    if (weight.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse weight as double
      double weightValue = double.tryParse(weight) ?? 0;
      if (weightValue <= 0) {
        throw Exception('Weight must be greater than zero');
      }

      if (_child == null) {
        throw Exception('Child data not loaded');
      }

      // Calculate actual date based on birth date and day number
      DateTime actualDate = calculateDateFromDayNumber(
        _child!.dateOfBirth,
        selectedDay,
      );

      // Save weight to database
      await _childService.addDailyWeight(
        widget.childId,
        dayNumber: selectedDay,
        date: actualDate, // Use calculated date
        weight: weightValue,
      );

      // Update last updated day if this is a new maximum
      if (selectedDay > _lastUpdatedDay) {
        _lastUpdatedDay = selectedDay;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weight saved for day $selectedDay (${actualDate.day}/${actualDate.month}/${actualDate.year})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating weight: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  } */

 Future<void> updateWeight(String weight) async {
    if (weight.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse weight as double
      double weightValue = double.tryParse(weight) ?? 0;
      if (weightValue <= 0) {
        throw Exception('Weight must be greater than zero');
      }
      
      if (_child == null) {
        throw Exception('Child data not loaded');
      }
      
      // Calculate actual date based on birth date and day number
      DateTime actualDate = calculateDateFromDayNumber(_child!.dateOfBirth, selectedDay);
      
      // Save weight to daily weights collection
      await _childService.addDailyWeight(
        widget.childId,
        dayNumber: selectedDay,
        date: actualDate,
        weight: weightValue,
      );
      
      // If this is day 1, also update the child's birth weight
      if (selectedDay == 1) {
        await _childService.updateChild(widget.childId, {
          'weight': weightValue,
        });
      }
      
      // Update last updated day if this is a new maximum
      if (selectedDay > _lastUpdatedDay) {
        _lastUpdatedDay = selectedDay;
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight saved for day $selectedDay (${actualDate.day}/${actualDate.month}/${actualDate.year})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating weight: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(height: 16),
                              _buildDaysScroller(),
                              SizedBox(height: 24),
                              _buildBabyImage(),
                              SizedBox(height: 24),
                              _buildInfoCard(),
                              SizedBox(height: 24),
                              _buildGrowthChart(),
                              SizedBox(height: 24),
                              _buildWeightInput(),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              // Back button functionality
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, size: 24),
            ),
          ),
          Text(
            'Growth Milestone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            onTap: () {
              // Settings functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Settings pressed')));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysScroller() {
    return Container(
      height: 50,
      child:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                controller: _daysScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: 200, // Limiting to 200 days for performance
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  final isSelected = dayNumber == selectedDay;
                  final hasData = dayData.containsKey(dayNumber);

                  // Determine circle color based on data
                  Color circleColor;
                  if (isSelected) {
                    circleColor = const Color(
                      0xFF1873EA,
                    ); // Blue for selected day
                  } else if (hasData) {
                    circleColor = Colors.green; // Green for days with data
                  } else if (dayNumber <= _lastUpdatedDay + 1) {
                    circleColor = const Color(0x7FD9D9D9); // Gray for past days
                  } else {
                    circleColor = const Color(
                      0x4FD9D9D9,
                    ); // Light gray for future days
                  }

                  return Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDay = dayNumber;

                          // Update text field when day changes
                          if (dayData.containsKey(selectedDay)) {
                            String weightStr = dayData[selectedDay]!['weight']!;
                            if (weightStr != 'No data') {
                              _weightController.text =
                                  weightStr.split(' ')[0]; // Extract number
                            } else {
                              _weightController.text = '';
                            }
                          } else {
                            _weightController.text = '';
                          }
                        });
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: ShapeDecoration(
                                color: circleColor,
                                shape: OvalBorder(),
                              ),
                            ),
                            Text(
                              dayNumber.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isSelected || hasData
                                        ? Colors.white
                                        : const Color(0xFF8C8A8A),
                                fontSize: 12,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildBabyImage() {
    return Hero(
      tag: 'baby-image-$selectedDay',
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            // Replace with your actual image path
            image: AssetImage('assets/images/baby.png'),
            fit: BoxFit.cover,
            onError:
                (exception, stackTrace) =>
                    NetworkImage("https://placehold.co/100x100"),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    // Get data for selected day
    final data =
        dayData[selectedDay] ??
        {
          'weight': 'No data',
          'height': 'No data',
          'circumference': 'No data',
          'gender': _child?.gender ?? 'Unknown',
        };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoItem('Baby Weight', data['weight']!)),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem('Circumference', data['circumference']!),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Baby Height', data['height']!)),
              SizedBox(width: 20),
              Expanded(child: _buildInfoItem('Gender', data['gender']!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF1873EA),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /* Widget _buildGrowthChart() {
    if (weightData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: const Color(0xFF1873EA),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 8,
              offset: Offset(2, 2),
              spreadRadius: 0,
            )
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

    // Filter out days with no weight data and sort them
    List<MapEntry<int, double>> filteredData = weightData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Get min and max values for scaling
    final minDay = filteredData
        .map((e) => e.key)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxDay = filteredData
        .map((e) => e.key)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final minWeight =
        filteredData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        filteredData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Create spot data for line chart
    final spots = filteredData
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFF1873EA),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(2, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    color: const Color(0xFF1873EA),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFF1873EA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Weight (grams)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        interval: (maxDay - minDay) / 5,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: (maxWeight - minWeight) / 4,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: minDay - 0.5,
                  maxX: maxDay + 0.5,
                  minY: minWeight - 5,
                  maxY: maxWeight + 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}: ${spot.y.toInt()} g',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {
                      // Optional: Add callback for touch events
                    },
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Color(0xFF1873EA),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Color(0xFF1873EA),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF1873EA).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } */
  Widget _buildGrowthChart() {
    if (weightData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
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

    // Filter out days with no weight data and sort them
    List<MapEntry<int, double>> filteredData =
        weightData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Get min and max values for scaling
    final minDay =
        filteredData
            .map((e) => e.key)
            .reduce((a, b) => a < b ? a : b)
            .toDouble();
    final maxDay =
        filteredData
            .map((e) => e.key)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final minWeight = filteredData
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = filteredData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    // Calculate intervals for x and y axes - handle the case where min=max
    final double xInterval =
        (maxDay - minDay) <= 0 ? 1.0 : (maxDay - minDay) / 5;
    final double yInterval =
        (maxWeight - minWeight) <= 0 ? 10.0 : (maxWeight - minWeight) / 4;

    // Create spot data for line chart
    final spots =
        filteredData
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
            .toList();

    return Container(
      width: double.infinity,
      height: 200,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    color: const Color(0xFF1873EA),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFF1873EA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Weight (grams)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        interval: xInterval, // Fixed interval calculation
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: yInterval, // Fixed interval calculation
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: minDay - 0.5,
                  maxX: maxDay + 0.5,
                  minY: minWeight - 5,
                  maxY: maxWeight + 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipPadding: EdgeInsets.all(8),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}: ${spot.y.toInt()} g',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (
                      FlTouchEvent event,
                      LineTouchResponse? response,
                    ) {
                      // Optional: Add callback for touch events
                      if (response != null &&
                          response.lineBarSpots != null &&
                          response.lineBarSpots!.isNotEmpty) {
                        final spot = response.lineBarSpots!.first;
                        // You can do something when a point is touched
                      }
                    },
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Color(0xFF1873EA),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Color(0xFF1873EA),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF1873EA).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (grams)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a weight';
                  }

                  // Try to parse the weight
                  double? weight = double.tryParse(value);
                  if (weight == null) {
                    return 'Please enter a valid number';
                  }

                  // Check for negative or zero values
                  if (weight <= 0) {
                    return 'Weight must be greater than zero';
                  }

                  // Check for unrealistically high values (e.g., 20,000 grams = 20kg)
                  if (weight > 20000) {
                    return 'Weight seems too high';
                  }

                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        // Form validation
                        if (_formKey.currentState?.validate() ?? false) {
                          updateWeight(_weightController.text);
                          // Hide keyboard
                          FocusScope.of(context).unfocus();
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1873EA),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x99E5EAED),
            blurRadius: 20,
            offset: Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, true),
          _buildNavItem(Icons.search, false),
          _buildNavItem(Icons.favorite_border, false),
          _buildNavItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${icon.toString()} pressed')));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Color(0xFF1873EA).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isActive ? Color(0xFF1873EA) : Colors.grey,
        ),
      ),
    );
  }
}

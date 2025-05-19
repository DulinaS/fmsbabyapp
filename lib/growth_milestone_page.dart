/* /* import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'child_service.dart';
import 'child_model.dart';

class GrowthMilestonePage extends StatefulWidget {
  final String childId;

  const GrowthMilestonePage({super.key, required this.childId});

  @override
  State<GrowthMilestonePage> createState() => _GrowthMilestonePageState();

class _GrowthMilestonePageState extends State<GrowthMilestonePage> {
  int selectedDay = 1;
  final ScrollController _daysScrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late ChildService _childService;
  Map<int, Map<String, dynamic>> dayData = {}; // Changed to include date
  Map<int, double> weightData = {};
  Map<int, DateTime> dayDates = {}; // Map to store day -> date mapping
  bool _isLoading = true;
  int _lastUpdatedDay = 0;
  Child? _child;

  // For date selection
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize date controller with current date
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
    _dateController.dispose();
    super.dispose();
  }

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
          'date': _child!.dateOfBirth,
        };
        weightData[1] = _child!.weight!;
        dayDates[1] = _child!.dateOfBirth;

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
            dayDates.clear();

            // Process each document
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final dayNumber = data['dayNumber'] as int;
              final weight = data['weight'] as double;
              final date = (data['date'] as Timestamp).toDate();

              // Add to weight data for chart
              weightData[dayNumber] = weight;
              dayDates[dayNumber] = date;

              // Add to day data for display
              dayData[dayNumber] = {
                'weight': '$weight grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': date,
              };
            }

            // If we have day 1 data from baby creation but it's not in the daily weights collection
            if (!dayData.containsKey(1) && _child!.weight != null) {
              weightData[1] = _child!.weight!;
              dayDates[1] = _child!.dateOfBirth;
              dayData[1] = {
                'weight': '${_child!.weight} grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': _child!.dateOfBirth,
              };
            }

            _isLoading = false;
          });

          // Initialize weight controller for the selected day
          if (dayData.containsKey(selectedDay)) {
            String weightStr = dayData[selectedDay]!['weight']!;
            _weightController.text =
                weightStr.split(' ')[0]; // Extract just the number

            // Set date if available
            if (dayData[selectedDay]!.containsKey('date')) {
              _selectedDate = dayData[selectedDay]!['date'] as DateTime;
              _dateController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(_selectedDate);
            }
          } else {
            _weightController.text = '';
            // For new entries, set today's date as default
            _selectedDate = DateTime.now();
            _dateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(_selectedDate);
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
    final itemWidth = 100.0; // Increased width for date display
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    _daysScrollController.animateTo(
      offset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _child?.dateOfBirth ?? DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1873EA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Find next available day number
  int getNextDayNumber() {
    if (dayData.isEmpty) return 1;
    return dayData.keys.reduce((a, b) => a > b ? a : b) + 1;
  }

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

      // For new entries, get the next available day number
      int dayNumber = selectedDay;
      if (!dayData.containsKey(selectedDay)) {
        // If this is a new day/entry
        if (selectedDay == 1) {
          // Day 1 is always birth date
          _selectedDate = _child!.dateOfBirth;
        }
      }

      // Save weight to daily weights collection
      await _childService.addDailyWeight(
        widget.childId,
        dayNumber: dayNumber,
        date: _selectedDate, // Use the selected date from date picker
        weight: weightValue,
      );

      // If this is day 1, also update the child's birth weight
      if (dayNumber == 1) {
        await _childService.updateChild(widget.childId, {
          'weight': weightValue,
        });
      }

      // Update last updated day if this is a new maximum
      if (dayNumber > _lastUpdatedDay) {
        _lastUpdatedDay = dayNumber;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weight saved for day $dayNumber (${DateFormat('dd/MM/yyyy').format(_selectedDate)})',
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
                              _buildWeightAndDateInput(),
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
      height: 80, // Increased height for date display
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

                  // Get date for this day
                  String dateStr = 'Select Date';
                  if (dayDates.containsKey(dayNumber)) {
                    dateStr = DateFormat('d MMM').format(dayDates[dayNumber]!);
                  } else if (dayNumber == 1 && _child != null) {
                    dateStr = DateFormat('d MMM').format(_child!.dateOfBirth);
                  }

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
                    padding: EdgeInsets.only(right: 10),
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

                            // Update date field
                            if (dayData[selectedDay]!.containsKey('date')) {
                              _selectedDate =
                                  dayData[selectedDay]!['date'] as DateTime;
                              _dateController.text = DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate);
                            }
                          } else {
                            _weightController.text = '';
                            // For new entries, set today's date as default except for day 1
                            if (dayNumber == 1 && _child != null) {
                              _selectedDate = _child!.dateOfBirth;
                            } else {
                              _selectedDate = DateTime.now();
                            }
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate);
                          }
                        });
                      },
                      child: Container(
                        width: 90, // Increased width for date display
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: ShapeDecoration(
                                color: circleColor,
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  dayNumber.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isSelected || hasData
                                            ? Colors.white
                                            : const Color(0xFF8C8A8A),
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              dateStr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? const Color(0xFF1873EA)
                                        : Colors.black87,
                                fontSize: 11,
                                fontFamily: 'Nunito',
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
          'date': _child?.dateOfBirth ?? DateTime.now(),
        };

    // Format the date
    String dateStr =
        data['date'] is DateTime
            ? DateFormat('dd MMM yyyy').format(data['date'] as DateTime)
            : 'No date';

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
              Expanded(child: _buildInfoItem('Date', dateStr)),
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
                          // Show date instead of day number if available
                          String title = value.toInt().toString();
                          if (dayDates.containsKey(value.toInt())) {
                            title = DateFormat(
                              'd MMM',
                            ).format(dayDates[value.toInt()]!);
                          }

                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9, // Smaller font for dates
                              ),
                            ),
                          );
                        },
                        interval: xInterval,
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
                        interval: yInterval,
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
                          // Show date in tooltip
                          String dateStr = '';
                          if (dayDates.containsKey(spot.x.toInt())) {
                            dateStr = DateFormat(
                              'dd MMM yyyy',
                            ).format(dayDates[spot.x.toInt()]!);
                          }

                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}\n${dateStr}\n${spot.y.toInt()} g',
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

  Widget _buildWeightAndDateInput() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weight Input
            Text(
              "Weight (grams)",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter baby's weight",
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

            SizedBox(height: 16),

            // Date Input
            Text(
              "Date",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Stack(
              children: [
                AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: "Tap to select date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF1873EA),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Save Button
            Center(
              child: ElevatedButton(
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
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(200, 48), // Make button wider
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
 */
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'child_service.dart';
import 'child_model.dart';

class GrowthMilestonePage extends StatefulWidget {
  final String childId;

  const GrowthMilestonePage({super.key, required this.childId});

  @override
  State<GrowthMilestonePage> createState() => _GrowthMilestonePageState();
}

class _GrowthMilestonePageState extends State<GrowthMilestonePage> {
  int selectedDay = 1;
  final ScrollController _daysScrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late ChildService _childService;
  Map<int, Map<String, dynamic>> dayData = {}; // Changed to include date
  Map<int, double> weightData = {};
  Map<int, DateTime> dayDates = {}; // Map to store day -> date mapping
  bool _isLoading = true;
  int _lastUpdatedDay = 0;
  Child? _child;

  // For date selection
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize date controller with current date
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
    _dateController.dispose();
    super.dispose();
  }

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
          'date': _child!.dateOfBirth,
        };
        weightData[1] = _child!.weight!;
        dayDates[1] = _child!.dateOfBirth;

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
            dayDates.clear();

            // Process each document
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final dayNumber = data['dayNumber'] as int;
              final weight = data['weight'] as double;
              final date = (data['date'] as Timestamp).toDate();

              // Add to weight data for chart
              weightData[dayNumber] = weight;
              dayDates[dayNumber] = date;

              // Add to day data for display
              dayData[dayNumber] = {
                'weight': '$weight grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': date,
              };
            }

            // If we have day 1 data from baby creation but it's not in the daily weights collection
            if (!dayData.containsKey(1) && _child!.weight != null) {
              weightData[1] = _child!.weight!;
              dayDates[1] = _child!.dateOfBirth;
              dayData[1] = {
                'weight': '${_child!.weight} grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': _child!.dateOfBirth,
              };
            }

            _isLoading = false;
          });

          // Initialize weight controller for the selected day
          if (dayData.containsKey(selectedDay)) {
            String weightStr = dayData[selectedDay]!['weight']!;
            _weightController.text =
                weightStr.split(' ')[0]; // Extract just the number

            // Set date if available
            if (dayData[selectedDay]!.containsKey('date')) {
              _selectedDate = dayData[selectedDay]!['date'] as DateTime;
              _dateController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(_selectedDate);
            }
          } else {
            _weightController.text = '';
            // For new entries, set today's date as default
            _selectedDate = DateTime.now();
            _dateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(_selectedDate);
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
    final itemWidth = 100.0; // Increased width for date display
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    _daysScrollController.animateTo(
      offset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Ensure we can't select future dates
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: _child?.dateOfBirth ?? DateTime(today.year - 2),
      lastDate: today, // Restrict to today as the last possible date
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1873EA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Find next available day number
  int getNextDayNumber() {
    if (dayData.isEmpty) return 1;
    return dayData.keys.reduce((a, b) => a > b ? a : b) + 1;
  }

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

      // Ensure we're not selecting a future date
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      if (_selectedDate.isAfter(today)) {
        throw Exception('Cannot add weight for future dates');
      }

      // For new entries, get the next available day number
      int dayNumber = selectedDay;
      if (!dayData.containsKey(selectedDay)) {
        // If this is a new day/entry
        if (selectedDay == 1) {
          // Day 1 is always birth date
          _selectedDate = _child!.dateOfBirth;
        }
      }

      // Save weight to daily weights collection
      await _childService.addDailyWeight(
        widget.childId,
        dayNumber: dayNumber,
        date: _selectedDate, // Use the selected date from date picker
        weight: weightValue,
      );

      // If this is day 1, also update the child's birth weight
      if (dayNumber == 1) {
        await _childService.updateChild(widget.childId, {
          'weight': weightValue,
        });
      }

      // Only update currentWeight if this is the most recent date
      // We need to find the most recent weight by date, not by day number
      List<MapEntry<int, DateTime>> sortedDates =
          dayDates.entries.toList()..add(MapEntry(dayNumber, _selectedDate));

      // Sort by date (most recent first)
      sortedDates.sort((a, b) => b.value.compareTo(a.value));

      // If this is the most recent date entry, update current weight
      if (sortedDates.isNotEmpty &&
          sortedDates.first.value.isAtSameMomentAs(_selectedDate)) {
        await _childService.updateChild(widget.childId, {
          'currentWeight': weightValue,
        });
      }

      // Update last updated day if this is a new maximum
      if (dayNumber > _lastUpdatedDay) {
        _lastUpdatedDay = dayNumber;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weight saved for day $dayNumber (${DateFormat('dd/MM/yyyy').format(_selectedDate)})',
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
                              _buildWeightAndDateInput(),
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
      height: 80, // Increased height for date display
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

                  // Get date for this day
                  String dateStr = 'Select Date';
                  if (dayDates.containsKey(dayNumber)) {
                    dateStr = DateFormat('d MMM').format(dayDates[dayNumber]!);
                  } else if (dayNumber == 1 && _child != null) {
                    dateStr = DateFormat('d MMM').format(_child!.dateOfBirth);
                  }

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
                    padding: EdgeInsets.only(right: 10),
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

                            // Update date field
                            if (dayData[selectedDay]!.containsKey('date')) {
                              _selectedDate =
                                  dayData[selectedDay]!['date'] as DateTime;
                              _dateController.text = DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate);
                            }
                          } else {
                            _weightController.text = '';
                            // For new entries, set today's date as default except for day 1
                            if (dayNumber == 1 && _child != null) {
                              _selectedDate = _child!.dateOfBirth;
                            } else {
                              _selectedDate = DateTime.now();
                            }
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate);
                          }
                        });
                      },
                      child: Container(
                        width: 90, // Increased width for date display
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: ShapeDecoration(
                                color: circleColor,
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  dayNumber.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isSelected || hasData
                                            ? Colors.white
                                            : const Color(0xFF8C8A8A),
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              dateStr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? const Color(0xFF1873EA)
                                        : Colors.black87,
                                fontSize: 11,
                                fontFamily: 'Nunito',
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
          'date': _child?.dateOfBirth ?? DateTime.now(),
        };

    // Format the date
    String dateStr =
        data['date'] is DateTime
            ? DateFormat('dd MMM yyyy').format(data['date'] as DateTime)
            : 'No date';

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
              Expanded(child: _buildInfoItem('Date', dateStr)),
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
                          // Show date instead of day number if available
                          String title = value.toInt().toString();
                          if (dayDates.containsKey(value.toInt())) {
                            title = DateFormat(
                              'd MMM',
                            ).format(dayDates[value.toInt()]!);
                          }

                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9, // Smaller font for dates
                              ),
                            ),
                          );
                        },
                        interval: xInterval,
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
                        interval: yInterval,
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
                          // Show date in tooltip
                          String dateStr = '';
                          if (dayDates.containsKey(spot.x.toInt())) {
                            dateStr = DateFormat(
                              'dd MMM yyyy',
                            ).format(dayDates[spot.x.toInt()]!);
                          }

                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}\n${dateStr}\n${spot.y.toInt()} g',
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

  Widget _buildWeightAndDateInput() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weight Input
            Text(
              "Weight (grams)",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter baby's weight",
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

            SizedBox(height: 16),

            // Date Input
            Text(
              "Date",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Stack(
              children: [
                AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: "Tap to select date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF1873EA),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Save Button
            Center(
              child: ElevatedButton(
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
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(200, 48), // Make button wider
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
 */
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'child_service.dart';
import 'child_model.dart';

class GrowthMilestonePage extends StatefulWidget {
  final String childId;

  const GrowthMilestonePage({super.key, required this.childId});

  @override
  State<GrowthMilestonePage> createState() => _GrowthMilestonePageState();
}

class _GrowthMilestonePageState extends State<GrowthMilestonePage> {
  int selectedDay = 1;
  final ScrollController _daysScrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late ChildService _childService;
  Map<int, Map<String, dynamic>> dayData = {}; // Includes weight, date, etc.
  Map<String, int> dateToDayMap = {}; // Maps date strings to day numbers
  Map<int, DateTime> dayToDateMap = {}; // Maps day numbers to dates
  Map<int, double> weightData = {}; // For the chart
  bool _isLoading = true;
  int _lastDayNumber = 0;
  Child? _child;

  // For date selection
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize date controller with current date
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
    _dateController.dispose();
    super.dispose();
  }

  // Convert DateTime to string key for mapping (yyyy-MM-dd format)
  String dateToKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Convert string key back to DateTime
  DateTime keyToDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Normalize date by removing time component
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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

      // Subscribe to daily weights
      _childService.getDailyWeights(widget.childId).listen((snapshot) {
        if (mounted) {
          setState(() {
            // Clear previous data
            dayData.clear();
            weightData.clear();
            dayToDateMap.clear();
            dateToDayMap.clear();

            // First, handle Day 1 (birth day)
            final birthDate = normalizeDate(_child!.dateOfBirth);
            final birthDateKey = dateToKey(birthDate);
            dayToDateMap[1] = birthDate;
            dateToDayMap[birthDateKey] = 1;

            if (_child!.weight != null) {
              // Add birth weight for day 1
              weightData[1] = _child!.weight!;
              dayData[1] = {
                'weight': '${_child!.weight} grams',
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': birthDate,
              };
            }

            // Process each document (sorted by date)
            List<DocumentSnapshot> sortedDocs =
                snapshot.docs.toList()..sort((a, b) {
                  final dateA =
                      (a.data() as Map<String, dynamic>)['date'] as Timestamp;
                  final dateB =
                      (b.data() as Map<String, dynamic>)['date'] as Timestamp;
                  return dateA.compareTo(dateB);
                });

            int dayCounter = 1; // Start from day 1 (birth date)
            DateTime? latestDate;
            double? latestWeight;

            for (var doc in sortedDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = normalizeDate((data['date'] as Timestamp).toDate());
              final dateKey = dateToKey(date);
              final weight = data['weight'] as double;

              // Skip if this is the birth date (already processed)
              if (dateKey == birthDateKey && dayCounter == 1) {
                // Just update the weight for day 1 if needed
                weightData[1] = weight;
                dayData[1] = {
                  'weight': '$weight grams',
                  'height': _child?.height?.toString() ?? 'No data',
                  'circumference':
                      _child?.headCircumference?.toString() ?? 'No data',
                  'gender': _child?.gender ?? 'Unknown',
                  'date': date,
                };
                continue;
              }

              // If date already has a day number, use that
              if (dateToDayMap.containsKey(dateKey)) {
                final existingDay = dateToDayMap[dateKey]!;
                weightData[existingDay] = weight;
                dayData[existingDay] = {
                  'weight': '$weight grams',
                  'height': _child?.height?.toString() ?? 'No data',
                  'circumference':
                      _child?.headCircumference?.toString() ?? 'No data',
                  'gender': _child?.gender ?? 'Unknown',
                  'date': date,
                };
              } else {
                // Assign next available day number
                dayCounter++;
                dateToDayMap[dateKey] = dayCounter;
                dayToDateMap[dayCounter] = date;

                weightData[dayCounter] = weight;
                dayData[dayCounter] = {
                  'weight': '$weight grams',
                  'height': _child?.height?.toString() ?? 'No data',
                  'circumference':
                      _child?.headCircumference?.toString() ?? 'No data',
                  'gender': _child?.gender ?? 'Unknown',
                  'date': date,
                };
              }

              // Keep track of latest date and weight
              if (latestDate == null || date.isAfter(latestDate)) {
                latestDate = date;
                latestWeight = weight;
              }
            }

            // Store last day number
            _lastDayNumber =
                dayData.isEmpty
                    ? 0
                    : dayData.keys.reduce((a, b) => a > b ? a : b);

            // Set selected day to next available day
            selectedDay = _lastDayNumber + 1;

            // Set today's date for new entry
            _selectedDate = DateTime.now();
            _dateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(_selectedDate);
            _weightController.text = '';

            _isLoading = false;
          });

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
    final itemWidth = 100.0; // Increased width for date display
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    _daysScrollController.animateTo(
      offset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Ensure we can't select future dates
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: _child?.dateOfBirth ?? DateTime(today.year - 2),
      lastDate: today, // Restrict to today as the last possible date
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1873EA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final normalizedDate = normalizeDate(picked);
      final dateKey = dateToKey(normalizedDate);

      // Check if this date already has an entry
      if (dateToDayMap.containsKey(dateKey)) {
        // If yes, switch to that day
        final existingDay = dateToDayMap[dateKey]!;

        setState(() {
          selectedDay = existingDay;
          _selectedDate = normalizedDate;
          _dateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(normalizedDate);

          // Update weight field with existing data
          if (dayData.containsKey(existingDay)) {
            String weightStr = dayData[existingDay]!['weight'];
            _weightController.text =
                weightStr.split(' ')[0]; // Extract just the number
          }
        });

        // Inform user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "This date already has a weight entry (Day $existingDay). You can update it.",
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // If not, set it as new entry
        setState(() {
          _selectedDate = normalizedDate;
          _dateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(normalizedDate);
        });
      }
    }
  }

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

      // Ensure we're not selecting a future date
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final normalizedSelectedDate = normalizeDate(_selectedDate);

      if (normalizedSelectedDate.isAfter(today)) {
        throw Exception('Cannot add weight for future dates');
      }

      // Convert date to key for mapping
      final dateKey = dateToKey(normalizedSelectedDate);

      // Check if this date already has an entry
      int dayNumber;
      bool isUpdate = false;

      if (dateToDayMap.containsKey(dateKey)) {
        // This is an update to existing date
        dayNumber = dateToDayMap[dateKey]!;
        isUpdate = true;
      } else {
        // This is a new date entry - use selected day number or next available
        if (dayData.containsKey(selectedDay)) {
          // If this day number is taken, use next available
          dayNumber = _lastDayNumber + 1;
        } else {
          dayNumber = selectedDay;
        }

        // Special handling for Day 1 (birth date)
        if (dayNumber == 1) {
          // Only allow Day 1 to be birth date
          final birthDateKey = dateToKey(normalizeDate(_child!.dateOfBirth));
          if (dateKey != birthDateKey) {
            throw Exception(
              'Day 1 must be the birth date. Please select a different day number for this date.',
            );
          }
        }
      }

      // Save weight to daily weights collection
      await _childService.addDailyWeight(
        widget.childId,
        dayNumber: dayNumber,
        date: normalizedSelectedDate,
        weight: weightValue,
      );

      // If this is day 1, also update the child's birth weight
      if (dayNumber == 1) {
        await _childService.updateChild(widget.childId, {
          'weight': weightValue,
        });
      }

      // ----- MODIFIED LOGIC FOR CURRENT WEIGHT UPDATE -----

      // Find the entry with the latest selected date (not creation date)
      // This ensures we use the date the user picked, not when they entered it
      DateTime latestDate = DateTime(1900); // Start with a very old date
      double latestDateWeight = 0;

      // Check all days to find the one with the latest selected date
      for (final entry in dayToDateMap.entries) {
        final dayNum = entry.key;
        final entryDate = entry.value;

        // If this entry has a date after our current latest
        if (entryDate.isAfter(latestDate)) {
          latestDate = entryDate;

          // Get the weight for this day
          if (weightData.containsKey(dayNum)) {
            latestDateWeight = weightData[dayNum]!;
          }
        }
      }

      // If our current selected date is the latest or same as latest,
      // use the current weight we're entering
      if (normalizedSelectedDate.isAfter(latestDate) ||
          normalizedSelectedDate.isAtSameMomentAs(latestDate)) {
        latestDate = normalizedSelectedDate;
        latestDateWeight = weightValue;
      }

      // Update current weight to weight from entry with latest selected date
      print(
        "Updating current weight to $latestDateWeight from date $latestDate",
      );
      await _childService.updateChild(widget.childId, {
        'currentWeight': latestDateWeight,
      });

      // ----- END OF MODIFIED LOGIC -----

      // Update our tracking
      if (!isUpdate) {
        _lastDayNumber = Math.max(_lastDayNumber, dayNumber);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate
                  ? 'Updated weight for day $dayNumber (${DateFormat('dd/MM/yyyy').format(normalizedSelectedDate)})'
                  : 'Added weight for day $dayNumber (${DateFormat('dd/MM/yyyy').format(normalizedSelectedDate)})',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data to update UI
        _loadChildData();
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

      setState(() {
        _isLoading = false;
      });
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
                              _buildWeightAndDateInput(),
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
      height: 80, // Increased height for date display
      child:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                controller: _daysScrollController,
                scrollDirection: Axis.horizontal,
                itemCount:
                    _lastDayNumber + 5, // Show a few extra days for new entries
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  final isSelected = dayNumber == selectedDay;
                  final hasData = dayData.containsKey(dayNumber);

                  // Get date for this day
                  String dateStr;
                  if (dayToDateMap.containsKey(dayNumber)) {
                    // Existing day with data
                    dateStr = DateFormat(
                      'd MMM yyyy',
                    ).format(dayToDateMap[dayNumber]!);
                  } else if (isSelected) {
                    // Selected day (might be new)
                    dateStr = DateFormat('d MMM yyyy').format(_selectedDate);
                  } else {
                    // Empty day
                    dateStr = 'Select date';
                  }

                  // Determine circle color based on data
                  Color circleColor;
                  if (isSelected) {
                    circleColor = const Color(
                      0xFF1873EA,
                    ); // Blue for selected day
                  } else if (hasData) {
                    circleColor = Colors.green; // Green for days with data
                  } else {
                    circleColor = const Color(
                      0x7FD9D9D9,
                    ); // Gray for future days
                  }

                  return Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDay = dayNumber;

                          // Update text fields when day changes
                          if (dayData.containsKey(selectedDay)) {
                            // Existing data
                            String weightStr = dayData[selectedDay]!['weight'];
                            _weightController.text =
                                weightStr.split(' ')[0]; // Extract number

                            // Update date field
                            _selectedDate =
                                dayData[selectedDay]!['date'] as DateTime;
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate);
                          } else {
                            // New entry
                            _weightController.text = '';

                            // For Day 1, use birth date, otherwise use today
                            if (dayNumber == 1 && _child != null) {
                              _selectedDate = _child!.dateOfBirth;
                            } else {
                              _selectedDate = DateTime.now();
                            }
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate);

                            // Check if selected date already has data
                            final dateKey = dateToKey(
                              normalizeDate(_selectedDate),
                            );
                            if (dateToDayMap.containsKey(dateKey)) {
                              final existingDay = dateToDayMap[dateKey]!;

                              // Switch to that day instead
                              selectedDay = existingDay;

                              // Update weight field with existing data
                              if (dayData.containsKey(existingDay)) {
                                String weightStr =
                                    dayData[existingDay]!['weight'];
                                _weightController.text =
                                    weightStr.split(' ')[0];
                              }

                              // Inform user
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "This date already has a weight entry (Day $existingDay). You can update it.",
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              });
                            }
                          }
                        });
                      },
                      child: Container(
                        width: 90, // Increased width for date display
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: ShapeDecoration(
                                color: circleColor,
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  dayNumber.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isSelected || hasData
                                            ? Colors.white
                                            : const Color(0xFF8C8A8A),
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              dateStr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? const Color(0xFF1873EA)
                                        : Colors.black87,
                                fontSize: 11,
                                fontFamily: 'Nunito',
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
          'date': _selectedDate,
        };

    // Format the date
    String dateStr =
        data['date'] is DateTime
            ? DateFormat('dd MMM yyyy').format(data['date'] as DateTime)
            : DateFormat('dd MMM yyyy').format(_selectedDate);

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
              Expanded(child: _buildInfoItem('Baby Weight', data['weight'])),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem(
                  'Circumference',
                  data['circumference'] ?? 'No data',
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Baby Height',
                  data['height'] ?? 'No data',
                ),
              ),
              SizedBox(width: 20),
              Expanded(child: _buildInfoItem('Date', dateStr)),
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

    // Sort entries by date for chronological chart
    List<MapEntry<int, double>> sortedEntries = [];

    for (var entry in weightData.entries) {
      // Only include entries that have dates
      if (dayToDateMap.containsKey(entry.key)) {
        sortedEntries.add(entry);
      }
    }

    // Sort by date
    sortedEntries.sort((a, b) {
      final dateA = dayToDateMap[a.key]!;
      final dateB = dayToDateMap[b.key]!;
      return dateA.compareTo(dateB);
    });

    // Calculate days since birth for x-axis
    final spots =
        sortedEntries.map((entry) {
          final date = dayToDateMap[entry.key]!;
          final birthDate = _child!.dateOfBirth;
          final daysSinceBirth = date.difference(birthDate).inDays;
          return FlSpot(daysSinceBirth.toDouble(), entry.value);
        }).toList();

    // Get min and max values for scaling
    if (spots.isEmpty) {
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

    // Calculate intervals for x and y axes - handle the case where min=max
    final double xInterval = (maxX - minX) <= 0 ? 1.0 : (maxX - minX) / 5;
    final double yInterval = (maxY - minY) <= 0 ? 10.0 : (maxY - minY) / 4;

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
                          // Calculate date for this x value (days since birth)
                          final birthDate = _child!.dateOfBirth;
                          final date = birthDate.add(
                            Duration(days: value.toInt()),
                          );
                          final dateStr = DateFormat('d MMM').format(date);

                          return SideTitleWidget(
                            angle: 0,
                            space: 8,
                            meta: meta,
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9, // Smaller font for dates
                              ),
                            ),
                          );
                        },
                        interval: xInterval,
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
                        interval: yInterval,
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
                  minX: minX - 0.5,
                  maxX: maxX + 0.5,
                  minY: minY - 5,
                  maxY: maxY + 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipPadding: EdgeInsets.all(8),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          // Get day number and date for this spot
                          final daysSinceBirth = spot.x.toInt();
                          final date = _child!.dateOfBirth.add(
                            Duration(days: daysSinceBirth),
                          );
                          final dateStr = DateFormat(
                            'dd MMM yyyy',
                          ).format(date);

                          // Find day number for this date
                          int? dayNumber;
                          for (var entry in dayToDateMap.entries) {
                            if (normalizeDate(
                              entry.value,
                            ).isAtSameMomentAs(normalizeDate(date))) {
                              dayNumber = entry.key;
                              break;
                            }
                          }

                          return LineTooltipItem(
                            'Day ${dayNumber ?? '?'}\n${dateStr}\n${spot.y.toInt()} g',
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

  Widget _buildWeightAndDateInput() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weight Input
            Text(
              "Weight (grams)",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter baby's weight",
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

            SizedBox(height: 16),

            // Date Input
            Text(
              "Date",
              style: TextStyle(
                color: const Color(0xFF1873EA),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Stack(
              children: [
                AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: "Tap to select date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF1873EA),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }

                      // Check if date already has an entry (except for current selected day)
                      try {
                        final dateStr = value;
                        final date = DateFormat('dd/MM/yyyy').parse(dateStr);
                        final normalizedDate = normalizeDate(date);
                        final dateKey = dateToKey(normalizedDate);

                        if (dateToDayMap.containsKey(dateKey)) {
                          final existingDay = dateToDayMap[dateKey]!;
                          if (existingDay != selectedDay) {
                            return 'This date already has data (Day $existingDay)';
                          }
                        }
                      } catch (e) {
                        // Parsing error, ignore
                      }

                      return null;
                    },
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Save Button
            Center(
              child: ElevatedButton(
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
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(200, 48), // Make button wider
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

// Helper for Math.max equivalent
class Math {
  static int max(int a, int b) {
    return a > b ? a : b;
  }
}

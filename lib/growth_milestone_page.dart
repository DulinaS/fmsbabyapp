import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fmsbabyapp/growth_standard_service.dart';
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

  // Weight unit selection
  bool _isKgUnit = true; // Default to kg for input

  // For WHO standard reference lines
  Map<String, List<FlSpot>> _whoStandardLines = {};
  bool _isLoadingStandards = false;

  late ChildService _childService;
  Map<int, Map<String, dynamic>> dayData = {}; // Includes weight, date, etc.
  Map<String, int> dateToDayMap = {}; // Maps date strings to day numbers
  Map<int, DateTime> dayToDateMap = {}; // Maps day numbers to dates
  Map<int, double> weightData =
      {}; // For the chart (always in grams internally)
  Map<int, Map<String, dynamic>> weightCategoryData =
      {}; // Stores category info for each weight point

  bool _isLoading = true;
  int _lastDayNumber = 0;
  Child? _child;
  String? _weightStatusMessage;
  Color _weightStatusColor = Colors.grey;

  // For date selection
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();

  // Reference to the Firestore weight standards collection
  final CollectionReference _growthStandardsCollection = FirebaseFirestore
      .instance
      .collection('growthStandards');

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

    //trigger loading WHO standards after child data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_child != null && !_isLoadingStandards && _whoStandardLines.isEmpty) {
        _isLoadingStandards = true;
        _loadWHOStandardLines();
      }
    });
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    _weightController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadWHOStandardLines() async {
    if (_child == null) return;

    try {
      final growthStandardService = GrowthStandardService();

      // Determine time range for chart - extend to at least 6 months
      int maxDays = 180; // Default to 6 months minimum

      if (dayToDateMap.isNotEmpty) {
        // Find latest date in data
        final latestDate = dayToDateMap.values.reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );

        // Calculate days from birth to latest date plus 60 days buffer
        int daysFromBirthToLatest =
            latestDate.difference(_child!.dateOfBirth).inDays + 60;

        // Use the larger of 180 days or actual data range
        maxDays = daysFromBirthToLatest > 180 ? daysFromBirthToLatest : 180;
      }

      // Round to next month
      maxDays = (maxDays ~/ 30 + 1) * 30;

      // Get standard lines data
      final standardLinesData = await growthStandardService
          .getStandardLinesData(
            _child!.gender,
            _child!.dateOfBirth,
            maxDays: maxDays,
          );

      // Convert to FlSpot format - ALWAYS in kg
      Map<String, List<FlSpot>> lines = {};
      standardLinesData.forEach((key, pointList) {
        lines[key] =
            pointList.map((point) {
              // Convert to FlSpot with x as days since birth and y as weight
              // Always convert weight to kg for the chart
              double yValue = (point['y'] as double) / 1000;
              return FlSpot(point['x'] as double, yValue);
            }).toList();
      });

      if (mounted) {
        setState(() {
          _whoStandardLines = lines;
          _isLoadingStandards = false;
        });
      }
    } catch (e) {
      print('Error loading WHO standards: $e');
      if (mounted) {
        setState(() {
          _isLoadingStandards = false;
        });
      }
    }
  }

  Widget _buildLegendItem(
    String label,
    Color color, {
    bool isLine = false,
    double width = 1.0,
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: isLine ? 2 : 2,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
          ),
          child:
              isDashed
                  ? CustomPaint(
                    painter: DashedLinePainter(
                      color: color,
                      strokeWidth: width,
                    ),
                  )
                  : null,
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  void _showWHOStandardsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'WHO Growth Standards',
            style: TextStyle(
              color: Color(0xFF1873EA),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'About WHO Growth Standards',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'The World Health Organization (WHO) growth standards show how healthy children should grow under optimal conditions regardless of ethnicity, socioeconomic status, and type of feeding.',
                ),
                SizedBox(height: 16),
                Text(
                  'Weight Categories',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildCategoryInfo(
                  'Normal',
                  'Weight between -2SD and +2SD from the median.',
                  Colors.green,
                ),
                SizedBox(height: 8),
                _buildCategoryInfo(
                  'Underweight',
                  'Weight below -2SD from the median.',
                  Colors.orange,
                ),
                SizedBox(height: 8),
                _buildCategoryInfo(
                  'Severely Underweight',
                  'Weight below -3SD from the median.',
                  Colors.red,
                ),
                SizedBox(height: 8),
                _buildCategoryInfo(
                  'Overweight',
                  'Weight above +2SD from the median.',
                  Colors.orange,
                ),
                SizedBox(height: 8),
                _buildCategoryInfo(
                  'Extremely Overweight',
                  'Weight above +3SD from the median.',
                  Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'SD = Standard Deviation, a statistical measure of the spread of values around the median (average).',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
              style: TextButton.styleFrom(foregroundColor: Color(0xFF1873EA)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryInfo(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
              Text(description, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // Convert grams to kg for display
  String gramsToDisplayWeight(double weightInGrams) {
    return _isKgUnit
        ? '${(weightInGrams / 1000).toStringAsFixed(2)} kg'
        : '${weightInGrams.toInt()} grams';
  }

  // Extract numeric value from weight display string
  double extractWeightValue(String weightDisplayString) {
    final numericPart =
        RegExp(r'[0-9]+\.?[0-9]*').firstMatch(weightDisplayString)?.group(0) ??
        '0';
    return double.tryParse(numericPart) ?? 0;
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

  // Determine weight category and status message
  Future<Map<String, dynamic>> determineWeightCategory(
    double weightInGrams,
    DateTime dateOfBirth,
    DateTime measurementDate,
    String gender,
  ) async {
    try {
      // Calculate age in months and years
      final ageInDays = measurementDate.difference(dateOfBirth).inDays;
      final ageInMonths = ageInDays / 30.44; // Average days per month
      final ageInYears = ageInDays / 365.25; // Average days per year

      // Determine if we should use monthly or yearly data
      final String collection = ageInYears < 1 ? 'months' : 'years';
      final String genderDoc =
          gender.toLowerCase() == 'boy' ? 'boys_weight' : 'girls_weight';

      // Get the reference ranges for this gender
      final docSnapshot = await _growthStandardsCollection.doc(genderDoc).get();
      if (!docSnapshot.exists) {
        // Handle missing data - use default
        return {
          'category': 'normal',
          'info': {
            'name': 'Normal',
            'color': '#4CAF50',
            'message':
                'Weight appears to be in normal range. Standards data missing.',
          },
          'actualWeight': weightInGrams,
        };
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final categories = data['categories'] as Map<String, dynamic>;

      // Calculate age key to use
      String ageKey;
      if (collection == 'months') {
        // Find closest month milestone (0, 1, 2, 3, 6, 9, 12)
        final availableMonths = [0, 1, 2, 3, 6, 9, 12];
        final closestMonth = availableMonths.reduce((prev, curr) {
          return (ageInMonths - prev).abs() < (ageInMonths - curr).abs()
              ? prev
              : curr;
        });
        ageKey = closestMonth.toString();
      } else {
        // Find closest year milestone (1, 2, 3, 4, 5)
        final availableYears = [1, 2, 3, 4, 5];
        final closestYear = availableYears.reduce((prev, curr) {
          return (ageInYears - prev).abs() < (ageInYears - curr).abs()
              ? prev
              : curr;
        });
        ageKey = closestYear.toString();
      }

      // Get range values for this age
      final Map<String, dynamic> rangeValues = data[collection][ageKey];

      // Determine weight category
      String category;
      if (weightInGrams < rangeValues['minus3SD']) {
        category = 'minus3SD';
      } else if (weightInGrams < rangeValues['minus2SD']) {
        category = 'minus2SD';
      } else if (weightInGrams < rangeValues['plus2SD']) {
        category = 'normal';
      } else if (weightInGrams < rangeValues['plus3SD']) {
        category = 'plus2SD';
      } else {
        category = 'plus3SD';
      }

      // Return category info with range values for reference
      return {
        'category': category,
        'info': categories[category],
        'ranges': rangeValues,
        'actualWeight': weightInGrams,
        'ageKey': ageKey,
        'collection': collection,
      };
    } catch (e) {
      print('Error determining weight category: $e');
      // Return a default category in case of error
      return {
        'category': 'error',
        'info': {
          'name': 'Error',
          'color': '#808080', // Gray
          'message': 'Could not determine weight category. Please try again.',
        },
        'actualWeight': weightInGrams,
      };
    }
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
      _childService.getDailyWeights(widget.childId).listen((snapshot) async {
        if (mounted) {
          // Clear previous data
          Map<int, Map<String, dynamic>> newDayData = {};
          Map<String, int> newDateToDayMap = {};
          Map<int, DateTime> newDayToDateMap = {};
          Map<int, double> newWeightData = {};
          Map<int, Map<String, dynamic>> newWeightCategoryData = {};

          // First, handle Day 1 (birth day)
          final birthDate = normalizeDate(_child!.dateOfBirth);
          final birthDateKey = dateToKey(birthDate);
          newDayToDateMap[1] = birthDate;
          newDateToDayMap[birthDateKey] = 1;

          if (_child!.weight != null) {
            // Add birth weight for day 1
            newWeightData[1] = _child!.weight!;

            // Get weight category for birth weight
            final weightCategory = await determineWeightCategory(
              _child!.weight!,
              _child!.dateOfBirth,
              _child!.dateOfBirth,
              _child!.gender,
            );

            newWeightCategoryData[1] = weightCategory;

            newDayData[1] = {
              'weight': gramsToDisplayWeight(_child!.weight!),
              'height': _child?.height?.toString() ?? 'No data',
              'circumference':
                  _child?.headCircumference?.toString() ?? 'No data',
              'gender': _child?.gender ?? 'Unknown',
              'date': birthDate,
              'category': weightCategory['category'],
              'message': weightCategory['info']['message'],
              'color': weightCategory['info']['color'],
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

          for (var doc in sortedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = normalizeDate((data['date'] as Timestamp).toDate());
            final dateKey = dateToKey(date);
            final weight = data['weight'] as double;

            // *** FIX: Use the dayNumber from the document, not sequential assignment ***
            final dayNumber =
                data['dayNumber'] as int? ?? 1; // Default to 1 if missing

            // Skip if this is the birth date (already processed)
            if (dateKey == birthDateKey && dayNumber == 1) {
              // Just update the weight for day 1 if needed
              newWeightData[1] = weight;

              // Get weight category for birth weight
              final weightCategory = await determineWeightCategory(
                weight,
                _child!.dateOfBirth,
                date,
                _child!.gender,
              );

              newWeightCategoryData[1] = weightCategory;

              newDayData[1] = {
                'weight': gramsToDisplayWeight(weight),
                'height': _child?.height?.toString() ?? 'No data',
                'circumference':
                    _child?.headCircumference?.toString() ?? 'No data',
                'gender': _child?.gender ?? 'Unknown',
                'date': date,
                'category': weightCategory['category'],
                'message': weightCategory['info']['message'],
                'color': weightCategory['info']['color'],
              };
              continue;
            }

            // *** FIX: Use the actual dayNumber from document ***
            newDateToDayMap[dateKey] = dayNumber;
            newDayToDateMap[dayNumber] = date;

            newWeightData[dayNumber] = weight;

            // Get weight category for this weight measurement
            final weightCategory = await determineWeightCategory(
              weight,
              _child!.dateOfBirth,
              date,
              _child!.gender,
            );

            newWeightCategoryData[dayNumber] = weightCategory;

            newDayData[dayNumber] = {
              'weight': gramsToDisplayWeight(weight),
              'height': _child?.height?.toString() ?? 'No data',
              'circumference':
                  _child?.headCircumference?.toString() ?? 'No data',
              'gender': _child?.gender ?? 'Unknown',
              'date': date,
              'category': weightCategory['category'],
              'message': weightCategory['info']['message'],
              'color': weightCategory['info']['color'],
            };
          }

          // Update state
          if (mounted) {
            setState(() {
              dayData = newDayData;
              dateToDayMap = newDateToDayMap;
              dayToDateMap = newDayToDateMap;
              weightData = newWeightData;
              weightCategoryData = newWeightCategoryData;

              // Store last day number - find the maximum day number from actual data
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

            // Load WHO standard lines if not already loaded
            if (!_isLoadingStandards && _whoStandardLines.isEmpty) {
              _isLoadingStandards = true;
              _loadWHOStandardLines();
            }

            // Scroll to selected day
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToSelectedDay();
            });
          }
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
            double weightValue = extractWeightValue(weightStr);

            // Convert to appropriate unit for display in the text field
            if (_isKgUnit) {
              // If weight stored in grams but display in kg
              if (weightStr.contains('grams')) {
                _weightController.text = (weightValue / 1000).toStringAsFixed(
                  2,
                );
              } else {
                _weightController.text = weightValue.toStringAsFixed(2);
              }
            } else {
              // If weight stored in kg but display in grams
              if (weightStr.contains('kg')) {
                _weightController.text = (weightValue * 1000).toStringAsFixed(
                  0,
                );
              } else {
                _weightController.text = weightValue.toStringAsFixed(0);
              }
            }

            // Update status message for this day
            _weightStatusMessage = dayData[existingDay]!['message'];
            _weightStatusColor = hexToColor(dayData[existingDay]!['color']);
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

          // Clear status message for new entry
          _weightStatusMessage = null;
        });
      }
    }
  }

  // Convert hex color string to Color
  Color hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Icon selector based on weight category
  IconData _getStatusIcon(String category) {
    switch (category) {
      case 'minus3SD':
        return Icons.error_outline;
      case 'minus2SD':
        return Icons.warning_amber_outlined;
      case 'normal':
        return Icons.check_circle_outline;
      case 'plus2SD':
        return Icons.warning_amber_outlined;
      case 'plus3SD':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  // Modified updateWeight method
  Future<void> updateWeight(String weightInput) async {
    if (weightInput.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse weight as double
      double weightValue = double.tryParse(weightInput) ?? 0;
      if (weightValue <= 0) {
        throw Exception('Weight must be greater than zero');
      }

      // Convert kg to grams for storage if using kg
      double weightInGrams = _isKgUnit ? weightValue * 1000 : weightValue;

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

      // Get the weight category for this measurement (before saving)
      final weightCategory = await determineWeightCategory(
        weightInGrams,
        _child!.dateOfBirth,
        normalizedSelectedDate,
        _child!.gender,
      );

      // Check if this date already has an entry
      bool isUpdate = false;
      String? existingDocId;

      if (dateToDayMap.containsKey(dateKey)) {
        // This is an update to existing date
        isUpdate = true;

        // Find the document ID for this date
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final dailyWeightsCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('children')
            .doc(widget.childId)
            .collection('dailyWeights');

        final querySnapshot =
            await dailyWeightsCollection
                .where(
                  'date',
                  isEqualTo: Timestamp.fromDate(normalizedSelectedDate),
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          existingDocId = querySnapshot.docs.first.id;
        }
      }

      if (isUpdate && existingDocId != null) {
        // Update existing document
        await _childService.updateDailyWeight(
          widget.childId,
          existingDocId,
          weight: weightInGrams,
        );

        debugPrint(
          'Updated existing weight entry for date: $normalizedSelectedDate',
        );
      } else {
        // This is a new entry - add it first, then reassign all day numbers chronologically

        // Add the new weight entry with a temporary day number
        await _childService.addDailyWeight(
          widget.childId,
          dayNumber: 999, // Temporary day number
          date: normalizedSelectedDate,
          weight: weightInGrams,
        );

        debugPrint('Added new weight entry for date: $normalizedSelectedDate');

        // Now reassign all day numbers chronologically
        await _reassignDayNumbersChronologically();

        print('Reassigned all day numbers chronologically');
      }

      // Handle birth date special case
      final birthDate = normalizeDate(_child!.dateOfBirth);
      if (normalizedSelectedDate.isAtSameMomentAs(birthDate)) {
        // Also update the child's birth weight
        await _childService.updateChild(widget.childId, {
          'weight': weightInGrams,
        });
      }

      // Update current weight to the weight from the latest chronological date
      await _updateCurrentWeightToLatest();

      // Show status message based on weight category
      setState(() {
        _weightStatusMessage = weightCategory['info']['message'];
        _weightStatusColor = hexToColor(weightCategory['info']['color']);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate
                  ? 'Updated weight for ${DateFormat('dd/MM/yyyy').format(normalizedSelectedDate)}'
                  : 'Added weight for ${DateFormat('dd/MM/yyyy').format(normalizedSelectedDate)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data to update UI
        _loadChildData();

        // Ensure WHO standards are loaded
        if (!_isLoadingStandards && _whoStandardLines.isEmpty) {
          _isLoadingStandards = true;
          _loadWHOStandardLines();
        }
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
                      'd MMM',
                    ).format(dayToDateMap[dayNumber]!);
                  } else if (isSelected) {
                    // Selected day (might be new)
                    dateStr = DateFormat('d MMM').format(_selectedDate);
                  } else {
                    // Empty day
                    dateStr = 'Select';
                  }

                  // Determine circle color based on data
                  Color circleColor;
                  if (isSelected) {
                    circleColor = const Color(
                      0xFF1873EA,
                    ); // Blue for selected day
                  } else if (hasData) {
                    // Use the weight category color if available
                    if (dayData[dayNumber]?.containsKey('color') ?? false) {
                      circleColor = hexToColor(dayData[dayNumber]!['color']);
                    } else {
                      circleColor = Colors.green; // Default for days with data
                    }
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
                            double weightValue = extractWeightValue(weightStr);

                            // Convert to appropriate unit for display in the text field
                            if (_isKgUnit) {
                              // If weight stored in grams but display in kg
                              if (weightStr.contains('grams')) {
                                _weightController.text = (weightValue / 1000)
                                    .toStringAsFixed(2);
                              } else {
                                _weightController.text = weightValue
                                    .toStringAsFixed(2);
                              }
                            } else {
                              // If weight stored in kg but display in grams
                              if (weightStr.contains('kg')) {
                                _weightController.text = (weightValue * 1000)
                                    .toStringAsFixed(0);
                              } else {
                                _weightController.text = weightValue
                                    .toStringAsFixed(0);
                              }
                            }

                            // Update date field
                            _selectedDate =
                                dayData[selectedDay]!['date'] as DateTime;
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate);

                            // Update weight status message and color
                            _weightStatusMessage =
                                dayData[selectedDay]!['message'];
                            _weightStatusColor = hexToColor(
                              dayData[selectedDay]!['color'],
                            );
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

                            // Clear status message for new entry
                            _weightStatusMessage = null;
                            _weightStatusColor = Colors.grey;

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
                                double weightValue = extractWeightValue(
                                  weightStr,
                                );

                                // Convert to appropriate unit for display in the text field
                                if (_isKgUnit) {
                                  // If weight stored in grams but display in kg
                                  if (weightStr.contains('grams')) {
                                    _weightController.text =
                                        (weightValue / 1000).toStringAsFixed(2);
                                  } else {
                                    _weightController.text = weightValue
                                        .toStringAsFixed(2);
                                  }
                                } else {
                                  // If weight stored in kg but display in grams
                                  if (weightStr.contains('kg')) {
                                    _weightController.text =
                                        (weightValue * 1000).toStringAsFixed(0);
                                  } else {
                                    _weightController.text = weightValue
                                        .toStringAsFixed(0);
                                  }
                                }

                                // Update weight status message and color
                                _weightStatusMessage =
                                    dayData[existingDay]!['message'];
                                _weightStatusColor = hexToColor(
                                  dayData[existingDay]!['color'],
                                );
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
          'message': null,
          'color': '#808080', // Default gray
        };

    // Format the date
    String dateStr =
        data['date'] is DateTime
            ? DateFormat('dd MMM yyyy').format(data['date'] as DateTime)
            : DateFormat('dd MMM yyyy').format(_selectedDate);

    // Get weight status message
    String weightStatusText = data['message'] ?? 'No weight data available';
    Color statusColor =
        data.containsKey('color') ? hexToColor(data['color']) : Colors.grey;

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
              Expanded(child: _buildInfoItem('Weight', data['weight'])),
              SizedBox(width: 20),
              Expanded(child: _buildInfoItem('Date', dateStr)),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(data['category'] ?? 'normal'),
                  color: statusColor,
                  size: 24,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    weightStatusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
        height: 420,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12),
              Text(
                'No weight data available yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add weight measurements to see progress',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Sort entries by date for chronological chart
    List<MapEntry<int, double>> sortedEntries = [];

    for (var entry in weightData.entries) {
      if (dayToDateMap.containsKey(entry.key)) {
        sortedEntries.add(entry);
      }
    }

    sortedEntries.sort((a, b) {
      final dateA = dayToDateMap[a.key]!;
      final dateB = dayToDateMap[b.key]!;
      return dateA.compareTo(dateB);
    });

    // Calculate days since birth for x-axis and prepare spots data
    List<FlSpot> spots = [];
    List<Color> spotColors = [];

    for (var entry in sortedEntries) {
      final dayNumber = entry.key;
      final date = dayToDateMap[dayNumber]!;
      final birthDate = _child!.dateOfBirth;
      final daysSinceBirth = date.difference(birthDate).inDays;
      final weightValue = entry.value / 1000;

      spots.add(FlSpot(daysSinceBirth.toDouble(), weightValue));

      // Improved color coding based on weight category
      Color spotColor = const Color(0xFF1873EA); // Default blue for normal
      if (dayData.containsKey(dayNumber) &&
          dayData[dayNumber]!.containsKey('category')) {
        final category = dayData[dayNumber]!['category'];
        switch (category) {
          case 'minus3SD': // Severely Underweight
            spotColor = Colors.red;
            break;
          case 'minus2SD': // Underweight
            spotColor = Colors.orange;
            break;
          case 'normal': // Normal
            spotColor = Colors.green;
            break;
          case 'plus2SD': // Overweight
            spotColor = Colors.orange;
            break;
          case 'plus3SD': // Severely Overweight
            spotColor = Colors.red;
            break;
          default:
            spotColor = const Color(0xFF1873EA);
        }
      }
      spotColors.add(spotColor);
    }

    if (spots.isEmpty) {
      return Container(
        width: double.infinity,
        height: 420,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFF1873EA)),
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
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

    // x axis calculation
    double dataMaxX = maxX;
    double whoMaxX = 0;
    double whoMinX = double.infinity;

    if (_whoStandardLines.isNotEmpty) {
      for (var line in _whoStandardLines.values) {
        if (line.isNotEmpty) {
          double lineMaxX = line
              .map((e) => e.x)
              .reduce((a, b) => a > b ? a : b);
          double lineMinX = line
              .map((e) => e.x)
              .reduce((a, b) => a < b ? a : b);
          if (lineMaxX > whoMaxX) whoMaxX = lineMaxX;
          if (lineMinX < whoMinX) whoMinX = lineMinX;
        }
      }
    } else {
      whoMaxX = 0;
      whoMinX = 0;
    }

    double overallMaxX =
        [dataMaxX, whoMaxX].reduce((a, b) => a > b ? a : b) + 5;
    double overallMinX = [minX, whoMinX].reduce((a, b) => a < b ? a : b) - 5;
    overallMinX = overallMinX < 0 ? 0 : overallMinX;

    final minXAdjusted = overallMinX;
    final maxXAdjusted = overallMaxX;

    //Y axis calculation
    double finalMinY = minY;
    double finalMaxY = maxY;

    if (_whoStandardLines.isNotEmpty) {
      for (var line in _whoStandardLines.values) {
        if (line.isNotEmpty) {
          var filteredLine =
              line
                  .where(
                    (spot) =>
                        spot.x >= (minXAdjusted) && spot.x <= (maxXAdjusted),
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

    double yRange = finalMaxY - finalMinY;
    double yBuffer = yRange * 0.15;

    finalMinY = (finalMinY - yBuffer).floorToDouble();
    finalMaxY = (finalMaxY + yBuffer).ceilToDouble();

    if (finalMaxY - finalMinY < 1.0) {
      double midpoint = (finalMaxY + finalMinY) / 2;
      finalMinY = midpoint - 0.5;
      finalMaxY = midpoint + 0.5;
    }

    if (finalMinY > 0 && finalMinY < 1.0) {
      finalMinY = 0;
    }

    if (_whoStandardLines.isEmpty && !_isLoadingStandards && _child != null) {
      _isLoadingStandards = true;
      _loadWHOStandardLines();
    }

    // Calculate chart width
    double chartWidth = (maxXAdjusted - minXAdjusted) * 10.0;
    chartWidth = chartWidth < 900 ? 900 : chartWidth;

    return Container(
      width: double.infinity,
      height: 580, // Increased height significantly for more tooltip space
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.5,
            color: const Color(0xFF1873EA).withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12.0,
          16.0,
          16.0,
          3.0,
        ), // Less left padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved styling
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1873EA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        size: 20,
                        color: Color(0xFF1873EA),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Weight Progress',
                      style: TextStyle(
                        color: const Color(0xFF1873EA),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Weight (kg)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showWHOStandardsInfo(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF1873EA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF1873EA),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),

            // Improved Legend
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ), // NEW
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImprovedLegendItem(
                    'Your Baby',
                    const Color(0xFF1873EA),
                    isLine: true,
                    width: 3.0,
                  ),
                  _buildImprovedLegendItem(
                    'WHO Median',
                    Colors.green,
                    isLine: true,
                    width: 2.0,
                  ),
                  _buildImprovedLegendItem(
                    'Normal Range',
                    Colors.orange.withOpacity(0.8),
                    isDashed: true,
                  ),
                  _buildImprovedLegendItem(
                    'Extreme Range',
                    Colors.red.withOpacity(0.8),
                    isDashed: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Chart with improved spacing
            Expanded(
              child:
                  _isLoadingStandards && spots.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF1873EA),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Loading WHO standards...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          right: 8,
                        ), // Removed left padding
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            width: chartWidth,
                            height: 380, // Increased chart area height
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 1.0,
                                  verticalInterval: 15,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 0.8,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 65,
                                      getTitlesWidget: (value, meta) {
                                        if (value < 0) {
                                          return const SizedBox();
                                        }

                                        final birthDate = _child!.dateOfBirth;
                                        final date = birthDate.add(
                                          Duration(days: value.toInt()),
                                        );

                                        final month = DateFormat(
                                          'MMM',
                                        ).format(date);
                                        final day = DateFormat(
                                          'd',
                                        ).format(date);

                                        return SideTitleWidget(
                                          angle: 0,
                                          space: 8,
                                          meta: meta,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  day,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  month,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      interval: 15,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value < 0) return const SizedBox();
                                        if (value.round() != value)
                                          return const SizedBox();

                                        String valueText =
                                            value.toInt().toString();

                                        return SideTitleWidget(
                                          angle: 0,
                                          space: 12, // Increased space
                                          meta: meta,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              valueText,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      reservedSize:
                                          45, // Slightly reduced reserved size
                                      interval: 1.0,
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                minX: minXAdjusted,
                                maxX: maxXAdjusted,
                                minY: finalMinY,
                                maxY:
                                    finalMaxY +
                                    0.5, // Add small buffer to prevent cutoff
                                clipData:
                                    FlClipData.all(), // This helps with tooltip positioning
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor:
                                        (touchedSpot) => const Color.fromARGB(
                                          255,
                                          248,
                                          245,
                                          245,
                                        ),
                                    tooltipRoundedRadius: 16,
                                    tooltipPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    tooltipMargin:
                                        20, // Add margin to prevent cutoff
                                    fitInsideHorizontally:
                                        true, // Keep tooltip inside chart
                                    fitInsideVertically:
                                        true, // Keep tooltip inside chart
                                    tooltipBorder: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 1.5,
                                    ),
                                    getTooltipItems: (
                                      List<LineBarSpot> touchedSpots,
                                    ) {
                                      return touchedSpots.map((spot) {
                                        // Check if this is a WHO standard line
                                        for (var entry
                                            in _whoStandardLines.entries) {
                                          final lineType = entry.key;
                                          final line = entry.value;

                                          bool isWHOLine = line.any(
                                            (s) =>
                                                (s.x - spot.x).abs() < 0.1 &&
                                                (s.y - spot.y).abs() < 0.1,
                                          );

                                          if (isWHOLine) {
                                            String lineLabel = "";
                                            Color lineColor = Colors.black87;

                                            switch (lineType) {
                                              case 'minus3SD':
                                                lineLabel = "SD -3 (Severe)";
                                                lineColor = Colors.red.shade700;
                                                break;
                                              case 'minus2SD':
                                                lineLabel =
                                                    "SD -2 (Underweight)";
                                                lineColor =
                                                    Colors.orange.shade700;
                                                break;
                                              case 'median':
                                                lineLabel = "WHO Median";
                                                lineColor =
                                                    Colors.green.shade700;
                                                break;
                                              case 'plus2SD':
                                                lineLabel =
                                                    "SD +2 (Overweight)";
                                                lineColor =
                                                    Colors.orange.shade700;
                                                break;
                                              case 'plus3SD':
                                                lineLabel = "SD +3 (Severe)";
                                                lineColor = Colors.red.shade700;
                                                break;
                                              default:
                                                lineLabel = lineType;
                                            }

                                            String weightText =
                                                '${spot.y.toStringAsFixed(1)} kg';

                                            return LineTooltipItem(
                                              '$lineLabel\n$weightText',
                                              TextStyle(
                                                color: lineColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            );
                                          }
                                        }

                                        // Baby's data point
                                        int dayNumber = -1;
                                        for (var entry in sortedEntries) {
                                          final days =
                                              dayToDateMap[entry.key]!
                                                  .difference(
                                                    _child!.dateOfBirth,
                                                  )
                                                  .inDays;
                                          double weight = entry.value / 1000;

                                          if ((days.toDouble() - spot.x).abs() <
                                                  0.1 &&
                                              (weight - spot.y).abs() < 0.1) {
                                            dayNumber = entry.key;
                                            break;
                                          }
                                        }

                                        if (dayNumber > 0) {
                                          final date = dayToDateMap[dayNumber]!;
                                          final dateStr = DateFormat(
                                            'd MMM yyyy',
                                          ).format(date);

                                          String category = "Normal";
                                          Color categoryColor =
                                              Colors.green.shade700;

                                          if (dayData.containsKey(dayNumber) &&
                                              dayData[dayNumber]!.containsKey(
                                                'category',
                                              )) {
                                            switch (dayData[dayNumber]!['category']) {
                                              case 'minus3SD':
                                                category =
                                                    "Severly Underweight";
                                                categoryColor =
                                                    Colors.red.shade700;
                                                break;
                                              case 'minus2SD':
                                                category = "Underweight";
                                                categoryColor =
                                                    Colors.orange.shade700;
                                                break;
                                              case 'normal':
                                                category = "Normal";
                                                categoryColor =
                                                    Colors.green.shade700;
                                                break;
                                              case 'plus2SD':
                                                category = "Overweight";
                                                categoryColor =
                                                    Colors.orange.shade700;
                                                break;
                                              case 'plus3SD':
                                                category =
                                                    "Severely Overweight";
                                                categoryColor =
                                                    Colors.red.shade700;
                                                break;
                                            }
                                          }

                                          String weightText =
                                              '${spot.y.toStringAsFixed(1)} kg';

                                          return LineTooltipItem(
                                            '$dateStr\n$weightText\n$category',
                                            TextStyle(
                                              color: categoryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          );
                                        }

                                        return LineTooltipItem(
                                          'Unknown point',
                                          TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                  handleBuiltInTouches: true,
                                ),
                                lineBarsData: [
                                  // WHO standard lines
                                  if (_whoStandardLines.containsKey('minus3SD'))
                                    LineChartBarData(
                                      spots: _whoStandardLines['minus3SD']!,
                                      isCurved: true,
                                      color: Colors.red.withOpacity(0.8),
                                      barWidth: 1.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      dashArray: [6, 4],
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  if (_whoStandardLines.containsKey('minus2SD'))
                                    LineChartBarData(
                                      spots: _whoStandardLines['minus2SD']!,
                                      isCurved: true,
                                      color: Colors.orange.withOpacity(0.8),
                                      barWidth: 1.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      dashArray: [6, 4],
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  if (_whoStandardLines.containsKey('median'))
                                    LineChartBarData(
                                      spots: _whoStandardLines['median']!,
                                      isCurved: true,
                                      color: Colors.green,
                                      barWidth: 2.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  if (_whoStandardLines.containsKey('plus2SD'))
                                    LineChartBarData(
                                      spots: _whoStandardLines['plus2SD']!,
                                      isCurved: true,
                                      color: Colors.orange.withOpacity(0.8),
                                      barWidth: 1.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      dashArray: [6, 4],
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  if (_whoStandardLines.containsKey('plus3SD'))
                                    LineChartBarData(
                                      spots: _whoStandardLines['plus3SD']!,
                                      isCurved: true,
                                      color: Colors.red.withOpacity(0.8),
                                      barWidth: 1.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      dashArray: [6, 4],
                                      belowBarData: BarAreaData(show: false),
                                    ),

                                  // Main weight data line
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: const Color(0xFF1873EA),
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (
                                        spot,
                                        percent,
                                        barData,
                                        index,
                                      ) {
                                        Color dotColor =
                                            index < spotColors.length
                                                ? spotColors[index]
                                                : const Color(0xFF1873EA);

                                        return FlDotCirclePainter(
                                          radius: 6,
                                          color: dotColor,
                                          strokeWidth: 3,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(
                                        0xFF1873EA,
                                      ).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for improved legend items
  Widget _buildImprovedLegendItem(
    String label,
    Color color, {
    bool isLine = false,
    double width = 1.0,
    bool isDashed = false,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child:
              isDashed
                  ? CustomPaint(
                    painter: DashedLinePainter(
                      color: color,
                      strokeWidth: width,
                    ),
                  )
                  : null,
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
            // Weight Input with unit toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Weight",
                    style: TextStyle(
                      color: const Color(0xFF1873EA),
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Unit toggle switch
                Row(
                  children: [
                    Text(
                      "grams",
                      style: TextStyle(
                        color: !_isKgUnit ? Colors.black : Colors.grey,
                        fontSize: 12,
                        fontWeight:
                            !_isKgUnit ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Switch(
                      value: _isKgUnit,
                      activeColor: Color(0xFF1873EA),
                      onChanged: (value) {
                        setState(() {
                          _isKgUnit = value;

                          // Convert text field value if it's not empty
                          if (_weightController.text.isNotEmpty) {
                            try {
                              double currentValue = double.parse(
                                _weightController.text,
                              );
                              if (value) {
                                // Switching to kg
                                _weightController.text = (currentValue / 1000)
                                    .toStringAsFixed(2);
                              } else {
                                // Switching to grams
                                _weightController.text = (currentValue * 1000)
                                    .toStringAsFixed(0);
                              }
                            } catch (e) {
                              // Just clear the field if conversion fails
                              _weightController.text = '';
                            }
                          }
                          // Reload WHO standard lines with new unit
                          if (_whoStandardLines.isNotEmpty) {
                            _isLoadingStandards = true;
                            _loadWHOStandardLines();
                          }
                        });
                      },
                    ),
                    Text(
                      "kg",
                      style: TextStyle(
                        color: _isKgUnit ? Colors.black : Colors.grey,
                        fontSize: 12,
                        fontWeight:
                            _isKgUnit ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText:
                    _isKgUnit
                        ? "Enter baby's weight in kg"
                        : "Enter baby's weight in grams",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixText: _isKgUnit ? "kg" : "g",
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

                // Check for unrealistic values based on unit
                if (_isKgUnit) {
                  // For kg, 20kg is a reasonable upper limit for babies/infants
                  if (weight > 20) {
                    return 'Weight seems too high';
                  }
                } else {
                  // For grams, 20,000g (20kg) is a reasonable upper limit
                  if (weight > 20000) {
                    return 'Weight seems too high';
                  }
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

            // Display weight status message when input is provided
            if (_weightStatusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _weightStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _weightStatusColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(
                          dayData[selectedDay]?['category'] ?? 'normal',
                        ),
                        color: _weightStatusColor,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _weightStatusMessage!,
                          style: TextStyle(
                            color: _weightStatusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            // After your Save button widget:
            SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showDeleteWeightsDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(200, 48),
                ),
                child: Text(
                  'Delete Weight',
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

  Future<void> _showDeleteWeightsDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dailyWeightsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('children')
              .doc(widget.childId)
              .collection('dailyWeights')
              .orderBy('date', descending: true)
              .get();

      final weights = dailyWeightsSnapshot.docs;

      if (weights.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No weight entries found to delete.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<String> selectedIds = [];

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: EdgeInsets.all(20),
                  width: double.maxFinite,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select weights to delete',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true, // always show scrollbar thumb
                          thickness:
                              4, // thicker scrollbar for better visibility
                          radius: Radius.circular(8),
                          child: ListView.builder(
                            itemCount: weights.length,
                            itemBuilder: (context, index) {
                              final doc = weights[index];
                              final data = doc.data();

                              final date = (data['date'] as Timestamp).toDate();
                              final weightInKg = (data['weight'] ?? 0) / 1000.0;

                              final formattedDate = DateFormat(
                                'dd/MM/yyyy',
                              ).format(date);
                              final label =
                                  '$formattedDate - Weight: ${weightInKg.toStringAsFixed(2)} kg';

                              final isSelected = selectedIds.contains(doc.id);

                              return Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 0,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Colors
                                            .blueAccent, // same color as the bullet
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedIds.add(doc.id);
                                      } else {
                                        selectedIds.remove(doc.id);
                                      }
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors
                                                  .blueAccent, // same accent color
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              textStyle: TextStyle(fontSize: 16),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed:
                                selectedIds.isEmpty
                                    ? null
                                    : () async {
                                      Navigator.pop(context);
                                      await _deleteSelectedWeights(selectedIds);
                                    },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color:
                                    Colors.white, // White text for red button
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load weights: $e')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteSelectedWeights(List<String> ids) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final dailyWeightsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(widget.childId)
          .collection('dailyWeights');

      // Step 1: Delete documents
      final batch = FirebaseFirestore.instance.batch();
      for (String id in ids) {
        final docRef = dailyWeightsCollection.doc(id);
        batch.delete(docRef);
      }
      await batch.commit();

      debugPrint('Deleted ${ids.length} weight documents');

      // Step 2: Reassign day numbers chronologically
      if (_child != null) {
        await _childService.reassignDayNumbersChronologically(
          widget.childId,
          _child!.dateOfBirth,
        );
        debugPrint('Reassigned day numbers after deletion');
      }

      // Step 3: Update current weight to latest
      await _childService.updateCurrentWeightToLatest(widget.childId);

      // Step 4: Force immediate UI refresh
      await _forceUIRefreshAfterDeletion();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${ids.length} weight entries and updated day numbers.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete weights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
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

  //Weights in chronological order
  Future<void> _reassignDayNumbersChronologically() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final dailyWeightsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(widget.childId)
          .collection('dailyWeights');

      // Get all weight documents
      final snapshot = await dailyWeightsCollection.get();

      if (snapshot.docs.isEmpty) return;

      // Create a list of documents with their dates
      List<Map<String, dynamic>> documentsWithDates = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        documentsWithDates.add({
          'docId': doc.id,
          'date': normalizeDate(date),
          'weight': data['weight'],
          'originalDayNumber': data['dayNumber'],
        });
      }

      // Sort by date (chronological order)
      documentsWithDates.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      // Batch update to reassign day numbers
      final batch = FirebaseFirestore.instance.batch();

      // Start from day 2 (day 1 is always birth date)
      int newDayNumber = 2;

      for (var docData in documentsWithDates) {
        final docRef = dailyWeightsCollection.doc(docData['docId']);

        // Check if this is birth date
        final docDate = docData['date'] as DateTime;
        final birthDate = normalizeDate(_child!.dateOfBirth);

        if (docDate.isAtSameMomentAs(birthDate)) {
          // This is birth date, should be day 1
          batch.update(docRef, {'dayNumber': 1});
        } else {
          // Regular date, assign chronological day number
          batch.update(docRef, {'dayNumber': newDayNumber});
          newDayNumber++;
        }
      }

      // Commit the batch update
      await batch.commit();

      print('Successfully reassigned day numbers chronologically');
    } catch (e) {
      print('Error reassigning day numbers: $e');
      throw e;
    }
  }

  // Helper method to update current weight to the latest chronological entry
  Future<void> _updateCurrentWeightToLatest() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final dailyWeightsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(widget.childId)
          .collection('dailyWeights');

      // Get the latest weight entry by date
      final latestSnapshot =
          await dailyWeightsCollection
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (latestSnapshot.docs.isNotEmpty) {
        final latestWeight =
            latestSnapshot.docs.first.data()['weight'] as double;

        await _childService.updateChild(widget.childId, {
          'currentWeight': latestWeight,
        });
      }
    } catch (e) {
      print('Error updating current weight: $e');
    }
  }

  // Add this as a new method
  Future<void> _forceUIRefreshAfterDeletion() async {
    try {
      // Clear current data
      setState(() {
        dayData.clear();
        dateToDayMap.clear();
        dayToDateMap.clear();
        weightData.clear();
        weightCategoryData.clear();
        _lastDayNumber = 0;
        selectedDay = 1;
      });

      // Force reload child data
      await _loadChildData();

      // Reload WHO standards if needed
      if (!_isLoadingStandards && _whoStandardLines.isEmpty) {
        _isLoadingStandards = true;
        _loadWHOStandardLines();
      }
    } catch (e) {
      debugPrint('Error forcing UI refresh: $e');
    }
  }
}

class Math {
  static int max(int a, int b) {
    return a > b ? a : b;
  }
}

// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedLinePainter({required this.color, this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    double dashWidth = 4, dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

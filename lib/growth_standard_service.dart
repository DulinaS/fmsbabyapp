import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GrowthStandardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the growth standards collection
  CollectionReference get _growthStandardsCollection =>
      _firestore.collection('growthStandards');

  // Initialize the weight ranges collection with WHO standards
  Future<void> initializeWeightRanges() async {
    try {
      // Create separate documents for boys and girls
      await _initializeGirlWeightRanges();
      await _initializeBoyWeightRanges();

      print('Weight ranges initialized successfully');
    } catch (e) {
      print('Error initializing weight ranges: $e');
      throw Exception('Failed to initialize weight ranges');
    }
  }

  // Initialize weight ranges for girls
  Future<void> _initializeGirlWeightRanges() async {
    // Reference to girls weight ranges document
    DocumentReference girlRangesDoc = _growthStandardsCollection.doc(
      'girls_weight',
    );

    // Data structure with ranges for different ages
    // We'll store the thresholds for different SD lines (-3SD, -2SD, median, +1SD, +2SD, +3SD)
    // Values are in grams, derived from the WHO growth standards charts
    final girlWeightRanges = {
      // Monthly data for the first year (simplified to key milestones)
      'months': {
        '0': {
          // Birth
          'minus3SD': 2000,
          'minus2SD': 2400,
          'median': 3200,
          'plus1SD': 3600,
          'plus2SD': 4200,
          'plus3SD': 4800,
        },
        '1': {
          'minus3SD': 2700,
          'minus2SD': 3200,
          'median': 4300,
          'plus1SD': 4700,
          'plus2SD': 5400,
          'plus3SD': 6000,
        },
        '2': {
          'minus3SD': 3400,
          'minus2SD': 3900,
          'median': 5100,
          'plus1SD': 5700,
          'plus2SD': 6300,
          'plus3SD': 7000,
        },
        '3': {
          'minus3SD': 3900,
          'minus2SD': 4500,
          'median': 5800,
          'plus1SD': 6400,
          'plus2SD': 7000,
          'plus3SD': 7900,
        },
        '6': {
          'minus3SD': 5000,
          'minus2SD': 5700,
          'median': 7200,
          'plus1SD': 7900,
          'plus2SD': 8700,
          'plus3SD': 9800,
        },
        '9': {
          'minus3SD': 5900,
          'minus2SD': 6700,
          'median': 8200,
          'plus1SD': 9100,
          'plus2SD': 10000,
          'plus3SD': 11200,
        },
        '12': {
          // 1 year
          'minus3SD': 6300,
          'minus2SD': 7200,
          'median': 8900,
          'plus1SD': 9900,
          'plus2SD': 11000,
          'plus3SD': 12300,
        },
      },
      // Yearly data after first year
      'years': {
        '1': {
          // Same as month 12
          'minus3SD': 6300,
          'minus2SD': 7200,
          'median': 8900,
          'plus1SD': 9900,
          'plus2SD': 11000,
          'plus3SD': 12300,
        },
        '2': {
          'minus3SD': 8200,
          'minus2SD': 9200,
          'median': 11500,
          'plus1SD': 12800,
          'plus2SD': 14300,
          'plus3SD': 16000,
        },
        '3': {
          'minus3SD': 9600,
          'minus2SD': 10800,
          'median': 13900,
          'plus1SD': 15500,
          'plus2SD': 17300,
          'plus3SD': 19500,
        },
        '4': {
          'minus3SD': 11000,
          'minus2SD': 12200,
          'median': 16300,
          'plus1SD': 18200,
          'plus2SD': 20400,
          'plus3SD': 23000,
        },
        '5': {
          'minus3SD': 12200,
          'minus2SD': 13600,
          'median': 18200,
          'plus1SD': 20500,
          'plus2SD': 23500,
          'plus3SD': 27000,
        },
      },
      'categories': {
        'minus3SD': {
          'name': 'Severely Underweight',
          'color': '#FF0000', // Red
          'message':
              'Urgent: Baby weight is extremely low. Please consult a doctor immediately.',
        },
        'minus2SD': {
          'name': 'Underweight',
          'color': '#FFA500', // Orange
          'message':
              'Caution: Baby weight is below the healthy range. Consider consulting a doctor.',
        },
        'normal': {
          'name': 'Normal',
          'color': '#4CAF50', // Green
          'message': 'Good: Baby weight is within the healthy range.',
        },
        'plus2SD': {
          'name': 'Overweight',
          'color': '#FFA500', // Orange
          'message':
              'Caution: Baby weight is above the healthy range. Consider consulting a doctor.',
        },
        'plus3SD': {
          'name': 'Extremely Overweight',
          'color': '#FF0000', // Red
          'message':
              'Urgent: Baby weight is extremely high. Please consult a doctor.',
        },
      },
    };

    // Set the data in Firestore
    await girlRangesDoc.set(girlWeightRanges);
  }

  // Initialize weight ranges for boys
  Future<void> _initializeBoyWeightRanges() async {
    // Reference to boys weight ranges document
    DocumentReference boyRangesDoc = _growthStandardsCollection.doc(
      'boys_weight',
    );

    // Data structure with ranges for different ages
    // We'll store the thresholds for different SD lines (-3SD, -2SD, median, +1SD, +2SD, +3SD)
    // Values are in grams, derived from the WHO growth standards charts
    final boyWeightRanges = {
      // Monthly data for the first year (simplified to key milestones)
      'months': {
        '0': {
          // Birth
          'minus3SD': 2200,
          'minus2SD': 2500,
          'median': 3300,
          'plus1SD': 3900,
          'plus2SD': 4500,
          'plus3SD': 5000,
        },
        '1': {
          'minus3SD': 3000,
          'minus2SD': 3600,
          'median': 4500,
          'plus1SD': 5100,
          'plus2SD': 5800,
          'plus3SD': 6500,
        },
        '2': {
          'minus3SD': 3800,
          'minus2SD': 4500,
          'median': 5600,
          'plus1SD': 6300,
          'plus2SD': 7000,
          'plus3SD': 7800,
        },
        '3': {
          'minus3SD': 4500,
          'minus2SD': 5100,
          'median': 6400,
          'plus1SD': 7200,
          'plus2SD': 8000,
          'plus3SD': 8900,
        },
        '6': {
          'minus3SD': 5700,
          'minus2SD': 6400,
          'median': 7900,
          'plus1SD': 8800,
          'plus2SD': 9800,
          'plus3SD': 10900,
        },
        '9': {
          'minus3SD': 6600,
          'minus2SD': 7400,
          'median': 8900,
          'plus1SD': 10000,
          'plus2SD': 11000,
          'plus3SD': 12300,
        },
        '12': {
          // 1 year
          'minus3SD': 7000,
          'minus2SD': 7900,
          'median': 9600,
          'plus1SD': 10800,
          'plus2SD': 12000,
          'plus3SD': 13500,
        },
      },
      // Yearly data after first year
      'years': {
        '1': {
          // Same as month 12
          'minus3SD': 7000,
          'minus2SD': 7900,
          'median': 9600,
          'plus1SD': 10800,
          'plus2SD': 12000,
          'plus3SD': 13500,
        },
        '2': {
          'minus3SD': 8800,
          'minus2SD': 9800,
          'median': 12200,
          'plus1SD': 13700,
          'plus2SD': 15400,
          'plus3SD': 17200,
        },
        '3': {
          'minus3SD': 10200,
          'minus2SD': 11500,
          'median': 14300,
          'plus1SD': 16200,
          'plus2SD': 18200,
          'plus3SD': 20500,
        },
        '4': {
          'minus3SD': 11500,
          'minus2SD': 12900,
          'median': 16300,
          'plus1SD': 18500,
          'plus2SD': 21000,
          'plus3SD': 24000,
        },
        '5': {
          'minus3SD': 12700,
          'minus2SD': 14300,
          'median': 18400,
          'plus1SD': 21000,
          'plus2SD': 24000,
          'plus3SD': 27500,
        },
      },
      'categories': {
        'minus3SD': {
          'name': 'Severely Underweight',
          'color': '#FF0000', // Red
          'message':
              'Urgent: Baby weight is extremely low. Please consult a doctor immediately.',
        },
        'minus2SD': {
          'name': 'Underweight',
          'color': '#FFA500', // Orange
          'message':
              'Caution: Baby weight is below the healthy range. Consider consulting a doctor.',
        },
        'normal': {
          'name': 'Normal',
          'color': '#4CAF50', // Green
          'message': 'Good: Baby weight is within the healthy range.',
        },
        'plus2SD': {
          'name': 'Overweight',
          'color': '#FFA500', // Orange
          'message':
              'Caution: Baby weight is above the healthy range. Consider consulting a doctor.',
        },
        'plus3SD': {
          'name': 'Extremely Overweight',
          'color': '#FF0000', // Red
          'message':
              'Urgent: Baby weight is extremely high. Please consult a doctor.',
        },
      },
    };

    // Set the data in Firestore
    await boyRangesDoc.set(boyWeightRanges);
  }

  // Function to determine a baby's weight category based on age, weight, and gender
  Future<Map<String, dynamic>> determineWeightCategory(
    double weightInGrams,
    DateTime dateOfBirth,
    DateTime measurementDate,
    String gender,
  ) async {
    try {
      // Calculate age in months
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
        throw Exception('Growth standards not found');
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
        'ageInMonths': ageInMonths,
        'ageInYears': ageInYears,
        'ageKey': ageKey,
        'collection': collection,
      };
    } catch (e) {
      debugPrint('Error determining weight category: $e');
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

  // Get reference data for WHO weight charts
  Future<Map<String, dynamic>> getWeightStandardsData(String gender) async {
    try {
      final String genderDoc =
          gender.toLowerCase() == 'boy' ? 'boys_weight' : 'girls_weight';
      final docSnapshot = await _growthStandardsCollection.doc(genderDoc).get();

      if (!docSnapshot.exists) {
        throw Exception('Growth standards not found');
      }

      return docSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting weight standards: $e');
      throw Exception('Failed to get weight standards data');
    }
  }

  // Generate standard lines data for chart display
  Future<Map<String, List<Map<String, dynamic>>>> getStandardLinesData(
    String gender,
    DateTime birthDate, {
    int maxDays = 365, // Default to 1 year of data
  }) async {
    try {
      // Get the standards data
      final standardsData = await getWeightStandardsData(gender);

      // Lines we want to generate
      final lineTypes = [
        'minus3SD',
        'minus2SD',
        'median',
        'plus2SD',
        'plus3SD',
      ];
      Map<String, List<Map<String, dynamic>>> result = {};

      // Initialize result map
      for (final type in lineTypes) {
        result[type] = [];
      }

      // Generate points at regular intervals
      for (int dayNum = 0; dayNum <= maxDays; dayNum += 30) {
        // Monthly points
        final ageInDays = dayNum;
        final ageInMonths = ageInDays / 30.44;
        final ageInYears = ageInDays / 365.25;

        // Determine if we should use monthly or yearly data
        final String collection = ageInYears < 1 ? 'months' : 'years';

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
        final Map<String, dynamic> rangeValues =
            standardsData[collection][ageKey];

        // Calculate actual date for this age
        final measurementDate = birthDate.add(Duration(days: dayNum));

        // Add data points for each line
        for (final type in lineTypes) {
          result[type]!.add({
            'x': dayNum.toDouble(),
            'y': rangeValues[type].toDouble(),
            'date': measurementDate,
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error generating standard lines: $e');
      throw Exception('Failed to generate standard lines data');
    }
  }
}

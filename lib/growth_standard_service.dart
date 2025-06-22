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
    // Values are in kg, derived from the WHO growth standards charts
    final girlWeightRanges = {
      // Monthly data for the first year (simplified to key milestones)
      'months': {
        '0': {
          // Birth
          'minus3SD': 2.0,
          'minus2SD': 2.4,
          'median': 3.2,
          'plus1SD': 3.6,
          'plus2SD': 4.2,
          'plus3SD': 4.8,
        },
        '1': {
          'minus3SD': 2.7,
          'minus2SD': 3.2,
          'median': 4.3,
          'plus1SD': 4.7,
          'plus2SD': 5.4,
          'plus3SD': 6.0,
        },
        '2': {
          'minus3SD': 3.4,
          'minus2SD': 3.9,
          'median': 5.1,
          'plus1SD': 5.7,
          'plus2SD': 6.3,
          'plus3SD': 7.0,
        },
        '3': {
          'minus3SD': 3.9,
          'minus2SD': 4.5,
          'median': 5.8,
          'plus1SD': 6.4,
          'plus2SD': 7.0,
          'plus3SD': 7.9,
        },
        '6': {
          'minus3SD': 5.0,
          'minus2SD': 5.7,
          'median': 7.2,
          'plus1SD': 7.9,
          'plus2SD': 8.7,
          'plus3SD': 9.8,
        },
        '9': {
          'minus3SD': 5.9,
          'minus2SD': 6.7,
          'median': 8.2,
          'plus1SD': 9.1,
          'plus2SD': 10.0,
          'plus3SD': 11.2,
        },
        '12': {
          // 1 year
          'minus3SD': 6.3,
          'minus2SD': 7.2,
          'median': 8.9,
          'plus1SD': 9.9,
          'plus2SD': 11.0,
          'plus3SD': 12.3,
        },
      },
      // Yearly data after first year
      'years': {
        '1': {
          // Same as month 12
          'minus3SD': 6.3,
          'minus2SD': 7.2,
          'median': 8.9,
          'plus1SD': 9.9,
          'plus2SD': 11.0,
          'plus3SD': 12.3,
        },
        '2': {
          'minus3SD': 8.2,
          'minus2SD': 9.2,
          'median': 11.5,
          'plus1SD': 12.8,
          'plus2SD': 14.3,
          'plus3SD': 16.0,
        },
        '3': {
          'minus3SD': 9.6,
          'minus2SD': 10.8,
          'median': 13.9,
          'plus1SD': 15.5,
          'plus2SD': 17.3,
          'plus3SD': 19.5,
        },
        '4': {
          'minus3SD': 11.0,
          'minus2SD': 12.2,
          'median': 16.3,
          'plus1SD': 18.2,
          'plus2SD': 20.4,
          'plus3SD': 23.0,
        },
        '5': {
          'minus3SD': 12.2,
          'minus2SD': 13.6,
          'median': 18.2,
          'plus1SD': 20.5,
          'plus2SD': 23.5,
          'plus3SD': 27.0,
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
    // Values are in kg, derived from the WHO growth standards charts
    final boyWeightRanges = {
      // Monthly data for the first year (simplified to key milestones)
      'months': {
        '0': {
          // Birth
          'minus3SD': 2.2,
          'minus2SD': 2.5,
          'median': 3.3,
          'plus1SD': 3.9,
          'plus2SD': 4.5,
          'plus3SD': 5.0,
        },
        '1': {
          'minus3SD': 3.0,
          'minus2SD': 3.6,
          'median': 4.5,
          'plus1SD': 5.1,
          'plus2SD': 5.8,
          'plus3SD': 6.5,
        },
        '2': {
          'minus3SD': 3.8,
          'minus2SD': 4.5,
          'median': 5.6,
          'plus1SD': 6.3,
          'plus2SD': 7.0,
          'plus3SD': 7.8,
        },
        '3': {
          'minus3SD': 4.5,
          'minus2SD': 5.1,
          'median': 6.4,
          'plus1SD': 7.2,
          'plus2SD': 8.0,
          'plus3SD': 8.9,
        },
        '6': {
          'minus3SD': 5.7,
          'minus2SD': 6.4,
          'median': 7.9,
          'plus1SD': 8.8,
          'plus2SD': 9.8,
          'plus3SD': 10.9,
        },
        '9': {
          'minus3SD': 6.6,
          'minus2SD': 7.4,
          'median': 8.9,
          'plus1SD': 10.0,
          'plus2SD': 11.0,
          'plus3SD': 12.3,
        },
        '12': {
          // 1 year
          'minus3SD': 7.0,
          'minus2SD': 7.9,
          'median': 9.6,
          'plus1SD': 10.8,
          'plus2SD': 12.0,
          'plus3SD': 13.5,
        },
      },
      // Yearly data after first year
      'years': {
        '1': {
          // Same as month 12
          'minus3SD': 7.0,
          'minus2SD': 7.9,
          'median': 9.6,
          'plus1SD': 10.8,
          'plus2SD': 12.0,
          'plus3SD': 13.5,
        },
        '2': {
          'minus3SD': 8.8,
          'minus2SD': 9.8,
          'median': 12.2,
          'plus1SD': 13.7,
          'plus2SD': 15.4,
          'plus3SD': 17.2,
        },
        '3': {
          'minus3SD': 10.2,
          'minus2SD': 11.5,
          'median': 14.3,
          'plus1SD': 16.2,
          'plus2SD': 18.2,
          'plus3SD': 20.5,
        },
        '4': {
          'minus3SD': 11.5,
          'minus2SD': 12.9,
          'median': 16.3,
          'plus1SD': 18.5,
          'plus2SD': 21.0,
          'plus3SD': 24.0,
        },
        '5': {
          'minus3SD': 12.7,
          'minus2SD': 14.3,
          'median': 18.4,
          'plus1SD': 21.0,
          'plus2SD': 24.0,
          'plus3SD': 27.5,
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
    double weightInKg, // Changed parameter name and comment
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

      // Determine weight category - now comparing kg to kg values
      String category;
      if (weightInKg < rangeValues['minus3SD']) {
        category = 'minus3SD';
      } else if (weightInKg < rangeValues['minus2SD']) {
        category = 'minus2SD';
      } else if (weightInKg < rangeValues['plus2SD']) {
        category = 'normal';
      } else if (weightInKg < rangeValues['plus3SD']) {
        category = 'plus2SD';
      } else {
        category = 'plus3SD';
      }

      // Return category info with range values for reference
      return {
        'category': category,
        'info': categories[category],
        'ranges': rangeValues,
        'actualWeight': weightInKg, // Changed variable name
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
        'actualWeight': weightInKg, // Changed variable name
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

  /* // Generate standard lines data for chart display
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

        // Add data points for each line - values are already in kg
        for (final type in lineTypes) {
          result[type]!.add({
            'x': dayNum.toDouble(),
            'y':
                rangeValues[type]
                    .toDouble(), // Already in kg, no conversion needed
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
 */
  // REPLACE THE getStandardLinesData METHOD IN growth_standard_service.dart
  // Find this method and replace it entirely with this improved version:

  // Generate standard lines data for chart display with smooth interpolation
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

      // Helper function to interpolate weight between two age milestones
      double interpolateWeight(
        Map<String, dynamic> lowerAgeData,
        Map<String, dynamic> upperAgeData,
        double actualAge,
        double lowerAge,
        double upperAge,
        String lineType,
      ) {
        if (actualAge <= lowerAge) return lowerAgeData[lineType].toDouble();
        if (actualAge >= upperAge) return upperAgeData[lineType].toDouble();

        // Linear interpolation between the two age points
        double ratio = (actualAge - lowerAge) / (upperAge - lowerAge);
        double lowerWeight = lowerAgeData[lineType].toDouble();
        double upperWeight = upperAgeData[lineType].toDouble();

        return lowerWeight + ratio * (upperWeight - lowerWeight);
      }

      // Helper function to get weight for any age with interpolation
      double getWeightForAge(double ageInMonths, String lineType) {
        // Determine if we should use monthly or yearly data primarily
        if (ageInMonths <= 12) {
          // Use monthly data with interpolation
          final monthlyData = standardsData['months'] as Map<String, dynamic>;
          final availableMonths = [0, 1, 2, 3, 6, 9, 12];

          // Find the two closest age milestones
          int lowerIndex = 0;
          int upperIndex = availableMonths.length - 1;

          for (int i = 0; i < availableMonths.length - 1; i++) {
            if (ageInMonths >= availableMonths[i] &&
                ageInMonths <= availableMonths[i + 1]) {
              lowerIndex = i;
              upperIndex = i + 1;
              break;
            }
          }

          final lowerAge = availableMonths[lowerIndex].toDouble();
          final upperAge = availableMonths[upperIndex].toDouble();
          final lowerAgeData = monthlyData[lowerAge.toInt().toString()];
          final upperAgeData = monthlyData[upperAge.toInt().toString()];

          return interpolateWeight(
            lowerAgeData,
            upperAgeData,
            ageInMonths,
            lowerAge,
            upperAge,
            lineType,
          );
        } else {
          // Use yearly data with interpolation
          final yearlyData = standardsData['years'] as Map<String, dynamic>;
          final ageInYears = ageInMonths / 12.0;
          final availableYears = [1, 2, 3, 4, 5];

          // Find the two closest age milestones
          int lowerIndex = 0;
          int upperIndex = availableYears.length - 1;

          for (int i = 0; i < availableYears.length - 1; i++) {
            if (ageInYears >= availableYears[i] &&
                ageInYears <= availableYears[i + 1]) {
              lowerIndex = i;
              upperIndex = i + 1;
              break;
            }
          }

          final lowerAge = availableYears[lowerIndex].toDouble();
          final upperAge = availableYears[upperIndex].toDouble();
          final lowerAgeData = yearlyData[lowerAge.toInt().toString()];
          final upperAgeData = yearlyData[upperAge.toInt().toString()];

          return interpolateWeight(
            lowerAgeData,
            upperAgeData,
            ageInYears,
            lowerAge,
            upperAge,
            lineType,
          );
        }
      }

      // Generate points at much higher frequency for smooth curves
      for (int dayNum = 0; dayNum <= maxDays; dayNum += 3) {
        // Every 3 days instead of 30
        final ageInDays = dayNum;
        final ageInMonths = ageInDays / 30.44; // Average days per month

        // Calculate actual date for this age
        final measurementDate = birthDate.add(Duration(days: dayNum));

        // Add data points for each line with interpolated values
        for (final type in lineTypes) {
          final interpolatedWeight = getWeightForAge(ageInMonths, type);

          result[type]!.add({
            'x': dayNum.toDouble(),
            'y': interpolatedWeight,
            'date': measurementDate,
          });
        }
      }

      // Add additional smoothing for very early days (0-30 days) for birth transition
      if (maxDays >= 30) {
        // Add daily points for first month for ultra-smooth birth transition
        Map<String, List<Map<String, dynamic>>> earlyResult = {};
        for (final type in lineTypes) {
          earlyResult[type] = [];
        }

        for (int dayNum = 0; dayNum <= 30; dayNum += 1) {
          // Daily for first month
          final ageInDays = dayNum;
          final ageInMonths = ageInDays / 30.44;
          final measurementDate = birthDate.add(Duration(days: dayNum));

          for (final type in lineTypes) {
            final interpolatedWeight = getWeightForAge(ageInMonths, type);

            earlyResult[type]!.add({
              'x': dayNum.toDouble(),
              'y': interpolatedWeight,
              'date': measurementDate,
            });
          }
        }

        // Merge early detailed data with regular data (remove duplicates)
        for (final type in lineTypes) {
          // Remove points from result that are in the first 30 days
          result[type]!.removeWhere((point) => point['x'] <= 30);

          // Add the detailed early points
          result[type]!.addAll(earlyResult[type]!);

          // Sort by x (day number) to maintain chronological order
          result[type]!.sort(
            (a, b) => (a['x'] as double).compareTo(b['x'] as double),
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error generating standard lines: $e');
      throw Exception('Failed to generate standard lines data');
    }
  }
}

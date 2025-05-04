import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final double? weight; // Birth weight in grams
  final double? height; // Birth height in cm
  final double? headCircumference; // Head circumference in cm
  final double? currentWeight;
  final double? currentHeight;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Child({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.weight,
    this.height,
    this.headCircumference,
    this.currentWeight,
    this.currentHeight,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate age in months
  int get ageInMonths {
    final now = DateTime.now();
    return ((now.year - dateOfBirth.year) * 12) + now.month - dateOfBirth.month;
  }

  // Format age for display (e.g., "2 years 3 months" or "5 months")
  String get formattedAge {
    final months = ageInMonths;
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years == 0) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      return '$years ${years == 1 ? 'year' : 'years'} ' +
          '$remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
    }
  }

  // Create Child object from Firestore document
  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Child(
      id: doc.id,
      name: data['name'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: data['gender'] ?? '',
      weight: data['weight']?.toDouble(),
      height: data['height']?.toDouble(),
      headCircumference: data['headCircumference']?.toDouble(),
      currentWeight: data['currentWeight']?.toDouble(),
      currentHeight: data['currentHeight']?.toDouble(),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Convert Child object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'weight': weight,
      'height': height,
      'headCircumference': headCircumference,
      'currentWeight':
          currentWeight ??
          weight, // Initially set current to birth weight if available
      'currentHeight':
          currentHeight ??
          height, // Initially set current to birth height if available
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int get ageInWeeks {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(dateOfBirth).inDays;
    return (difference / 7).ceil();
  }
}

// Model for growth measurements
class Measurement {
  final String id;
  final DateTime date;
  final double weight;
  final double height;
  final double? headCircumference;
  final String? notes;
  final DateTime createdAt;

  Measurement({
    required this.id,
    required this.date,
    required this.weight,
    required this.height,
    this.headCircumference,
    this.notes,
    required this.createdAt,
  });

  // Create Measurement object from Firestore document
  factory Measurement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Measurement(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: data['weight']?.toDouble() ?? 0.0,
      height: data['height']?.toDouble() ?? 0.0,
      headCircumference: data['headCircumference']?.toDouble(),
      notes: data['notes'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Convert Measurement object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'headCircumference': headCircumference,
      'notes': notes ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

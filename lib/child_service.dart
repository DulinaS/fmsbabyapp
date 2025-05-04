/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'child_model.dart';

class ChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  // Constructor requires user ID to associate children with their parent
  ChildService(this._userId);

  // Collection reference for this user's children
  CollectionReference get _childrenCollection => 
      _firestore.collection('users').doc(_userId).collection('children');

  // Add a new child
  Future<String> addChild({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    double? weight,
    double? height,
    double? headCircumference,
  }) async {
    try {
      // Create a new document reference
      final docRef = await _childrenCollection.add({
        'name': name,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'gender': gender,
        'weight': weight,
        'height': height,
        'headCircumference': headCircumference,
        'currentWeight': weight, // Initially set current to birth weight
        'currentHeight': height, // Initially set current to birth height
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the parent's numberOfChildren field
      await _firestore.collection('users').doc(_userId).update({
        'numberOfChildren': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding child: $e');
      throw Exception('Failed to add child');
    }
  }

  // Get all children for this user
  Stream<List<Child>> getChildren() {
    return _childrenCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Child.fromFirestore(doc)).toList());
  }

  // Get a specific child by ID
  Future<Child?> getChild(String childId) async {
    try {
      final doc = await _childrenCollection.doc(childId).get();
      if (doc.exists) {
        return Child.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting child: $e');
      return null;
    }
  }

  // Update a child's information
  Future<void> updateChild(String childId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt timestamp to the data
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _childrenCollection.doc(childId).update(data);
    } catch (e) {
      debugPrint('Error updating child: $e');
      throw Exception('Failed to update child');
    }
  }

  // Delete a child
  Future<void> deleteChild(String childId) async {
    try {
      await _childrenCollection.doc(childId).delete();
      
      // Update the parent's numberOfChildren field
      await _firestore.collection('users').doc(_userId).update({
        'numberOfChildren': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error deleting child: $e');
      throw Exception('Failed to delete child');
    }
  }

  // Add a new measurement for a child
  Future<String> addMeasurement(
    String childId, {
    required DateTime date,
    required double weight,
    required double height,
    double? headCircumference,
    String? notes,
  }) async {
    try {
      // Get measurements subcollection for this child
      final measurementsCollection = 
          _childrenCollection.doc(childId).collection('measurements');
      
      // Add new measurement
      final docRef = await measurementsCollection.add({
        'date': Timestamp.fromDate(date),
        'weight': weight,
        'height': height,
        'headCircumference': headCircumference,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update current measurements in the child document
      await _childrenCollection.doc(childId).update({
        'currentWeight': weight,
        'currentHeight': height,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding measurement: $e');
      throw Exception('Failed to add measurement');
    }
  }

  // Get all measurements for a child
  Stream<List<Measurement>> getMeasurements(String childId) {
    final measurementsCollection = 
        _childrenCollection.doc(childId).collection('measurements');

    return measurementsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Measurement.fromFirestore(doc)).toList());
  }
} */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/vaccination_service.dart';
import 'child_model.dart';

class ChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  // Constructor requires user ID to associate children with their parent
  ChildService(this._userId);

  // Collection reference for this user's children
  CollectionReference get _childrenCollection => 
      _firestore.collection('users').doc(_userId).collection('children');

  // Add a new child
  Future<String> addChild({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    double? weight,
    double? height,
    double? headCircumference,
  }) async {
    try {
      // Create a new document reference
      final docRef = await _childrenCollection.add({
        'name': name,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'gender': gender,
        'weight': weight,
        'height': height,
        'headCircumference': headCircumference,
        'currentWeight': weight, // Initially set current to birth weight
        'currentHeight': height, // Initially set current to birth height
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the parent's numberOfChildren field
      await _firestore.collection('users').doc(_userId).update({
        'numberOfChildren': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding child: $e');
      throw Exception('Failed to add child');
    }
  }

  // Get all children for this user
  Stream<List<Child>> getChildren() {
    return _childrenCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Child.fromFirestore(doc)).toList());
  }

  // Get a specific child by ID
  Future<Child?> getChild(String childId) async {
    try {
      final doc = await _childrenCollection.doc(childId).get();
      if (doc.exists) {
        return Child.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting child: $e');
      return null;
    }
  }

  // Update a child's information
  Future<void> updateChild(String childId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt timestamp to the data
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _childrenCollection.doc(childId).update(data);
    } catch (e) {
      debugPrint('Error updating child: $e');
      throw Exception('Failed to update child');
    }
  }

  // Delete a child
  Future<void> deleteChild(String childId) async {
    try {
      await _childrenCollection.doc(childId).delete();
      
      // Update the parent's numberOfChildren field
      await _firestore.collection('users').doc(_userId).update({
        'numberOfChildren': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error deleting child: $e');
      throw Exception('Failed to delete child');
    }
  }

  // Add a new measurement for a child
  Future<String> addMeasurement(
    String childId, {
    required DateTime date,
    required double weight,
    required double height,
    double? headCircumference,
    String? notes,
  }) async {
    try {
      // Get measurements subcollection for this child
      final measurementsCollection = 
          _childrenCollection.doc(childId).collection('measurements');
      
      // Add new measurement
      final docRef = await measurementsCollection.add({
        'date': Timestamp.fromDate(date),
        'weight': weight,
        'height': height,
        'headCircumference': headCircumference,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update current measurements in the child document
      await _childrenCollection.doc(childId).update({
        'currentWeight': weight,
        'currentHeight': height,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding measurement: $e');
      throw Exception('Failed to add measurement');
    }
  }

  // Get all measurements for a child
  Stream<List<Measurement>> getMeasurements(String childId) {
    final measurementsCollection = 
        _childrenCollection.doc(childId).collection('measurements');

    return measurementsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Measurement.fromFirestore(doc)).toList());
  }
  
  // Add a weight measurement for a specific day
  Future<void> addDailyWeight(
    String childId, {
    required int dayNumber,
    required DateTime date,
    required double weight,
  }) async {
    try {
      // Get reference to daily weights collection for this child
      final dailyWeightsCollection = 
          _childrenCollection.doc(childId).collection('dailyWeights');
      
      // Check if an entry for this day already exists
      final existingEntry = await dailyWeightsCollection
          .where('dayNumber', isEqualTo: dayNumber)
          .limit(1)
          .get();
      
      if (existingEntry.docs.isNotEmpty) {
        // Update existing entry
        await dailyWeightsCollection.doc(existingEntry.docs.first.id).update({
          'weight': weight,
          'date': Timestamp.fromDate(date),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new entry
        await dailyWeightsCollection.add({
          'dayNumber': dayNumber,
          'weight': weight,
          'date': Timestamp.fromDate(date),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update current weight in the child document
      await _childrenCollection.doc(childId).update({
        'currentWeight': weight,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding daily weight: $e');
      throw Exception('Failed to add daily weight');
    }
  }

  // Get all daily weights for a child
  Stream<QuerySnapshot> getDailyWeights(String childId) {
    return _childrenCollection
        .doc(childId)
        .collection('dailyWeights')
        .orderBy('dayNumber')
        .snapshots();
  }

  // Get the last updated day number
  Future<int> getLastUpdatedDay(String childId) async {
    try {
      final snapshot = await _childrenCollection
          .doc(childId)
          .collection('dailyWeights')
          .orderBy('dayNumber', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['dayNumber'] as int;
      }
      return 0; // No data yet
    } catch (e) {
      debugPrint('Error getting last updated day: $e');
      return 0;
    }
  }

Future<void> initializeVaccinations(String childId) async {
    try {
      // Create a VaccinationService instance
      final vaccinationService = VaccinationService(_userId);
      
      // Get the child to access their birth date
      final child = await getChild(childId);
      if (child == null) {
        throw Exception('Child not found');
      }
      
      // Initialize vaccinations based on birth date
      await vaccinationService.initializeVaccinations(childId, child.dateOfBirth);
    } catch (e) {
      debugPrint('Error initializing vaccinations: $e');
      throw Exception('Failed to initialize vaccinations');
    }
  }

  // Update all vaccination due dates when child's birth date is updated
  Future<void> updateVaccinationScheduleAfterBirthDateChange(
    String childId, 
    DateTime newBirthDate
  ) async {
    try {
      // Create a VaccinationService instance
      final vaccinationService = VaccinationService(_userId);
      
      // Update vaccination schedule based on new birth date
      await vaccinationService.updateVaccinationSchedule(childId, newBirthDate);
    } catch (e) {
      debugPrint('Error updating vaccination schedule: $e');
      throw Exception('Failed to update vaccination schedule');
    }
  }

  // Add a vaccination record to child's profile
  Future<void> recordVaccination(
    String childId,
    String vaccineName,
    DateTime dateGiven,
  ) async {
    try {
      // Reference to the vaccinations collection
      final vaccinationsCollection = 
          _childrenCollection.doc(childId).collection('vaccinationRecords');
          
      // Add vaccination record
      await vaccinationsCollection.add({
        'name': vaccineName,
        'dateGiven': Timestamp.fromDate(dateGiven),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording vaccination: $e');
      throw Exception('Failed to record vaccination');
    }
  }

  // Get all vaccination records for a child
  Stream<QuerySnapshot> getVaccinationRecords(String childId) {
    return _childrenCollection
        .doc(childId)
        .collection('vaccinationRecords')
        .orderBy('dateGiven', descending: true)
        .snapshots();
  }
}
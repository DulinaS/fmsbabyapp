/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'vaccination_model.dart';
import 'child_model.dart';

class VaccinationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  // Constructor requires user ID to associate vaccinations with user
  VaccinationService(this._userId);

  // Collection reference for this user's children
  CollectionReference get _childrenCollection =>
      _firestore.collection('users').doc(_userId).collection('children');

  // Reference to vaccinations collection of a specific child
  CollectionReference _vaccinationsCollection(String childId) =>
      _childrenCollection.doc(childId).collection('vaccinations');

  // Get standard vaccination schedule (for initial setup)
  List<Map<String, dynamic>> getStandardVaccinationSchedule() {
    return [
      {
        "name": "BCG",
        "weekDue": 0,
        "description":
            "Protects against tuberculosis (TB), a serious infection that affects the lungs and other parts of the body.",
      },
      {
        "name": "Hepatitis B (1st dose)",
        "weekDue": 0,
        "description":
            "Prevents hepatitis B, a liver infection caused by the hepatitis B virus.",
      },
      {
        "name": "Hepatitis B (2nd dose)",
        "weekDue": 4,
        "description":
            "Second dose of vaccine that prevents hepatitis B infection.",
      },
      {
        "name": "DTP, Hib, Polio (1st dose)",
        "weekDue": 6,
        "description":
            "Combined vaccine that protects against diphtheria, tetanus, pertussis (whooping cough), Haemophilus influenzae type b, and polio.",
      },
      {
        "name": "Rotavirus (1st dose)",
        "weekDue": 6,
        "description":
            "Protects against rotavirus, which causes severe diarrhea and vomiting in babies and young children.",
      },
      {
        "name": "Pneumococcal (1st dose)",
        "weekDue": 6,
        "description":
            "Helps prevent pneumonia, meningitis, and bloodstream infections caused by pneumococcal bacteria.",
      },
      {
        "name": "DTP, Hib, Polio (2nd dose)",
        "weekDue": 10,
        "description":
            "Second dose of combined vaccine protecting against multiple diseases.",
      },
      {
        "name": "Rotavirus (2nd dose)",
        "weekDue": 10,
        "description": "Second dose of vaccine protecting against rotavirus.",
      },
      {
        "name": "Pneumococcal (2nd dose)",
        "weekDue": 10,
        "description": "Second dose of pneumococcal vaccine.",
      },
      {
        "name": "DTP, Hib, Polio (3rd dose)",
        "weekDue": 14,
        "description":
            "Third dose of combined vaccine protecting against multiple diseases.",
      },
      {
        "name": "Rotavirus (3rd dose)",
        "weekDue": 14,
        "description": "Third and final dose of rotavirus vaccine.",
      },
      {
        "name": "Hepatitis B (3rd dose)",
        "weekDue": 24,
        "description": "Third and final dose of hepatitis B vaccine.",
      },
      {
        "name": "MMR",
        "weekDue": 36,
        "description":
            "Protects against measles, mumps, and rubella, which are potentially serious diseases.",
      },
      {
        "name": "Varicella",
        "weekDue": 52,
        "description":
            "Protects against chickenpox, a highly contagious disease that causes an itchy, blister-like rash.",
      },
    ];
  }

  // Initialize vaccinations for a new child
  Future<void> initializeVaccinations(
    String childId,
    DateTime birthDate,
  ) async {
    try {
      final batch = _firestore.batch();
      final standardSchedule = getStandardVaccinationSchedule();

      for (var vaccine in standardSchedule) {
        // Calculate due date based on birth date and week due
        final dueDate = birthDate.add(Duration(days: vaccine["weekDue"] * 7));

        // Determine status based on current date
        final now = DateTime.now();
        String status = 'upcoming';
        if (dueDate.isBefore(now)) {
          status = 'due';
        }

        // Create new document reference
        final vaccineRef = _vaccinationsCollection(childId).doc();

        batch.set(vaccineRef, {
          'name': vaccine["name"],
          'weekDue': vaccine["weekDue"],
          'description': vaccine["description"],
          'completed': false,
          'dateCompleted': null,
          'dueDate': Timestamp.fromDate(dueDate),
          'status': status,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch write
      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing vaccinations: $e');
      throw Exception('Failed to initialize vaccinations');
    }
  }

  // Add this to VaccinationService class
  Future<void> checkAndInitializeVaccinations(
    String childId,
    DateTime birthDate,
  ) async {
    try {
      // Check if vaccinations already exist for this child
      final snapshot = await _vaccinationsCollection(childId).limit(1).get();

      // If no vaccinations exist, initialize them
      if (snapshot.docs.isEmpty) {
        await initializeVaccinations(childId, birthDate);
      }
    } catch (e) {
      debugPrint('Error checking vaccinations: $e');
      throw Exception('Failed to check vaccinations');
    }
  }

  // Get all vaccinations for a child
  Stream<List<Vaccination>> getVaccinations(String childId) {
    return _vaccinationsCollection(childId)
        .orderBy('weekDue')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Vaccination.fromFirestore(doc))
                  .toList(),
        );
  }

  // Mark a vaccination as completed
  Future<void> markVaccinationCompleted(
    String childId,
    String vaccinationId, {
    DateTime? completionDate,
  }) async {
    try {
      await _vaccinationsCollection(childId).doc(vaccinationId).update({
        'completed': true,
        'dateCompleted':
            completionDate != null
                ? Timestamp.fromDate(completionDate)
                : Timestamp.fromDate(DateTime.now()),
        'status': 'completed',
      });
    } catch (e) {
      debugPrint('Error marking vaccination completed: $e');
      throw Exception('Failed to mark vaccination as completed');
    }
  }

  // Mark a vaccination as not completed
  Future<void> markVaccinationNotCompleted(
    String childId,
    String vaccinationId,
  ) async {
    try {
      // Get the vaccination to calculate its status
      final vacDoc =
          await _vaccinationsCollection(childId).doc(vaccinationId).get();
      final vacData = vacDoc.data() as Map<String, dynamic>;
      final dueDate = (vacData['dueDate'] as Timestamp).toDate();

      // Determine status based on current date
      final now = DateTime.now();
      String status = 'upcoming';
      if (dueDate.isBefore(now)) {
        status = 'due';
      }

      await _vaccinationsCollection(childId).doc(vaccinationId).update({
        'completed': false,
        'dateCompleted': null,
        'status': status,
      });
    } catch (e) {
      debugPrint('Error marking vaccination as not completed: $e');
      throw Exception('Failed to mark vaccination as not completed');
    }
  }

  // Update vaccination status based on current date
  Future<void> updateVaccinationStatuses(String childId) async {
    try {
      // Get all vaccinations that are not completed
      final snapshot =
          await _vaccinationsCollection(
            childId,
          ).where('completed', isEqualTo: false).get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp).toDate();

        // Update status based on due date and current date
        String status = 'upcoming';
        if (dueDate.isBefore(now)) {
          status = 'due';
        }

        if (status != data['status']) {
          batch.update(doc.reference, {'status': status});
        }
      }

      // Commit the batch write if there are updates
      if (batch != null) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating vaccination statuses: $e');
      throw Exception('Failed to update vaccination statuses');
    }
  }

  // Calculate weeks between two dates
  int calculateWeeksFromBirth(DateTime birthDate, DateTime currentDate) {
    final difference = currentDate.difference(birthDate);
    return (difference.inDays / 7).floor();
  }

  // Update vaccination schedule when a child's birth date is changed
  Future<void> updateVaccinationSchedule(
    String childId,
    DateTime newBirthDate,
  ) async {
    try {
      final vaccinations = await _vaccinationsCollection(childId).get();
      final batch = _firestore.batch();

      for (var doc in vaccinations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final weekDue = data['weekDue'] as int;

        // Calculate new due date based on new birth date
        final newDueDate = newBirthDate.add(Duration(days: weekDue * 7));

        // Determine status based on current date and completion status
        final now = DateTime.now();
        String status = data['completed'] ? 'completed' : 'upcoming';
        if (!data['completed'] && newDueDate.isBefore(now)) {
          status = 'due';
        }

        batch.update(doc.reference, {
          'dueDate': Timestamp.fromDate(newDueDate),
          'status': status,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating vaccination schedule: $e');
      throw Exception('Failed to update vaccination schedule');
    }
  }
}
 */

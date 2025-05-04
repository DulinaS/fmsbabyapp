import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccination {
  final String id;
  final String name;
  final int weekDue;
  final String description;
  final bool completed;
  final DateTime? dateCompleted;
  final DateTime? dueDate; // Calculated based on child's birth date
  final String status; // 'due', 'upcoming', or 'completed'

  Vaccination({
    required this.id,
    required this.name,
    required this.weekDue,
    required this.description,
    required this.completed,
    this.dateCompleted,
    this.dueDate,
    this.status = 'upcoming',
  });

  // Create Vaccination object from Firestore document
  factory Vaccination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Vaccination(
      id: doc.id,
      name: data['name'] ?? '',
      weekDue: data['weekDue'] ?? 0,
      description: data['description'] ?? '',
      completed: data['completed'] ?? false,
      dateCompleted: data['dateCompleted'] != null 
          ? (data['dateCompleted'] as Timestamp).toDate() 
          : null,
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'upcoming',
    );
  }

  // Convert Vaccination object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weekDue': weekDue,
      'description': description,
      'completed': completed,
      'dateCompleted': dateCompleted != null ? Timestamp.fromDate(dateCompleted!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
    };
  }

  // Create a copy of the vaccination object with updated fields
  Vaccination copyWith({
    String? id,
    String? name,
    int? weekDue,
    String? description,
    bool? completed,
    DateTime? dateCompleted,
    DateTime? dueDate,
    String? status,
  }) {
    return Vaccination(
      id: id ?? this.id,
      name: name ?? this.name,
      weekDue: weekDue ?? this.weekDue,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}
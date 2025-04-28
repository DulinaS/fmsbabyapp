import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create new user document in Firestore after registration
  Future<void> createUserDocument(User user, String name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': name,
      'numberOfChildren': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<DocumentSnapshot> getUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return await _firestore.collection('users').doc(userId).get();
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }

    await _firestore.collection('users').doc(userId).update(updateData);
  }

  // Add a new child
  Future<String> addChild({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    double? weight,
    double? height,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Add child document
    final childRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc();

    await childRef.set({
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'currentWeight': weight,
      'currentHeight': height,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update user's child count
    await _firestore.collection('users').doc(userId).update({
      'numberOfChildren': FieldValue.increment(1),
    });

    return childRef.id;
  }

  // Get all children for current user
  Stream<QuerySnapshot> getChildrenStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .orderBy('name')
        .snapshots();
  }

  // Get a specific child
  Future<DocumentSnapshot> getChild(String childId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .get();
  }

  // Update child information
  Future<void> updateChild({
    required String childId,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    double? weight,
    double? height,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (dateOfBirth != null) updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    if (gender != null) updateData['gender'] = gender;
    if (weight != null) updateData['currentWeight'] = weight;
    if (height != null) updateData['currentHeight'] = height;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .update(updateData);
  }

  // Add growth measurement to a child
  Future<void> addMeasurement({
    required String childId,
    required DateTime date,
    required double weight,
    required double height,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Add measurement
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .collection('measurements')
        .add({
          'date': Timestamp.fromDate(date),
          'weight': weight,
          'height': height,
          'notes': notes ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

    // Update current measurements
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .update({
          'currentWeight': weight,
          'currentHeight': height,
        });
  }

  // Get measurements for a child
  Stream<QuerySnapshot> getMeasurementsStream(String childId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Delete a child
  Future<void> deleteChild(String childId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete the child document
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .delete();

    // Update user's child count
    await _firestore.collection('users').doc(userId).update({
      'numberOfChildren': FieldValue.increment(-1),
    });
  }
}
/* 
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/login_page.dart';
import 'growth_milestone_page.dart';
import 'package:fmsbabyapp/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Growth Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1873EA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      home: const LoginPage(),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/login_page.dart';
import 'growth_milestone_page.dart';
import 'package:fmsbabyapp/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'growth_standard_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Add this line to check and initialize growth standards
  await checkAndInitializeGrowthStandards();

  runApp(const MyApp());
}

Future<void> checkAndInitializeGrowthStandards() async {
  try {
    // Check if standards already exist in Firestore
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docSnapshot =
        await firestore.collection('growthStandards').doc('boys_weight').get();

    if (!docSnapshot.exists) {
      print('Initializing growth standards...');
      final growthStandardService = GrowthStandardService();
      await growthStandardService.initializeWeightRanges();
      print('Growth standards initialized successfully');
    } else {
      print('Growth standards already exist');
    }
  } catch (e) {
    print('Error checking/initializing growth standards: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Growth Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1873EA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      home: const LoginPage(),
    );
  }
}

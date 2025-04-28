
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
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Dodaj ten import
import 'firebase_options.dart';
import 'screens/admin_panel_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CICHE LOGOWANIE DLA PANELU ADMINA ---
  try {
    // Sprawdzamy, czy już nie jesteśmy zalogowani
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      print("Zalogowano anonimowo jako Panel Admina.");
    }
  } catch (e) {
    print("Błąd cichego logowania: $e");
  }
  // ------------------------------------------

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panel Admina - Repozytorium',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const AdminPanelScreen(),
    );
  }
}
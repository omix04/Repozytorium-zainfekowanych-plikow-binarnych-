import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Debug: print Firebase app options so we can verify the project used by web
  try {
    final app = Firebase.app();
    final opts = app.options;
    print(
      'FIREBASE APP: name=${app.name} projectId=${opts.projectId} appId=${opts.appId}',
    );
  } catch (e) {
    print('FIREBASE APP: cannot read app options: $e');
  }

  // Ensure we have an authenticated user so Firestore rules that require auth
  // still allow read access for anonymous users. If no user exists, sign in
  // anonymously; signed-in users (Google/email) will be preserved.
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      final cred = await auth.signInAnonymously();
      print('FIREBASE AUTH: signed in anonymously uid=${cred.user?.uid}');
    } else {
      print('FIREBASE AUTH: already signed in uid=${auth.currentUser?.uid}');
    }
  } catch (e) {
    print('FIREBASE AUTH: anonymous sign-in failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Repozytorium binariów',
      theme: ThemeData(useMaterial3: true),
      home: const ListScreen(),
    );
  }
}

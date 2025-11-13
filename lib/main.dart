// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // debug: confirm init in console
  // ignore: avoid_print
  print('Firebase initialized: ${Firebase.apps.map((a) => a.name).toList()}');

  runApp(const TherapistApp());
}

class TherapistApp extends StatelessWidget {
  const TherapistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapist',
      theme: ThemeData(useMaterial3: true),
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

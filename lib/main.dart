// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Required for security

// --- Define the New Gradient and Color Palette (for the UI) ---
const Color primaryBlueGradientStart = Color(0xFF6DD5ED); // Lighter blue
const Color primaryBlueGradientEnd = Color(0xFF2193B0);   // Darker blue
const Color secondaryGreenGradientEnd = Color(0xFF6CCECB);   // Darker green/teal for secondary accents
const Color softBackgroundBlue = Color(0xFFE3F2FD); // Very light blue for overall background
const Color cardSurfaceColor = Color(0xFFFFFFFF);    // White for elevated cards/inputs
const Color darkTextColor = Color(0xFF263238);       // Dark gray for primary text
const Color lightTextColor = Color(0xFFB0BEC5);      // Light gray for hints/secondary text

// Define the main gradient to be used in AppBars and buttons.
final LinearGradient mainAppGradient = LinearGradient(
  colors: [primaryBlueGradientStart, primaryBlueGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase Core
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. Initialize Firebase App Check (Crucial for secure connections)
  // NOTE: 'YOUR_RECAPTCHA_SITE_KEY_HERE' should be replaced if building for web.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use .debug for emulator/debug testing
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY_HERE'), 
  );
  
  // debug: confirm init in console
  // ignore: avoid_print
  print('Firebase initialized: ${Firebase.apps.map((a) => a.name).toList()}');
  
  // FIX: Run the application with the defined class
  runApp(const TherapistApp());
}

// ----------------------------------------------------
// FIX: CLASS DEFINITION ADDED HERE
// ----------------------------------------------------
class TherapistApp extends StatelessWidget {
  const TherapistApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapist',
      theme: ThemeData(
        useMaterial3: true,
        // --- CUSTOM COLOR SCHEME ---
        colorScheme: ColorScheme.light(
          primary: primaryBlueGradientEnd, // Darker blue for primary actions
          onPrimary: cardSurfaceColor,     // White text on primary buttons
          surface: cardSurfaceColor,  // Overall Scaffold background
          onSurface: darkTextColor,     // Main text color
          error: Colors.red.shade700,      
          surfaceContainer: cardSurfaceColor, 
          surfaceContainerLow: cardSurfaceColor, 
          outline: Colors.grey.shade300,
          outlineVariant: Colors.grey.shade200,
        ),
        // Configure ElevatedButton Theme for the gradient style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlueGradientEnd, 
            foregroundColor: cardSurfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          ),
        ),
        // Set AppBar theme (used when not overridden by a Stack/Gradient)
        appBarTheme: const AppBarTheme(
          elevation: 0, 
          titleTextStyle: TextStyle(
            color: cardSurfaceColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: cardSurfaceColor),
          actionsIconTheme: IconThemeData(color: cardSurfaceColor),
        ),
        // Input decoration theme for the floating card style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurfaceColor,
          hintStyle: TextStyle(color: lightTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), 
            borderSide: BorderSide.none, 
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryBlueGradientStart, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
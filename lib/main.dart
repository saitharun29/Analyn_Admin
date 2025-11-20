// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'screens/splash_screen.dart';

// --- Define the New Gradient and Color Palette ---
// These colors are extracted or approximated from the provided image.
const Color primaryBlueGradientStart = Color(0xFF6DD5ED); // Lighter blue
const Color primaryBlueGradientEnd = Color(0xFF2193B0);   // Darker blue
const Color secondaryGreenGradientStart = Color(0xFF83E8DD); // Lighter green/teal
const Color secondaryGreenGradientEnd = Color(0xFF6CCECB);   // Darker green/teal

const Color softBackgroundBlue = Color(0xFFE3F2FD); // Very light blue for overall background
const Color cardSurfaceColor = Color(0xFFFFFFFF);    // White for elevated cards/inputs
const Color darkTextColor = Color(0xFF263238);       // Dark gray for primary text
const Color lightTextColor = Color(0xFFB0BEC5);      // Light gray for hints/secondary text

// Define the main gradient to be used in AppBars, etc.
final LinearGradient mainAppGradient = LinearGradient(
  colors: [primaryBlueGradientStart, primaryBlueGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
      theme: ThemeData(
        useMaterial3: true,
        // --- CUSTOM COLOR SCHEME ---
        colorScheme: ColorScheme.light(
          primary: primaryBlueGradientEnd, // Use the darker blue as primary for consistency
          onPrimary: cardSurfaceColor,     // White text on primary buttons
          surface: cardSurfaceColor,       // White for cards, text fields (inner part)
          background: softBackgroundBlue,  // Overall Scaffold background (light blue)
          onBackground: darkTextColor,     // Main text color
          error: Colors.red.shade700,      // Error text/indicators
          // Other surface containers
          surfaceContainer: cardSurfaceColor, 
          surfaceContainerLow: cardSurfaceColor, 
          // Outline colors for text fields
          outline: Colors.grey.shade300,
          outlineVariant: Colors.grey.shade200,
        ),
        // Configure ElevatedButton to use the primary color, but we'll apply gradient directly later
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlueGradientEnd, // Default if not overridden by gradient
            foregroundColor: cardSurfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded
          ),
        ),
        // Set AppBar theme to use a gradient background (requires custom implementation)
        appBarTheme: AppBarTheme(
          elevation: 0, // No default elevation, we'll add shadow manually if needed
          titleTextStyle: TextStyle(
            color: cardSurfaceColor, // White text on gradient app bar
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: cardSurfaceColor), // White back button
          actionsIconTheme: IconThemeData(color: cardSurfaceColor), // White action icons
          toolbarTextStyle: TextStyle(color: cardSurfaceColor),
          // For the actual gradient, we'll need to wrap AppBar in a FlexibleSpaceBar/Container
          // or create a custom PreferredSizeWidget for full control.
          // For simplicity, we'll use a `FlexibleSpaceBar` in screens where needed.
        ),
        // Input decoration theme for text fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurfaceColor,
          hintStyle: TextStyle(color: lightTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), // More rounded
            borderSide: BorderSide.none, // No border by default, use shadow for depth
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryBlueGradientStart, width: 2), // Focus border with a gradient color
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
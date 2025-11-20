// lib/widgets/app_button.dart
import 'package:flutter/material.dart';
import '../main.dart'; // Import main.dart to use the gradient

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient? gradient; // Optional gradient for specific buttons

  const AppButton({
    super.key, 
    required this.label, 
    required this.onPressed,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Use the primary app gradient by default if no specific gradient is provided
    final buttonGradient = gradient ?? LinearGradient(
      colors: [primaryBlueGradientStart, primaryBlueGradientEnd],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(16), // Matching rounded corners
        boxShadow: [
          BoxShadow(
            color: primaryBlueGradientEnd.withOpacity(0.3), // Shadow color from gradient
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Make button transparent to show gradient
          shadowColor: Colors.transparent,     // Remove button's default shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          foregroundColor: cardSurfaceColor, // Text color is white (from main.dart)
        ),
        child: Text(label),
      ),
    );
  }
}
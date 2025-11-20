// lib/screens/jobs_screen.dart
import 'package:flutter/material.dart';
import '../main.dart'; // Ensure this import is correct for theme access (colors, etc.)

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  // Helper widget to display the empty state message in a floating card format
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      // Margin to position the card below the AppBar area
      margin: const EdgeInsets.only(top: 40, left: 24, right: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardSurfaceColor, // White background for the card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Subtle shadow for the floating effect
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 3,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.work_off_outlined,
            size: 60,
            color: theme.outline, // Subtle color for the icon
          ),
          const SizedBox(height: 16),
          // Main Message (already bold)
          Text(
            'No incoming job requests (pending).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.onBackground, 
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
            ),
          ),
          const SizedBox(height: 8),
          // FIX: Made the "Total bookings" text thicker (FontWeight.w600)
          Text(
            'Total bookings for therapist: 0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.outline, 
              fontSize: 14,
              fontWeight: FontWeight.w600, // Applied thicker style
            ), 
          ),
          const SizedBox(height: 16),
          // Tip text
          Text(
            'Tip: create a booking with status="pending" in Firestore to test.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.onBackground.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color to the light blue defined in main.dart
      backgroundColor: softBackgroundBlue,
      body: Center(
        child: _buildEmptyState(context),
      ),
    );
  }
}
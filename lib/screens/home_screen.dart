// lib/screens/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'jobs_screen.dart';      
import 'earnings_screen.dart';
import 'profile_screen.dart';
import '../app_router.dart';
import '../main.dart'; // Import main.dart for gradient

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = <Widget>[
    JobsScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  
  // Helper to get the title based on the selected index
  String get _currentTitle {
    switch (_selectedIndex) {
      case 0: return 'Jobs';
      case 1: return 'Earnings';
      case 2: return 'Profile';
      default: return 'Therapist Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    // Define a dark gray color for unselected items (visible black/dark gray)
    const Color darkUnselectedColor = Color(0xFF5A5A5A); // A prominent dark gray

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: mainAppGradient,
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text(_currentTitle, style: TextStyle(color: theme.surface)),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (_) => false);
            },
            icon: Icon(Icons.logout, color: theme.surface),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      
      // Bottom Navigation Bar Styling
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.surface, // White background
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3), 
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent, // Use transparent so Container color shows
          elevation: 0, 
          selectedItemColor: theme.primary, // Primary color for selected icon (Jobs is vibrant)
          
          // FIX: Changed unselectedItemColor to a prominent dark gray
          unselectedItemColor: darkUnselectedColor, 
          
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
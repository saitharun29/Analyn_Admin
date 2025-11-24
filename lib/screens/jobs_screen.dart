// lib/screens/jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; 
import '../widgets/app_button.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  // NOTE: Assuming _uid correctly holds the ID 'cHCHAexiICJIGO0FzPeHWSlxt2'
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _autoAcceptMode = false; // State for auto-accept toggle

  // Stream to fetch jobs that are either pending or accepted
  Stream<QuerySnapshot<Map<String, dynamic>>> get _activeJobsStream =>
      FirebaseFirestore.instance
          .collection('bookings')
          .where('therapistId', isEqualTo: _uid)
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('timeSlot', descending: false)
          .snapshots();

  // --- JOB ACTIONS ---

  Future<void> _updateJobStatus(String jobId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(jobId)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job status updated to $status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job: $e')),
        );
      }
    }
  }
  
  void _startNavigation(double latitude, double longitude) async {
    final url = Uri.parse('google.navigation:q=$latitude,$longitude');
    
    // NOTE: Removed 'const' for dynamic string interpolation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation feature placeholder: Go to $latitude, $longitude')),
    );
  }

  void _checkIn(String clientId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checking in for client $clientId... (Placeholder)')),
    );
  }


  // --- UI BUILDERS ---
  
  Widget _buildJobCard(BuildContext context, DocumentSnapshot doc, ColorScheme theme) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String;
    final serviceType = data['serviceType'] ?? 'Unknown Service';
    final clientName = data['clientName'] ?? 'Client';
    
    // --- FIX: TIMESTAMP CONVERSION ---
    final rawTimeSlot = data['timeSlot'];
    String timeString;

    if (rawTimeSlot is Timestamp) {
        final dateTime = rawTimeSlot.toDate();
        // Format the time as a displayable string
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        timeString = '${dateTime.day} ${monthNames[dateTime.month - 1]}, ${dateTime.hour % 12}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    } else {
        timeString = 'N/A';
    }
    // ----------------------------------

    final location = data['location'] ?? {'lat': 0.0, 'lng': 0.0};
    final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;

    final isPending = status == 'pending';
    final statusColor = isPending ? Colors.orange.shade600 : theme.primary;
    final statusText = isPending ? 'PENDING' : 'ACCEPTED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status and Service
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                serviceType,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Details
          _buildDetailRow(Icons.person_outline, clientName, theme),
          _buildDetailRow(Icons.access_time, timeString, theme), // Use the formatted string
          _buildDetailRow(Icons.location_on_outlined, 'View Location', theme),
          
          const SizedBox(height: 20),

          // Action Buttons
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateJobStatus(doc.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryGreenGradientEnd,
                      foregroundColor: cardSurfaceColor,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateJobStatus(doc.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            )
          else 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // GPS Navigation Button
                Expanded(
                  child: AppButton( 
                    label: 'Navigate',
                    onPressed: () => _startNavigation(lat, lng),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.indigo.shade600],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Bluetooth Check-in Button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Check In'),
                    onPressed: () => _checkIn(data['clientId']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primary,
                      side: BorderSide(color: theme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: theme.onSurface.withOpacity(0.8))),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 24, right: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
            color: theme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No incoming job requests (pending).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.onSurface, 
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total bookings for therapist: 0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.outline, 
              fontSize: 14,
              fontWeight: FontWeight.w600, 
            ), 
          ),
          const SizedBox(height: 16),
          const Text(
            'Tip: create a booking with status="pending" in Firestore to test.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }


  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: softBackgroundBlue,
      // The Jobs screen now uses a StreamBuilder to show either jobs or the empty state
      body: Column(
        children: [
          // Auto-Accept Toggle Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Auto-Accept Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch.adaptive(
                  value: _autoAcceptMode,
                  onChanged: (bool newValue) {
                    setState(() {
                      _autoAcceptMode = newValue;
                    });
                    // In a real app, update Firestore or local settings here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auto-Accept is now ${_autoAcceptMode ? 'ON' : 'OFF'}')),
                    );
                  },
                  activeColor: secondaryGreenGradientEnd,
                ),
              ],
            ),
          ),

          // Job List StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _activeJobsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                // Display the list of active jobs
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildJobCard(context, docs[index], theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
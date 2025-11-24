import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import main.dart for colors and theme definitions

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  
  // State variables for all timeframes
  double _dailyEarnings = 0.0;
  double _weeklyEarnings = 0.0;
  double _monthlyEarnings = 0.0;
  double _totalEarnings = 0.0;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _earningsStream =>
      FirebaseFirestore.instance
          .collection('transactions')
          .where('therapistId', isEqualTo: _uid)
          .orderBy('dateCompleted', descending: true)
          .snapshots();

  // --- UPDATED CALCULATION LOGIC (FIXED) ---
  Map<String, double> _computeTotalsFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double daily = 0.0;
    double weekly = 0.0;
    double monthly = 0.0;
    double total = 0.0;
    final now = DateTime.now();

    // Normalize dates to midnight for accurate comparison
    final todayStart = DateTime(now.year, now.month, now.day);
    // Find the Monday of the current week (1 for Monday)
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    for (var doc in docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final payoutStatus = data['payoutStatus'] as String? ?? 'pending';
      
      // --- CRITICAL FIX: Skip transaction if payoutStatus is not 'paid' ---
      if (payoutStatus != 'paid') continue;
      // ---------------------------------------------------------------------

      final ts = data['dateCompleted'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is DateTime) {
        date = ts;
      }

      if (date == null) continue;
      
      total += amount;

      if (date.year == now.year && date.month == now.month) {
        monthly += amount;
      }

      if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
        weekly += amount;
      }

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        daily += amount;
      }
    }
    return {
      'total': total,
      'monthly': monthly,
      'weekly': weekly,
      'daily': daily,
    };
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: softBackgroundBlue, // Set background color
      body: SafeArea(
        child: Column(
          children: [
            // --- Summary Cards (Floating Style) ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Row 1: Daily & Weekly
                  Row(
                    children: [
                      _buildSummaryCard('Today', _dailyEarnings, Colors.blue.shade400),
                      const SizedBox(width: 12),
                      _buildSummaryCard('This Week', _weeklyEarnings, Colors.orange.shade400),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Monthly & Total
                  Row(
                    children: [
                      _buildSummaryCard('This Month', _monthlyEarnings, Colors.purple.shade400),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Total', _totalEarnings, secondaryGreenGradientEnd),
                    ],
                  ),
                ],
              ),
            ),
            // -------------------------
            
            // StreamBuilder for transaction list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _earningsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    // Reset totals if empty
                    if (_totalEarnings != 0.0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _dailyEarnings = 0.0;
                            _weeklyEarnings = 0.0;
                            _monthlyEarnings = 0.0;
                            _totalEarnings = 0.0;
                          });
                        }
                      });
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 60,
                              color: theme.outline,
                            ),
                            const SizedBox(height: 16),
                            // FIX: Made text bold
                            Text(
                              'No recorded transactions yet.',
                              style: TextStyle(
                                color: theme.onBackground.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.bold, // Applied Font Style
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final totals = _computeTotalsFromDocs(docs);
                  
                  // Update state only when values changed
                  if (_totalEarnings != totals['total']) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _dailyEarnings = totals['daily'] ?? 0.0;
                          _weeklyEarnings = totals['weekly'] ?? 0.0;
                          _monthlyEarnings = totals['monthly'] ?? 0.0;
                          _totalEarnings = totals['total'] ?? 0.0;
                        });
                      }
                    });
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final ts = data['dateCompleted'];
                      DateTime date = DateTime.now();
                      if (ts is Timestamp) date = ts.toDate();
                      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                      final service = (data['serviceType'] as String?) ?? 'Service';
                      final jobId = (data['jobId'] as String?) ?? '—';
                      final payoutStatus = (data['payoutStatus'] as String?) ?? 'unknown';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildTransactionListItem(
                          context, 
                          service, 
                          jobId, 
                          date, 
                          amount, 
                          payoutStatus
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the summary cards (Floating Card Style)
  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper widget for transaction list items
  Widget _buildTransactionListItem(
    BuildContext context, 
    String service, 
    String jobId, 
    DateTime date, 
    double amount, 
    String payoutStatus
  ) {
    final theme = Theme.of(context).colorScheme;
    final isPaid = payoutStatus == 'paid';
    final statusColor = isPaid ? secondaryGreenGradientEnd : Colors.orange.shade400;
    
    return Container(
      decoration: BoxDecoration(
        color: cardSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            isPaid ? Icons.check : Icons.access_time,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(service, style: TextStyle(fontWeight: FontWeight.w600, color: theme.onSurface)),
        subtitle: Text('Job: $jobId • ${date.day}/${date.month}/${date.year}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              isPaid ? 'Paid' : 'Pending',
              style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  // --- UPDATED CALCULATION LOGIC ---
  Map<String, double> _computeTotalsFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    
    double daily = 0.0;
    double weekly = 0.0;
    double monthly = 0.0;
    double total = 0.0;

    final now = DateTime.now();
    
    // Normalize dates to midnight for accurate comparison
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    // Find the Monday of the current week
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    for (var doc in docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      
      final ts = data['dateCompleted'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is DateTime) {
        date = ts;
      }
      
      if (date == null) continue;

      // 1. Total
      total += amount;

      // 2. Monthly (Same Year AND Same Month)
      if (date.year == now.year && date.month == now.month) {
        monthly += amount;
      }

      // 3. Weekly (On or after this week's Monday)
      // We check if the transaction date is after or at the same moment as weekStart
      if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
        weekly += amount;
      }

      // 4. Daily (Same Year, Month, and Day)
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
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings Dashboard')),
      body: SafeArea(
        child: Column(
          children: [
            // --- UPDATED HEADER UI ---
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              child: Column(
                children: [
                  // Row 1: Daily & Weekly
                  Row(
                    children: [
                      _buildSummaryCard('Today', _dailyEarnings, Colors.blue),
                      const SizedBox(width: 12),
                      _buildSummaryCard('This Week', _weeklyEarnings, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Monthly & Total
                  Row(
                    children: [
                      _buildSummaryCard('This Month', _monthlyEarnings, Colors.purple),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Total', _totalEarnings, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            // -------------------------

            const Divider(height: 1),

            // StreamBuilder for transaction list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _earningsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    return const Center(child: Text('No recorded transactions yet.'));
                  }

                  final docs = snapshot.data!.docs;
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

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final ts = data['dateCompleted'];
                      DateTime date = DateTime.now();
                      if (ts is Timestamp) date = ts.toDate();

                      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                      final service = (data['serviceType'] as String?) ?? 'Service';
                      final jobId = (data['jobId'] as String?) ?? '—';
                      final payoutStatus = (data['payoutStatus'] as String?) ?? 'unknown';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: payoutStatus == 'paid' ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            payoutStatus == 'paid' ? Icons.check : Icons.access_time,
                            color: payoutStatus == 'paid' ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text('$service', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('Job: $jobId\n${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                        trailing: Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        isThreeLine: true,
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

  // Helper widget to build the summary cards
  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
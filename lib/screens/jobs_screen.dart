// lib/screens/jobs_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Query only by therapistId (avoid composite-index issues)
  Stream<QuerySnapshot<Map<String, dynamic>>> get _incomingJobsStream =>
      FirebaseFirestore.instance
          .collection('bookings')
          .where('therapistId', isEqualTo: _uid)
          .snapshots();

  Future<void> _updateJobStatus(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> jobDocument, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(jobDocument.id).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job $newStatus')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<bool?> _confirmDialog(BuildContext context, String title, String content) =>
      showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
            ],
          ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _incomingJobsStream,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Firestore error: ${snap.error}'));
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final docs = snap.data?.docs ?? [];

            // debug: status counts
            final statuses = <String, int>{};
            for (var d in docs) {
              final st = (d.data()['status'] as String?) ?? 'unknown';
              statuses[st] = (statuses[st] ?? 0) + 1;
            }

            final pending = docs.where((d) => ((d.data()['status'] as String?) ?? '').toLowerCase() == 'pending').toList();

            if (pending.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No incoming job requests (pending).', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Total bookings for therapist: ${docs.length}'),
                  const SizedBox(height: 8),
                  Text('Status counts: ${statuses.entries.map((e) => '${e.key}:${e.value}').join(', ')}'),
                  const SizedBox(height: 8),
                  const Text('Tip: create a booking with status="pending" in Firestore to test.'),
                ]),
              );
            }

            return ListView.builder(
              itemCount: pending.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final jobDoc = pending[index];
                final job = jobDoc.data();
                final service = (job['serviceType'] as String?) ?? 'Service';
                final client = (job['patientName'] as String?) ?? (job['clientName'] as String?) ?? 'Client';
                final address = job['clientAddress'] as String? ?? (job['location']?['address'] as String? ?? '');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        Chip(label: Text(job['status']?.toString().toUpperCase() ?? 'PENDING')),
                      ]),
                      const SizedBox(height: 8),
                      Text('Client: $client'),
                      if (address.isNotEmpty) ...[const SizedBox(height: 6), Text('Address: $address')],
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: () async {
                            final ok = await _confirmDialog(context, 'Reject booking', 'Reject this booking?');
                            if (ok == true) await _updateJobStatus(context, jobDoc, 'rejected');
                          },
                          child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final ok = await _confirmDialog(context, 'Accept booking', 'Accept this booking?');
                            if (ok == true) await _updateJobStatus(context, jobDoc, 'accepted');
                          },
                          child: const Text('ACCEPT'),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

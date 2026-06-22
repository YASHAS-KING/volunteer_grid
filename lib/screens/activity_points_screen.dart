import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'submit_activity_screen.dart';

class ActivityPointsScreen extends StatefulWidget {
  const ActivityPointsScreen({super.key});

  @override
  State<ActivityPointsScreen> createState() => _ActivityPointsScreenState();
}

class _ActivityPointsScreenState extends State<ActivityPointsScreen> {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AICTE Tracker',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).colorScheme.primary)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('activities').stream(primaryKey: ['id']).eq('user_id', _userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data ?? [];
          int totalPoints = 0;
          for (var a in activities) {
            totalPoints += (a['points_claimed'] as int?) ?? 0;
          }
          final progress = (totalPoints / 100.0).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.deepPurple.shade300]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Points Earned / Pending', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('$totalPoints / 100',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      const Text('Minimum 30 points required per year',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitActivityScreen())),
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('Log New Activity',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 32),
                Text('History & Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (activities.isEmpty)
                  const Center(child: Text('No activities logged yet.', style: TextStyle(color: Colors.grey))),
                ...activities.map((a) => _buildHistoryCard(
                      context,
                      title: a['activity_name'] ?? 'Unknown',
                      category: a['category'] ?? '',
                      points: a['points_claimed']?.toString() ?? '0',
                      status: a['status'] == 'pending_verification' ? 'Pending Verification' : 'Approved',
                      statusColor: a['status'] == 'pending_verification' ? Colors.orange : Colors.green,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context,
      {required String title,
      required String category,
      required String points,
      required String status,
      required Color statusColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Text('+$points',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_points_screen.dart';
import 'settings_screen.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _activities = [];
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadActivities();
  }

  Future<void> _loadProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final data = await _supabase.from('profiles').select().eq('id', uid).maybeSingle();
    if (mounted) setState(() => _profile = data);
  }

  Future<void> _loadActivities() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final data = await _supabase.from('activities').select().eq('user_id', uid);
    if (mounted) setState(() => _activities = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final bytes = await File(result.files.single.path!).readAsBytes();
      final ext = result.files.single.extension ?? 'jpg';
      final path = 'avatars/$uid/profile.$ext';
      await _supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = '${_supabase.storage.from('avatars').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('profiles').update({'avatar_url': url}).eq('id', uid);
      if (mounted) setState(() => _profile = {...?_profile, 'avatar_url': url});
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  int get _totalPoints => _activities.fold(0, (sum, a) => sum + ((a['points_claimed'] as int?) ?? 0));
  int get _eventsJoined => _activities.length;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = _profile?['full_name'] ?? 'Volunteer';
    final email = _supabase.auth.currentUser?.email ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('My Dashboard', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _loadProfile();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async { await _loadProfile(); await _loadActivities(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple))
                          : null,
                    ),
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: _uploadingAvatar
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _statCard(context, 'Activities\nLogged', '$_eventsJoined', Icons.event_available),
                _statCard(context, 'AICTE\nPoints', '$_totalPoints', Icons.stars_outlined),
                _statCard(context, 'Status', _totalPoints >= 30 ? 'Good' : 'Low', Icons.verified_outlined),
              ]),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activities', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityPointsScreen())),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_activities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: const Column(children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No activities yet.', style: TextStyle(color: Colors.grey)),
                    Text('Log your first activity in the AICTE tab.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: _activities.take(3).map((a) {
                      final status = a['status'] == 'pending_verification';
                      return Column(children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(width: 50, height: 50,
                              decoration: BoxDecoration(color: status ? Colors.orange.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                              child: Icon(status ? Icons.hourglass_top : Icons.check_circle, color: status ? Colors.orange : Colors.green)),
                          title: Text(a['activity_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(a['category'] ?? ''),
                          trailing: Text('+${a['points_claimed'] ?? 0} pts', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        ),
                        if (a != _activities.take(3).last) const Divider(),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String count, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(count, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ]),
      ),
    );
  }
}

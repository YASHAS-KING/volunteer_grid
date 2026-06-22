import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_details_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Volunteer Grid',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).colorScheme.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('No new notifications'))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _events.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.event_busy, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No events yet',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Check back soon for volunteer opportunities!',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('Recommended for you',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          );
                        }
                        final e = _events[i - 1];
                        final tags = (e['tags'] as List?)?.cast<String>() ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildEventCard(context, e, tags),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, Map<String, dynamic> e, List<String> tags) {
    final imageUrl = e['image_url'] as String?;
    final fallbackUrl =
        'https://picsum.photos/seed/${Uri.encodeComponent(e['title'] ?? 'event')}/400/200';
    final displayImage = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : fallbackUrl;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailsScreen(event: e))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                displayImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.deepPurple.shade50,
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 40)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['title'] ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(e['org_name'] ?? '',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(e['date'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ]),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: tags
                          .map((tag) => Chip(
                                label: Text(tag,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor:
                                    Colors.deepPurple.withValues(alpha: 0.1),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

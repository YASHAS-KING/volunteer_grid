import 'package:flutter/material.dart';
import 'volunteer_registration_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final title = event['title'] ?? '';
    final orgName = event['org_name'] ?? '';
    final date = event['date'] ?? '';
    final description = event['description'] ?? '';
    final imageUrl = event['image_url'] as String?;
    final tags = (event['tags'] as List?)?.cast<String>() ?? [];
    final lat = event['lat'];
    final lng = event['lng'];
    final fallbackUrl =
        'https://picsum.photos/seed/${Uri.encodeComponent(title)}/400/200';
    final displayImage =
        (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : fallbackUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                displayImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.deepPurple.shade50,
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 48)),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Hosted by $orgName',
                      style: TextStyle(
                          fontSize: 16,
                          color: primary,
                          fontWeight: FontWeight.w600)),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: tags
                          .map((tag) => Chip(
                                label: Text(tag,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor:
                                    primary.withValues(alpha: 0.1),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (date.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(date, style: const TextStyle(fontSize: 16)),
                    ]),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                          '${(lat as double).toStringAsFixed(4)}, ${(lng as double).toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 16)),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  Text('About this event',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'Join us for a fantastic opportunity to give back to the community! All tools and training will be provided on-site.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        VolunteerRegistrationScreen(eventTitle: title))),
            backgroundColor: primary,
            label: const Text('Volunteer Now',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

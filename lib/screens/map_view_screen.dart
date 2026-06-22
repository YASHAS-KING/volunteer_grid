import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'org_dashboard_screen.dart' show tagIcons, tagColors;

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final _mapController = MapController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .not('lat', 'is', null)
          .not('lng', 'is', null);
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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore Nearby',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: primary)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() { _loading = true; _selected = null; });
            _loadEvents();
          }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _events.isNotEmpty
                        ? LatLng(_events.first['lat'], _events.first['lng'])
                        : const LatLng(12.9716, 77.5946),
                    initialZoom: 13,
                    onTap: (tap, point) => setState(() => _selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.volunteer_grid',
                    ),
                    MarkerLayer(
                      markers: _events.map((e) {
                        final isSelected = _selected?['id'] == e['id'];
                        final tags = (e['tags'] as List?)?.cast<String>() ?? [];
                        final firstTag = tags.isNotEmpty ? tags.first : null;
                        return Marker(
                          point: LatLng(e['lat'], e['lng']),
                          width: 56,
                          height: 56,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = e),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primary : (tagColors[firstTag] ?? Colors.deepPurple),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                    color: (isSelected ? primary : (tagColors[firstTag] ?? Colors.deepPurple)).withValues(alpha: 0.4),
                                    blurRadius: 8, offset: const Offset(0, 3),
                                  )],
                                ),
                                child: Icon(tagIcons[firstTag] ?? Icons.event, color: Colors.white, size: 20),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: isSelected ? primary : (tagColors[firstTag] ?? Colors.deepPurple), size: 18),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Empty state overlay
                if (_events.isEmpty)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No events with locations yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Organisations can add locations when posting events.',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ]),
                    ),
                  ),

                // Selected event card
                if (_selected != null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(Icons.event, color: primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_selected!['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if ((_selected!['org_name'] ?? '').isNotEmpty)
                                  Text(_selected!['org_name'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ])),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _selected = null),
                              ),
                            ]),
                            if ((_selected!['date'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(_selected!['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ]),
                            ],
                            if ((_selected!['description'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(_selected!['description'], maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // Zoom controls
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(children: [
                    _mapBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                    const SizedBox(height: 4),
                    _mapBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22),
          ),
        ),
      );
}

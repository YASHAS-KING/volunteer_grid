import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _picked;
  String _pickedLabel = '';
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;
  bool _showSuggestions = false;

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=6',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'VolunteerGridApp/1.0'});
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        if (mounted) setState(() { _suggestions = list; _showSuggestions = list.isNotEmpty; });
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0;
    final lng = double.tryParse(place['lon'].toString()) ?? 0;
    final label = place['display_name'] ?? '';
    final point = LatLng(lat, lng);
    setState(() {
      _picked = point;
      _pickedLabel = label;
      _suggestions = [];
      _showSuggestions = false;
      _searchCtrl.text = label.length > 60 ? '${label.substring(0, 60)}…' : label;
    });
    _mapController.move(point, 15);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_picked != null)
            TextButton(
              onPressed: () => Navigator.pop(context, {'latlng': _picked, 'label': _pickedLabel}),
              child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(12.9716, 77.5946),
              initialZoom: 13,
              onTap: (tap, point) {
                setState(() {
                  _picked = point;
                  _pickedLabel = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
                  _showSuggestions = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.volunteer_grid',
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 48,
                    height: 56,
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                      ),
                      Icon(Icons.arrow_drop_down, color: primary, size: 18),
                    ]),
                  ),
                ]),
            ],
          ),

          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search location…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() { _suggestions = []; _showSuggestions = false; }); })
                              : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _search,
                  ),
                ),

                // Suggestions dropdown
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: Column(
                      children: _suggestions.map((place) {
                        final name = place['display_name'] ?? '';
                        return InkWell(
                          onTap: () => _selectSuggestion(place),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(children: [
              _btn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
              const SizedBox(height: 4),
              _btn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
            ]),
          ),

          // Confirm button
          if (_picked != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, {'latlng': _picked, 'label': _pickedLabel}),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Confirm Location', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => Material(
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

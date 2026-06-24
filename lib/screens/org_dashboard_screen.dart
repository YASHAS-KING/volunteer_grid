import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_picker_screen.dart';
import 'settings_screen.dart';
import 'dart:typed_data';
import '../utils/upload_helper.dart';

const _eventTags = [
  'Education',
  'Nature',
  'Community',
  'Outdoor',
  'Indoor',
  'Hackathon',
  'Health',
  'Sports',
  'Arts',
  'Animal Welfare',
  'Disaster Relief',
  'Elderly Care',
  'Children',
  'Environment',
];

// Tag → icon + color for map pins
const Map<String, IconData> tagIcons = {
  'Education': Icons.school,
  'Nature': Icons.eco,
  'Community': Icons.people,
  'Outdoor': Icons.park,
  'Indoor': Icons.home_work,
  'Hackathon': Icons.code,
  'Health': Icons.health_and_safety,
  'Sports': Icons.sports,
  'Arts': Icons.palette,
  'Animal Welfare': Icons.pets,
  'Disaster Relief': Icons.emergency,
  'Elderly Care': Icons.elderly,
  'Children': Icons.child_care,
  'Environment': Icons.recycling,
};

const Map<String, Color> tagColors = {
  'Education': Colors.blue,
  'Nature': Colors.green,
  'Community': Colors.orange,
  'Outdoor': Colors.teal,
  'Indoor': Colors.purple,
  'Hackathon': Colors.indigo,
  'Health': Colors.red,
  'Sports': Colors.cyan,
  'Arts': Colors.pink,
  'Animal Welfare': Colors.brown,
  'Disaster Relief': Colors.deepOrange,
  'Elderly Care': Colors.blueGrey,
  'Children': Colors.amber,
  'Environment': Colors.lightGreen,
};

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() =>
      _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState
    extends State<OrganizationDashboardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _events = [];
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      final events = await _supabase
          .from('events')
          .select()
          .eq('org_id', uid)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _profile = profile;
          _events = List<Map<String, dynamic>>.from(events);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    // Notice we removed the "path == null" check here so it doesn't abort on Web!
    if (result == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final file = result.files.single;

      // Read bytes safely for both Web and Mobile
      final bytes =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) throw Exception('Could not read file data');

      final ext = file.extension ?? 'jpg';
      final path = 'avatar/$uid/profile.$ext';

      await _supabase.storage
          .from('avatar')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url =
          '${_supabase.storage.from('avatar').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', uid);
      if (mounted) {
        setState(() => _profile = {...?_profile, 'avatar_url': url});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // Future<void> _pickAvatar() async {
  //   // NEW CODE (Works with the latest version)
  //   final result = await FilePicker.pickFiles(type: FileType.image);
  //   if (result == null || result.files.single.path == null) return;
  //   setState(() => _uploadingAvatar = true);
  //   try {
  //     final uid = _supabase.auth.currentUser!.id;
  //     final bytes = await File(result.files.single.path!).readAsBytes();
  //     final ext = result.files.single.extension ?? 'jpg';
  //     final path = 'avatars/$uid/profile.$ext';
  //     await _supabase.storage.from('avatar').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
  //     final url = '${_supabase.storage.from('avatar').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
  //     await _supabase.from('profiles').update({'avatar_url': url}).eq('id', uid);
  //     if (mounted) setState(() => _profile = {...?_profile, 'avatar_url': url});
  //   } finally {
  //     if (mounted) setState(() => _uploadingAvatar = false);
  //   }
  // }

  Future<void> _deleteEvent(String id) async {
    await _supabase.from('events').delete().eq('id', id);
    await _load();
  }

  void _showAddEvent() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    LatLng? pickedLocation;
    String pickedLocationLabel = '';
    List<String> selectedTags = [];
    // String? pickedImagePath;
    Uint8List? pickedImageBytes;
    String? pickedImageExt;
    bool posting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post New Event',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Event image
                // Event image
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null) {
                      final file = result.files.single;
                      final bytes =
                          file.bytes ??
                          (file.path != null
                              ? await File(file.path!).readAsBytes()
                              : null);
                      if (bytes != null) {
                        setModal(() {
                          pickedImageBytes = bytes;
                          pickedImageExt = file.extension ?? 'jpg';
                        });
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: pickedImageBytes != null
                        // ✨ Web-safe rendering using Image.memory
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              pickedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tap to add event photo (optional)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                // GestureDetector(
                //   onTap: () async {
                //     // NEW CODE (Works with the latest version)
                //     final result = await FilePicker.pickFiles(
                //       type: FileType.image,
                //     );
                //     //final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                //     if (result != null && result.files.single.path != null) {
                //       setModal(
                //         () => pickedImagePath = result.files.single.path,
                //       );
                //     }
                //   },
                //   child: Container(
                //     width: double.infinity,
                //     height: 130,
                //     decoration: BoxDecoration(
                //       color: Colors.grey[100],
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(color: Colors.grey.shade300),
                //     ),
                //     child: pickedImagePath != null
                //         ? ClipRRect(
                //             borderRadius: BorderRadius.circular(12),
                //             child: Image.file(
                //               File(pickedImagePath!),
                //               fit: BoxFit.cover,
                //               width: double.infinity,
                //             ),
                //           )
                //         : const Column(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               Icon(
                //                 Icons.add_photo_alternate_outlined,
                //                 size: 36,
                //                 color: Colors.grey,
                //               ),
                //               SizedBox(height: 6),
                //               Text(
                //                 'Tap to add event photo (optional)',
                //                 style: TextStyle(
                //                   color: Colors.grey,
                //                   fontSize: 12,
                //                 ),
                //               ),
                //             ],
                //           ),
                //   ),
                // ),
                const SizedBox(height: 12),

                // Tags dropdown
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Event Type / Tags',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedTags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: selectedTags
                              .map(
                                (t) => Chip(
                                  label: Text(
                                    t,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () =>
                                      setModal(() => selectedTags.remove(t)),
                                  backgroundColor:
                                      (tagColors[t] ?? Colors.deepPurple)
                                          .withValues(alpha: 0.15),
                                  side: BorderSide.none,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text(
                          'Select tags…',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: null,
                        items: _eventTags
                            .where((t) => !selectedTags.contains(t))
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(
                                      tagIcons[t] ?? Icons.label,
                                      size: 18,
                                      color: tagColors[t] ?? Colors.deepPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModal(() => selectedTags.add(val));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setModal(() => pickedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          pickedDate == null
                              ? 'Pick Date'
                              : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}',
                          style: TextStyle(
                            fontSize: 15,
                            color: pickedDate == null
                                ? Colors.grey[600]
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Time picker
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setModal(() => pickedTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          pickedTime == null
                              ? 'Pick Time'
                              : pickedTime!.format(ctx),
                          style: TextStyle(
                            fontSize: 15,
                            color: pickedTime == null
                                ? Colors.grey[600]
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Location picker
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    );
                    if (result != null) {
                      setModal(() {
                        pickedLocation = result['latlng'] as LatLng;
                        pickedLocationLabel = result['label'] as String;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: pickedLocation != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: pickedLocation != null
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: pickedLocation != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickedLocation == null
                                ? 'Pick Location on Map'
                                : pickedLocationLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: pickedLocation == null
                                  ? Colors.grey[600]
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (pickedLocation != null)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Post button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: posting
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an event title'),
                                ),
                              );
                              return;
                            }
                            // setModal(() => posting = true);
                            // try {
                            //   final uid = _supabase.auth.currentUser?.id;
                            //   String dateStr = '';
                            //   if (pickedDate != null && pickedTime != null) {
                            //     dateStr =
                            //         '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year} at ${pickedTime!.format(ctx)}';
                            //   } else if (pickedDate != null) {
                            //     dateStr =
                            //         '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}';
                            //   }

                            //   String? imageUrl;
                            //   if (pickedImageBytes != null) {
                            //     final path =
                            //         'events/$uid/${DateTime.now().millisecondsSinceEpoch}.$pickedImageExt';
                            //     await _supabase.storage
                            //         .from('avatar')
                            //         .uploadBinary(
                            //           path,
                            //           pickedImageBytes!,
                            //           fileOptions: const FileOptions(
                            //             upsert: true,
                            //           ),
                            //         );
                            //     imageUrl = _supabase.storage
                            //         .from('avatar')
                            //         .getPublicUrl(path);
                            //   }
                            setModal(() => posting = true);
                            try {
                              final uid = _supabase.auth.currentUser?.id;
                              String dateStr = '';
                              if (pickedDate != null && pickedTime != null) {
                                dateStr =
                                    '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year} at ${pickedTime!.format(ctx)}';
                              } else if (pickedDate != null) {
                                dateStr =
                                    '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}';
                              }

                              // ✨ CLEANED UP IMAGE UPLOAD
                              String? imageUrl;
                              if (pickedImageBytes != null) {
                                final ext = pickedImageExt ?? 'jpg';
                                final path =
                                    'events/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

                                // We construct a fake PlatformFile since the helper expects one
                                final dummyFile = PlatformFile(
                                  name: 'event.$ext',
                                  size: pickedImageBytes!.length,
                                  bytes: pickedImageBytes,
                                );

                                imageUrl = await UploadHelper.uploadFile(
                                  file: dummyFile,
                                  bucketName:
                                      'avatar', // Explicitly using the working bucket
                                  folderPath: path,
                                );
                              }

                              // String? imageUrl;
                              // if (pickedImagePath != null) {
                              //   final bytes = await File(
                              //     pickedImagePath!,
                              //   ).readAsBytes();
                              //   final ext = pickedImagePath!.split('.').last;
                              //   final path =
                              //       'events/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
                              //   await _supabase.storage
                              //       .from('avatars')
                              //       .uploadBinary(
                              //         path,
                              //         bytes,
                              //         fileOptions: const FileOptions(
                              //           upsert: true,
                              //         ),
                              //       );
                              //   imageUrl = _supabase.storage
                              //       .from('avatars')
                              //       .getPublicUrl(path);
                              // }

                              // Supabase schema cache reports events.tags does NOT exist.
                              // Build payload explicitly to ensure we do not send any `tags` field.
                              final payload = <String, dynamic>{
                                'org_id': uid,
                                'title': titleCtrl.text.trim(),
                                'date': dateStr,
                                'description': descCtrl.text.trim(),
                                'org_name': _profile?['full_name'] ?? '',
                                if (imageUrl != null) 'image_url': imageUrl,
                                if (pickedLocation != null)
                                  'lat': pickedLocation!.latitude,
                                if (pickedLocation != null)
                                  'lng': pickedLocation!.longitude,
                                if (pickedLocationLabel.isNotEmpty)
                                  'location_name': pickedLocationLabel,
                              };

                              // ignore: avoid_print
                              print('POST EVENT PAYLOAD => $payload');

                              await _supabase.from('events').insert(payload);
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _load();
                            } catch (e) {
                              setModal(() => posting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to post event: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                // Helpful for debugging PostgrestException details
                                // ignore: avoid_print
                                print('POST EVENT ERROR => $e');
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: posting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Post Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final orgName = _profile?['full_name'] ?? 'Organization';
    final email = _supabase.auth.currentUser?.email ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Organization Dashboard',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple.shade100,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(
                                Icons.business,
                                size: 40,
                                color: Colors.deepPurple,
                              )
                            : null,
                      ),
                      GestureDetector(
                        onTap: _uploadingAvatar ? null : _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _uploadingAvatar
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard(
                    context,
                    'Events\nPosted',
                    '${_events.length}',
                    Icons.event_available,
                  ),
                  _statCard(
                    context,
                    'Volunteers\nReached',
                    '${_events.length * 12}',
                    Icons.people_outline,
                  ),
                  _statCard(
                    context,
                    'Hours\nGenerated',
                    '${_events.length * 20}',
                    Icons.timer_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Posted Events',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_events.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No events posted yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Tap + New Event to get started.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _events.asMap().entries.map((entry) {
                      final e = entry.value;
                      final tags = (e['tags'] as List?)?.cast<String>() ?? [];
                      final firstTag = tags.isNotEmpty ? tags.first : null;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    (tagColors[firstTag] ?? Colors.deepPurple)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                tagIcons[firstTag] ?? Icons.event,
                                color: tagColors[firstTag] ?? Colors.deepPurple,
                              ),
                            ),
                            title: Text(
                              e['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((e['date'] ?? '').isNotEmpty)
                                  Text(
                                    e['date'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                if ((e['location_name'] ?? '').isNotEmpty)
                                  Text(
                                    '📍 ${e['location_name']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteEvent(e['id']),
                            ),
                          ),
                          if (entry.key < _events.length - 1) const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEvent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

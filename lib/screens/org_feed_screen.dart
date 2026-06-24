import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_screen.dart';
import '../utils/upload_helper.dart';
import 'dart:typed_data';

class OrgFeedScreen extends StatefulWidget {
  const OrgFeedScreen({super.key});

  @override
  State<OrgFeedScreen> createState() => _OrgFeedScreenState();
}

class _OrgFeedScreenState extends State<OrgFeedScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;

  String get _myId => _supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', _myId)
          .maybeSingle();
      final posts = await _supabase
          .from('org_posts')
          .select()
          .eq('org_id', _myId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = List<Map<String, dynamic>>.from(posts);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // void _showCreatePost() {
  //   final captionCtrl = TextEditingController();
  //   String? pickedImagePath;
  //   String? pickedImageName;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (ctx, setModal) => Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(ctx).viewInsets.bottom,
  //           left: 20,
  //           right: 20,
  //           top: 24,
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Share Experience',
  //               style: Theme.of(
  //                 ctx,
  //               ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 16),
  //             GestureDetector(
  //               onTap: () async {
  //                 // NEW CODE (Works with the latest version)
  //                 final result = await FilePicker.pickFiles(
  //                   type: FileType.image,
  //                 );
  //                 if (result != null && result.files.single.path != null) {
  //                   setModal(() {
  //                     pickedImagePath = result.files.single.path;
  //                     pickedImageName = result.files.single.name;
  //                   });
  //                 }
  //               },
  //               child: Container(
  //                 width: double.infinity,
  //                 height: 160,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[100],
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(
  //                     color: Colors.grey.shade300,
  //                     style: BorderStyle.solid,
  //                   ),
  //                 ),
  //                 child: pickedImagePath != null
  //                     ? ClipRRect(
  //                         borderRadius: BorderRadius.circular(12),
  //                         child: Image.file(
  //                           File(pickedImagePath!),
  //                           fit: BoxFit.cover,
  //                           width: double.infinity,
  //                         ),
  //                       )
  //                     : const Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(
  //                             Icons.add_photo_alternate_outlined,
  //                             size: 40,
  //                             color: Colors.grey,
  //                           ),
  //                           SizedBox(height: 8),
  //                           Text(
  //                             'Tap to add a photo',
  //                             style: TextStyle(color: Colors.grey),
  //                           ),
  //                         ],
  //                       ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             TextField(
  //               controller: captionCtrl,
  //               maxLines: 3,
  //               decoration: InputDecoration(
  //                 hintText: 'Write a caption about your event experience…',
  //                 filled: true,
  //                 fillColor: Colors.grey[50],
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide: BorderSide(color: Colors.grey.shade300),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Theme.of(context).colorScheme.primary,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   padding: const EdgeInsets.symmetric(vertical: 14),
  //                 ),
  //                 onPressed: () async {
  //                   if (captionCtrl.text.trim().isEmpty &&
  //                       pickedImagePath == null) {
  //                     return;
  //                   }
  //                   Navigator.pop(ctx);
  //                   String? imageUrl;
  //                   if (pickedImagePath != null && pickedImageName != null) {
  //                     final bytes = await File(pickedImagePath!).readAsBytes();
  //                     final path =
  //                         'posts/$_myId/${DateTime.now().millisecondsSinceEpoch}_$pickedImageName';
  //                     await _supabase.storage
  //                         .from('avatars')
  //                         .uploadBinary(
  //                           path,
  //                           bytes,
  //                           fileOptions: const FileOptions(upsert: true),
  //                         );
  //                     imageUrl = _supabase.storage
  //                         .from('avatar')
  //                         .getPublicUrl(path);
  //                   }
  //                   await _supabase.from('org_posts').insert({
  //                     'org_id': _myId,
  //                     'org_name': _profile?['full_name'] ?? 'Organisation',
  //                     'org_avatar': _profile?['avatar_url'],
  //                     'caption': captionCtrl.text.trim(),
  //                     'image_url': imageUrl,
  //                     'created_at': DateTime.now().toIso8601String(),
  //                   });
  //                   _load();
  //                 },
  //                 child: const Text(
  //                   'Share',
  //                   style: TextStyle(color: Colors.white, fontSize: 16),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showCreatePost() {
    final captionCtrl = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Experience',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Web-Safe Image Picker
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.image,
                  );
                  if (result != null) {
                    final file = result.files.single;
                    // Safely get bytes for Web/Mobile
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
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            pickedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a caption…',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: posting
                      ? null
                      : () async {
                          if (captionCtrl.text.trim().isEmpty &&
                              pickedImageBytes == null)
                            {return;}

                          setModal(() => posting = true);
                          String? imageUrl;

                          try {
                            if (pickedImageBytes != null) {
                              final path =
                                  'posts/$_myId/${DateTime.now().millisecondsSinceEpoch}.$pickedImageExt';

                              // ✨ USING THE UPLOAD HELPER (Targets singular 'avatar' bucket)
                              imageUrl = await UploadHelper.uploadFile(
                                file: PlatformFile(
                                  name: 'post.$pickedImageExt',
                                  size: pickedImageBytes!.length,
                                  bytes: pickedImageBytes,
                                ),
                                bucketName: 'avatar',
                                folderPath: path,
                              );
                            }

                            await _supabase.from('org_posts').insert({
                              'org_id': _myId,
                              'org_name':
                                  _profile?['full_name'] ?? 'Organisation',
                              'org_avatar': _profile?['avatar_url'],
                              'caption': captionCtrl.text.trim(),
                              'image_url': imageUrl,
                              'created_at': DateTime.now().toIso8601String(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          } catch (e) {
                            setModal(() => posting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: posting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Share',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(String id) async {
    await _supabase.from('org_posts').delete().eq('id', id);
    _load();
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final orgName = _profile?['full_name'] ?? 'Organisation';
    final avatar = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feed',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePost,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_album_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share your event experiences with volunteers!',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _showCreatePost,
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, i) {
                        final post = _posts[i];
                        final postAvatar = post['org_avatar'] ?? avatar;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row — org name + time + delete
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      backgroundImage: postAvatar != null
                                          ? NetworkImage(postAvatar)
                                          : null,
                                      child: postAvatar == null
                                          ? Text(
                                              orgName.isNotEmpty
                                                  ? orgName[0].toUpperCase()
                                                  : 'O',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post['org_name'] ?? orgName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            _timeAgo(post['created_at']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => showModalBottomSheet(
                                        context: context,
                                        builder: (_) => SafeArea(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            title: const Text(
                                              'Delete Post',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _deletePost(post['id']);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Post image
                              if (post['image_url'] != null)
                                Image.network(
                                  post['image_url'],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                              // Caption
                              if ((post['caption'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    4,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${post['org_name'] ?? orgName}  ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextSpan(
                                          text: post['caption'],
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 0.5),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Conversation list ──────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _convos = [];
  List<Map<String, dynamic>> _filtered = [];
  final _search = TextEditingController();
  bool _searching = false;
  bool _loading = true;

  String get _myId => _supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('conversations')
          .select()
          .or('user1_id.eq.$_myId,user2_id.eq.$_myId')
          .order('updated_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data);

      final otherIds = rows
          .map((c) => c['user1_id'] == _myId ? c['user2_id'] : c['user1_id'])
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, String> nameMap = {};
      Map<String, String?> avatarMap = {};
      if (otherIds.isNotEmpty) {
        final profiles = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', otherIds);
        for (final p in profiles) {
          nameMap[p['id']] = p['full_name'] ?? 'Unknown';
          avatarMap[p['id']] = p['avatar_url'];
        }
      }

      final enriched = rows.map((c) {
        final otherId = c['user1_id'] == _myId ? c['user2_id'] : c['user1_id'];
        return {
          ...c,
          '_other_name': nameMap[otherId] ?? 'Unknown',
          '_other_avatar': avatarMap[otherId],
          '_other_id': otherId,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _convos = enriched;
          _filtered = enriched;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _convos
          : _convos.where((c) {
              final name = (c['_other_name'] ?? '').toLowerCase();
              return name.contains(q.toLowerCase());
            }).toList();
    });
  }

  void _showNewConversation() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Message', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (q) async {
                  if (q.trim().isEmpty) { setModalState(() => results = []); return; }
                  final data = await _supabase
                      .from('profiles')
                      .select()
                      .neq('id', _myId)
                      .ilike('full_name', '%$q%');
                  setModalState(() => results = List<Map<String, dynamic>>.from(data));
                },
              ),
              const SizedBox(height: 8),
              ...results.map((user) => ListTile(
                leading: CircleAvatar(
                  child: Text(user['full_name']?[0]?.toUpperCase() ?? '?'),
                ),
                title: Text(user['full_name'] ?? ''),
                subtitle: Text(user['role'] ?? ''),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openOrCreateConversation(user['id'], user['full_name'] ?? '');
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOrCreateConversation(String otherUserId, String otherName) async {
    // Check if conversation already exists
    final existing = await _supabase
        .from('conversations')
        .select()
        .or('and(user1_id.eq.$_myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$_myId)')
        .maybeSingle();

    String roomId;
    if (existing != null) {
      roomId = existing['id'];
    } else {
      final res = await _supabase.from('conversations').insert({
        'user1_id': _myId,
        'user2_id': otherUserId,
        'last_message': '',
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      roomId = res['id'];
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(roomId: roomId, contactName: otherName, otherUserId: otherUserId),
    )).then((_) { if (mounted) _loadConversations(); });
  }

  String _otherName(Map<String, dynamic> convo) => convo['_other_name'] ?? 'Unknown';
  String _otherId(Map<String, dynamic> convo) => convo['_other_id'] ?? (convo['user1_id'] == _myId ? convo['user2_id'] : convo['user1_id']);
  String? _otherAvatar(Map<String, dynamic> convo) => convo['_other_avatar'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearch,
                decoration: const InputDecoration(hintText: 'Search conversations…', border: InputBorder.none),
              )
            : Text('Messages', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: primary)),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _search.clear(); _filtered = _convos; }
            }),
          ),
          if (!_searching)
            IconButton(icon: const Icon(Icons.edit_square), onPressed: _showNewConversation),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('No conversations yet.', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showNewConversation,
                      icon: const Icon(Icons.edit_square),
                      label: const Text('Start a conversation'),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, i) => const Divider(height: 1, indent: 80),
                    itemBuilder: (context, i) {
                      final convo = _filtered[i];
                      final name = _otherName(convo);
                      final avatar = _otherAvatar(convo);
                      final lastMsg = convo['last_message'] ?? '';
                      final unread = convo['unread_for'] == _myId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: primary.withValues(alpha: 0.15),
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primary))
                              : null,
                        ),
                        title: Text(name, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: unread ? Colors.black87 : Colors.grey[500], fontSize: 13)),
                        ),
                        trailing: unread ? Container(width: 10, height: 10, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)) : null,
                        onTap: () {
                          if (unread) {
                            _supabase.from('conversations').update({'unread_for': null}).eq('id', convo['id']);
                          }
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatScreen(roomId: convo['id'], contactName: name, otherUserId: _otherId(convo)),
                          )).then((_) { if (mounted) _loadConversations(); });
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Chat room ──────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String roomId, contactName, otherUserId;
  const ChatScreen({super.key, required this.roomId, required this.contactName, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  RealtimeChannel? _channel;

  String get _myId => _supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  Future<void> _loadMessages() async {
    final data = await _supabase
        .from('messages')
        .select()
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() => _messages = List<Map<String, dynamic>>.from(data));
      _scrollToBottom();
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('chat_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: widget.roomId),
          callback: (payload) {
            if (!mounted) return;
            final incoming = Map<String, dynamic>.from(payload.newRecord);
            // Only add if it's from the other person (ours is already shown optimistically)
            if (incoming['sender_id'] != _myId) {
              setState(() => _messages.add(incoming));
              _scrollToBottom();
            } else {
              // Replace optimistic with confirmed record
              final idx = _messages.lastIndexWhere((m) => m['id'] == null && m['content'] == incoming['content']);
              if (idx != -1) setState(() => _messages[idx] = incoming);
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    // Optimistic — show instantly
    setState(() {
      _messages.add({'id': null, 'room_id': widget.roomId, 'sender_id': _myId, 'content': text, 'created_at': DateTime.now().toIso8601String()});
      _sending = true;
    });
    _scrollToBottom();
    try {
      await Future.wait([
        _supabase.from('messages').insert({'room_id': widget.roomId, 'sender_id': _myId, 'content': text}),
        // Update conversation preview + mark unread for the other user
        _supabase.from('conversations').update({
          'last_message': text,
          'updated_at': DateTime.now().toIso8601String(),
          'unread_for': widget.otherUserId,
        }).eq('id', widget.roomId),
      ]);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Text(widget.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: Colors.grey[500])))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isMe = msg['sender_id'] == _myId;
                      return _Bubble(content: msg['content'] ?? '', isMe: isMe, primary: primary, pending: msg['id'] == null);
                    },
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _send,
                    child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send, color: Colors.white, size: 20)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String content;
  final bool isMe, pending;
  final Color primary;
  const _Bubble({required this.content, required this.isMe, required this.primary, this.pending = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? (pending ? primary.withValues(alpha: 0.6) : primary) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
      ),
    );
  }
}

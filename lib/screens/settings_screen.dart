import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show navigatorKey;
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  Map<String, dynamic>? _profile;
  bool _savingName = false;
  bool _savingPass = false;
  bool _uploadingAvatar = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final data = await _supabase.from('profiles').select().eq('id', uid).maybeSingle();
    if (mounted) {
      setState(() => _profile = data);
      _nameCtrl.text = data?['full_name'] ?? '';
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final ext = result.files.single.extension ?? 'jpg';
      final path = 'avatars/$uid/profile.$ext';
      await _supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      // Bust cache with timestamp
      final publicUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', uid);
      if (mounted) {
        setState(() => _profile = {...?_profile, 'avatar_url': publicUrl});
        _show('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      if (mounted) _show('Failed to upload picture', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _savingName = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      await _supabase.from('profiles').update({'full_name': _nameCtrl.text.trim()}).eq('id', uid!);
      if (mounted) _show('Name updated successfully', Colors.green);
    } catch (e) {
      if (mounted) _show('Failed to update name', Colors.red);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPassCtrl.text.length < 8) { _show('Password must be at least 8 characters', Colors.red); return; }
    if (_newPassCtrl.text != _confirmPassCtrl.text) { _show('Passwords do not match', Colors.red); return; }
    setState(() => _savingPass = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: _newPassCtrl.text));
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      if (mounted) _show('Password updated successfully', Colors.green);
    } catch (e) {
      if (mounted) _show('Failed to update password', Colors.red);
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _supabase.auth.signOut();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'Volunteer Grid Privacy Policy\n\n'
            'Last updated: June 2025\n\n'
            '1. Information We Collect\n'
            'We collect information you provide when registering, such as your name, email address, and role (volunteer or organisation). We also collect activity data you log within the app.\n\n'
            '2. How We Use Your Information\n'
            'Your information is used to provide and improve the Volunteer Grid service, match volunteers with opportunities, and enable communication between volunteers and organisations.\n\n'
            '3. Data Sharing\n'
            'We do not sell your personal data. Your profile information (name, role) is visible to other users of the platform to enable matching and communication. We do not share data with third parties except as required by law.\n\n'
            '4. Data Storage\n'
            'Your data is stored securely using Supabase infrastructure. We implement industry-standard security measures to protect your information.\n\n'
            '5. Your Rights\n'
            'You may update or delete your account at any time through the Settings page. To request full data deletion, contact us at support@volunteergrid.app.\n\n'
            '6. Cookies\n'
            'This app does not use cookies. Authentication sessions are managed securely on-device.\n\n'
            '7. Changes to This Policy\n'
            'We may update this policy from time to time. Continued use of the app after changes constitutes acceptance of the updated policy.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'Volunteer Grid Terms of Service\n\n'
            'Last updated: June 2025\n\n'
            '1. Acceptance of Terms\n'
            'By using Volunteer Grid, you agree to these Terms of Service. If you do not agree, please do not use the app.\n\n'
            '2. Eligibility\n'
            'You must be at least 13 years old to use this service. Organisations must be legitimate registered entities.\n\n'
            '3. User Responsibilities\n'
            'You are responsible for maintaining the confidentiality of your account. You agree not to post false, misleading, or harmful content. Volunteers agree to honour commitments made to organisations.\n\n'
            '4. Organisation Responsibilities\n'
            'Organisations must post accurate event information. They must not misuse volunteer data or contact volunteers outside the scope of posted events.\n\n'
            '5. AICTE Points\n'
            'Points awarded through the platform are for informational and tracking purposes only. Volunteer Grid makes no guarantees regarding recognition of these points by any external body.\n\n'
            '6. Content Ownership\n'
            'You retain ownership of content you post. By posting, you grant Volunteer Grid a non-exclusive licence to display that content within the app.\n\n'
            '7. Termination\n'
            'We reserve the right to suspend or terminate accounts that violate these terms.\n\n'
            '8. Limitation of Liability\n'
            'Volunteer Grid is provided "as is." We are not liable for any damages arising from use of the platform.\n\n'
            '9. Contact\n'
            'For questions about these terms, contact us at legal@volunteergrid.app.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _show(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final email = _supabase.auth.currentUser?.email ?? '';
    final role = _profile?['role'] ?? 'volunteer';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 24, color: primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + account info
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : email.isNotEmpty ? email[0] : '?').toUpperCase(),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
                        )
                      : null,
                ),
                GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: _uploadingAvatar
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(role == 'organization' ? 'Organisation' : 'Volunteer',
                  style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 28),

          _sectionLabel('Profile'),
          _card([
            _buildField('Full Name', _nameCtrl, Icons.person_outline, TextInputType.name),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: _inputDeco('Email (read-only)', Icons.email_outlined),
              child: Text(email, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingName ? null : _saveName,
                style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _savingName
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Name', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _sectionLabel('Security'),
          _card([
            _buildField('New Password', _newPassCtrl, Icons.lock_outline, TextInputType.visiblePassword,
                obscure: _obscureNew, toggleObscure: () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 12),
            _buildField('Confirm New Password', _confirmPassCtrl, Icons.lock_outline, TextInputType.visiblePassword,
                obscure: _obscureConfirm, toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingPass ? null : _savePassword,
                style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _savingPass
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _sectionLabel('About'),
          _card([
            const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.info_outline), title: Text('App Version'), trailing: Text('1.0.0', style: TextStyle(color: Colors.grey))),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showPrivacyPolicy,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showTermsOfService,
            ),
          ]),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.8)),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, TextInputType type,
      {bool obscure = false, VoidCallback? toggleObscure}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: _inputDeco(label, icon).copyWith(
        suffixIcon: toggleObscure != null
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: toggleObscure)
            : null,
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      );
}

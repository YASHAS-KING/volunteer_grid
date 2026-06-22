import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmitActivityScreen extends StatefulWidget {
  const SubmitActivityScreen({super.key});

  @override
  State<SubmitActivityScreen> createState() => _SubmitActivityScreenState();
}

class _SubmitActivityScreenState extends State<SubmitActivityScreen> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _hoursController = TextEditingController();
  final _pointsController = TextEditingController();

  String _selectedCategory = 'NSS / NCC / Social Clubs';
  bool _isSubmitting = false;
  PlatformFile? _reportFile;
  PlatformFile? _photoFile;
  PlatformFile? _certFile;

  final _categories = [
    'NSS / NCC / Social Clubs',
    'College Fest (UTSAV / PHASE SHIFT)',
    'Teaching Govt School / NGO',
    'Paper Publication / Patent',
    'Value Added Course',
    'Class Representative',
    'Securing Sponsorship',
  ];

  Future<void> _pickFile(String fileType) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: fileType == 'photo' ? FileType.image : FileType.custom,
      allowedExtensions: fileType != 'photo' ? ['pdf', 'doc', 'docx'] : null,
    );
    if (result != null) {
      setState(() {
        if (fileType == 'report') _reportFile = result.files.first;
        if (fileType == 'photo') _photoFile = result.files.first;
        if (fileType == 'cert') _certFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile? file, String folder) async {
    if (file == null || file.bytes == null) return null;
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    await _supabase.storage.from('bmsce_activities').uploadBinary(path, file.bytes!);
    return _supabase.storage.from('bmsce_activities').getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _hoursController.text.isEmpty) {
      _showError('Please fill out the name and hours.');
      return;
    }
    if (_reportFile == null || _photoFile == null || _certFile == null) {
      _showError('Please upload all 3 required documents.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final reportUrl = await _uploadFile(_reportFile, 'reports');
      final photoUrl = await _uploadFile(_photoFile, 'photos');
      final certUrl = await _uploadFile(_certFile, 'certificates');

      await _supabase.from('activities').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'category': _selectedCategory,
        'activity_name': _nameController.text,
        'hours_spent': _hoursController.text,
        'points_claimed': int.tryParse(_pointsController.text) ?? 0,
        'status': 'pending_verification',
        'report_url': reportUrl ?? '',
        'photo_url': photoUrl ?? '',
        'cert_url': certUrl ?? '',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity submitted successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Activity'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 20),
            _buildTextField('Activity Name', 'e.g., Blood Donation Camp', _nameController),
            const SizedBox(height: 20),
            _buildTextField('Hours / Days Spent', 'e.g., 20 hours', _hoursController),
            const SizedBox(height: 20),
            _buildTextField('Points Claimed', 'e.g., 20', _pointsController, isNumber: true),
            const SizedBox(height: 32),
            const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildFileBox('1-Page Activity Report', Icons.description, _reportFile, () => _pickFile('report')),
            _buildFileBox('Geotagged Photos', Icons.add_a_photo, _photoFile, () => _pickFile('photo')),
            _buildFileBox('Official Certificate', Icons.verified, _certFile, () => _pickFile('cert')),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit for Evaluation',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Widget _buildFileBox(String title, IconData icon, PlatformFile? file, VoidCallback onTap) {
    final uploaded = file != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: uploaded ? Colors.green : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: uploaded ? Colors.green.shade50 : Colors.deepPurple.shade50, shape: BoxShape.circle),
            child: Icon(uploaded ? Icons.check : icon, color: uploaded ? Colors.green : Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(uploaded ? file.name : '*Required',
                  style: TextStyle(color: uploaded ? Colors.green : Colors.red, fontSize: 11)),
            ]),
          ),
          OutlinedButton(onPressed: onTap, child: Text(uploaded ? 'Change' : 'Upload')),
        ],
      ),
    );
  }
}

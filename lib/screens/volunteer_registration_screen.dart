// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class VolunteerRegistrationScreen extends StatefulWidget {
//   final String eventTitle;
//   const VolunteerRegistrationScreen({super.key, required this.eventTitle});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Register'), centerTitle: true),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Joining:',
//               style: TextStyle(color: Colors.grey[600], fontSize: 16),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               eventTitle,
//               style: Theme.of(
//                 context,
//               ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 32),
//             _buildTextField(
//               label: 'Full Name',
//               hint: 'Jane Doe',
//               icon: Icons.person_outline,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Email Address',
//               hint: 'jane@example.com',
//               icon: Icons.email_outlined,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Phone Number',
//               hint: '+1 (555) 000-0000',
//               icon: Icons.phone_outlined,
//             ),
//             const SizedBox(height: 20),
//             _buildTextField(
//               label: 'Any previous experience? (Optional)',
//               hint: 'Tell us about yourself...',
//               icon: Icons.info_outline,
//               maxLines: 3,
//             ),
//             const SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).popUntil((r) => r.isFirst);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Registration Successful!'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).colorScheme.primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'Submit Application',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String hint,
//     required IconData icon,
//     int maxLines = 1,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey) : null,
//             filled: true,
//             fillColor: Colors.grey[100],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  final String eventTitle;
  const VolunteerRegistrationScreen({super.key, required this.eventTitle});

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  final _supabase = Supabase.instance.client;
  
  // 1. Initialize Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  // 2. Fetch User Data
  Future<void> _prefillUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
          
      if (profile != null && profile['full_name'] != null && mounted) {
        setState(() {
          _nameController.text = profile['full_name'];
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Joining:', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 4),
            Text(widget.eventTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            
            // 3. Connect Controllers to TextFields
            _buildTextField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField(label: 'Email Address', controller: _emailController, icon: Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField(label: 'Phone Number', controller: _phoneController, icon: Icons.phone_outlined),
            const SizedBox(height: 20),
            _buildTextField(label: 'Any previous experience?', controller: _experienceController, icon: Icons.info_outline, maxLines: 3),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add your Supabase insert logic here!
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Submit Application', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // <-- Controller wired here!
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

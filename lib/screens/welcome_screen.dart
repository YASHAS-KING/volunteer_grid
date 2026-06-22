import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?auto=format&fit=crop&w=1080&q=80',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.deepPurple.shade900.withValues(alpha: 0.95)],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volunteer\nGrid.',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect with causes you care about. Make a real impact in your community.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, height: 1.5),
                ),
                const SizedBox(height: 40),
                _RoleButton(
                  title: 'I am a Volunteer',
                  icon: Icons.favorite,
                  isOutlined: false,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen(initialRole: 'volunteer'))),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'I am an Organization',
                  icon: Icons.business,
                  isOutlined: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen(initialRole: 'organization'))),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text(
                      'Already have an account? Log In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isOutlined;
  final VoidCallback onTap;

  const _RoleButton({required this.title, required this.icon, required this.isOutlined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: isOutlined ? Colors.white : Theme.of(context).colorScheme.primary),
        label: Text(
          title,
          style: TextStyle(
            color: isOutlined ? Colors.white : Theme.of(context).colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : Colors.white,
          side: isOutlined ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: isOutlined ? 0 : 2,
        ),
      ),
    );
  }
}

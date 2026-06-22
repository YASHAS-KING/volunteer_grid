import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_layout.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://znpjlhisoryaeylptled.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpucGpsaGlzb3J5YWV5bHB0bGVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTU1NDIsImV4cCI6MjA5NTUzMTU0Mn0.VWv5kx0p4ISUJBzjJfJNNkjhjUs5SGSuMFcrYDViPlk',
  );
  runApp(const VolunteerGridApp());
}

class VolunteerGridApp extends StatelessWidget {
  const VolunteerGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer Grid',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    // Give the SDK one frame to restore a persisted session before deciding
    Supabase.instance.client.auth.onAuthStateChange.first.then((_) {
      if (mounted) setState(() => _initializing = false);
    });
    // Fallback: stop loading after 2 s even if no event fires
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _initializing) setState(() => _initializing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) return const MainLayout();
        return const WelcomeScreen();
      },
    );
  }
}

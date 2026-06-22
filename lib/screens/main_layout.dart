import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'org_feed_screen.dart';
import 'map_view_screen.dart';
import 'messages_screen.dart';
import 'org_dashboard_screen.dart';
import 'home_feed_screen.dart';
import 'activity_points_screen.dart';
import 'volunteer_dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String _role = 'volunteer';
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _roleLoaded = true);
      return;
    }
    final data = await Supabase.instance.client
        .from('profiles').select('role').eq('id', uid).maybeSingle();
    if (mounted) {
      setState(() {
        _role = data?['role'] ?? 'volunteer';
        _roleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isOrg = _role == 'organization';

    // Org: Feed | Map | Chat | Dashboard
    // Volunteer: Feed | Map | AICTE | Chat | Profile
    final screens = isOrg
        ? [const OrgFeedScreen(), const MapViewScreen(), const MessagesScreen(), const OrganizationDashboardScreen()]
        : [const HomeFeedScreen(), const MapViewScreen(), const ActivityPointsScreen(), const MessagesScreen(), const VolunteerDashboardScreen()];

    final destinations = isOrg
        ? const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Feed'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Dashboard'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Feed'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.stars_outlined), selectedIcon: Icon(Icons.stars), label: 'AICTE'),
            NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: destinations,
      ),
    );
  }
}

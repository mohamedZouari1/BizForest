import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/map_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/records_screen.dart';
import 'screens/planting_screen.dart';
import 'screens/incidents_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase successfully initialized!');
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
  }

  final storage = StorageService();
  final role = await storage.getRole();
  runApp(BizForestApp(initialRole: role));
}

class BizForestApp extends StatelessWidget {
  final UserRole? initialRole;

  const BizForestApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizForest',
      theme: buildAppTheme(),
      home: initialRole == null
          ? const OnboardingScreen()
          : AppShell(role: initialRole!),
    );
  }
}

class AppShell extends StatefulWidget {
  final UserRole role;

  const AppShell({super.key, required this.role});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Pages based on role
  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _buildNav();
  }

  void _buildNav() {
    switch (widget.role) {
      case UserRole.field:
        _pages = [
          const MapScreen(),
          const SurveyScreen(),
          const PlantingScreen(),
          const RecordsScreen(),
        ];
        _destinations = const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Survey'),
          NavigationDestination(icon: Icon(Icons.nature_outlined), selectedIcon: Icon(Icons.nature), label: 'Planting'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Records'),
        ];
        break;
      case UserRole.manager:
        _pages = [
          const DashboardScreen(),
          const MapScreen(),
          const RecordsScreen(),
        ];
        _destinations = const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Records'),
        ];
        break;
      case UserRole.government:
        _pages = [
          const DashboardScreen(),
          const MapScreen(),
        ];
        _destinations = const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
        ];
        break;
      case UserRole.public:
        _pages = [
          const MapScreen(),
          const PlantingScreen(),
          const IncidentsScreen(),
        ];
        _destinations = const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.nature_outlined), selectedIcon: Icon(Icons.nature), label: 'Planting'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning), label: 'Incidents'),
        ];
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('BizForest', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.role.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.role.color.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(widget.role.icon, size: 14, color: widget.role.color),
                  const SizedBox(width: 4),
                  Text(
                    widget.role.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.role.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (idx) => setState(() => _index = idx),
        destinations: _destinations,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/presentation/screens/analytics/analytics_dashboard_screen.dart';
import 'package:smartgymai/presentation/screens/activity_log/activity_log_screen.dart';
import 'package:smartgymai/presentation/screens/user_management/user_management_screen.dart';
import 'package:smartgymai/presentation/screens/settings/settings_screen.dart';
import 'package:smartgymai/presentation/screens/ai_analytics/ai_analytics_screen.dart';
import 'package:smartgymai/presentation/widgets/connection_status_bar.dart';
import 'package:smartgymai/providers/sensors_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
    final List<Widget> _screens = [
    const AnalyticsDashboardScreen(),
    const UserManagementScreen(),
    const ActivityLogScreen(),
    const AIAnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataIfNeeded();
    });
  }

  void _refreshDataIfNeeded() {
    // If we're on the dashboard tab, refresh the occupancy data
    if (_selectedIndex == 0) {
      ref.read(sensorsProvider.notifier).refreshOccupancyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Connection status bar at the top
          const ConnectionStatusBar(),
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            // Refresh data when switching to the dashboard tab
            _refreshDataIfNeeded();
          });
        },        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 
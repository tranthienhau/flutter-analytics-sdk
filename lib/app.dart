import 'package:flutter/material.dart';

import 'features/attribution/attribution_screen.dart';
import 'features/events/event_builder_screen.dart';
import 'features/events/event_log_screen.dart';
import 'features/settings/consent_screen.dart';
import 'features/settings/debug_screen.dart';
import 'features/tracking/tracking_screen.dart';

class AnalyticsApp extends StatelessWidget {
  const AnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analytics SDK POC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const _MainShell(),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _tabs = <_TabDefinition>[
    _TabDefinition(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _TabDefinition(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt,
      label: 'Events',
    ),
    _TabDefinition(
      icon: Icons.attribution_outlined,
      activeIcon: Icons.attribution,
      label: 'Attribution',
    ),
    _TabDefinition(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const TrackingScreen();
      case 1:
        return const _EventsSubNav();
      case 2:
        return const AttributionScreen();
      case 3:
        return const _SettingsSubNav();
      default:
        return const TrackingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabDefinition {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabDefinition({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ---------------------------------------------------------------------------
// Events sub-navigation (builder + log)
// ---------------------------------------------------------------------------

class _EventsSubNav extends StatelessWidget {
  const _EventsSubNav();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Builder'),
              Tab(icon: Icon(Icons.list_alt), text: 'Log'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EventBuilderScreen(),
            EventLogScreen(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings sub-navigation (consent + debug)
// ---------------------------------------------------------------------------

class _SettingsSubNav extends StatelessWidget {
  const _SettingsSubNav();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shield_outlined), text: 'Consent'),
              Tab(icon: Icon(Icons.bug_report_outlined), text: 'Debug'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ConsentScreen(),
            DebugScreen(),
          ],
        ),
      ),
    );
  }
}

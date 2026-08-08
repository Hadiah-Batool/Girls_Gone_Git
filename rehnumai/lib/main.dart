import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'presentation/screens/student_list/heatmap_screen.dart';
import 'presentation/screens/daily_log/quick_log_screen.dart';
import 'presentation/screens/analysis/reasoning_trail_screen.dart';
import 'presentation/screens/amal/intervention_screen.dart';
import 'presentation/widgets/app_bottom_nav.dart';

void main() {
  runApp(const RehnumaiApp());
}

class RehnumaiApp extends StatelessWidget {
  const RehnumaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rehnumai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

/// Root shell that hosts the 4-tab bottom nav and an IndexedStack of screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Screens kept alive via IndexedStack — they preserve scroll / state.
  static const List<Widget> _screens = [
    HeatmapScreen(),      // 0 — Darsgah
    QuickLogScreen(),     // 1 — Logs
    ReasoningTrailScreen(), // 2 — Nazar
    InterventionScreen(), // 3 — Amal
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

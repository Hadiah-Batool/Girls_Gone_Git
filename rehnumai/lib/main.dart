// lib/main.dart
//
// Rehnumai – Student Risk Analyzer
// Entry point: loads .env (backend API key), initializes AppState, then boots UI shell.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'core/constants/app_theme.dart';
import 'presentation/screens/profile/entrance_screen.dart';
import 'presentation/screens/student_list/heatmap_screen.dart';
import 'presentation/screens/daily_log/quick_log_screen.dart';
import 'presentation/screens/analysis/reasoning_trail_screen.dart';
import 'presentation/screens/amal/intervention_screen.dart';
import 'presentation/widgets/app_bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — required by the backend OCR → agent pipeline.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const RehnumaiApp(),
    ),
  );
}

class RehnumaiApp extends StatelessWidget {
  const RehnumaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Rehnumai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: appState.isProfileComplete
          ? const MainShell()
          : const EntranceScreen(),
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
    HeatmapScreen(),        // 0 — Darsgah
    QuickLogScreen(),       // 1 — Logs
    ReasoningTrailScreen(), // 2 — Nazar
    InterventionScreen(),   // 3 — Amal
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

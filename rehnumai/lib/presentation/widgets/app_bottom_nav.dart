import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Bottom navigation bar used across all Rehnumai screens.
///
/// Tabs:  0 = Home, 1 = Logs, 2 = View, 3 = Action
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final navBg = isDark ? const Color(0xFF26211D) : AppColors.surfaceContainer;
    final indicatorBg = isDark ? const Color(0xFF42372F) : AppColors.surfaceContainerHigh;
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: indicatorBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: textSecondary);
        }),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: navBg,
        indicatorColor: indicatorBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'View',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Action',
          ),
        ],
      ),
    );
  }
}


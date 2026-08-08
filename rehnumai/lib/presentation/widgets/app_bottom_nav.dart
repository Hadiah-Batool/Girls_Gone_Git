import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Bottom navigation bar used across all Rehnumai screens.
///
/// Tabs:  0 = Darsgah, 1 = Logs, 2 = Nazar, 3 = Amal
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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.surfaceContainer,
      indicatorColor: AppColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          label: _label('Darsgah'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.edit_note_outlined),
          selectedIcon: const Icon(Icons.edit_note),
          label: _label('Logs'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: _label('Nazar'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.message_outlined),
          selectedIcon: const Icon(Icons.message),
          label: _label('Amal'),
        ),
      ],
    );
  }

  String _label(String text) => text;
}

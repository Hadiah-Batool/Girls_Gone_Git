import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: appState.isDarkMode,
            onChanged: (val) {
              context.read<AppState>().toggleTheme();
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          
          // Notifications
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive daily summaries'),
            value: true,
            onChanged: (val) {
              // Mock implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings updated')),
              );
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),

          // Language Selection
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English (Default)'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More languages coming soon!')),
              );
            },
          ),
          const Divider(),

          // About App
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Rehnumai'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Rehnumai',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.school, size: 48),
                children: [
                  const Text('AI-powered educational assistant for teachers.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

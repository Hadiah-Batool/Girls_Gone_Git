import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/scan_sheet/scan_sheet_screen.dart';

/// Shared side-drawer menu for Rehnumai app.
class RehnumaiDrawer extends StatelessWidget {
  const RehnumaiDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final drawerBg = AppColors.getBg(context);

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFFBF5246)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'رہنمائی',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.teacherName.isNotEmpty
                        ? appState.teacherName
                        : 'Teacher Menu',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    iconColor: AppColors.primary,
                    label: 'Edit Teacher Profile',
                    subtitle: appState.teacherName.isNotEmpty
                        ? appState.teacherName
                        : 'Not set',
                    onTap: () {
                      Navigator.pop(context);
                      _showEditProfileDialog(context, appState);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _DrawerToggleItem(
                    icon: appState.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    iconColor: AppColors.secondary,
                    label: 'Dark Mode',
                    value: appState.isDarkMode,
                    onChanged: (_) => appState.toggleTheme(),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    iconColor: AppColors.getOnSurfaceVariant(context),
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _DrawerItem(
                    icon: Icons.document_scanner_rounded,
                    iconColor: AppColors.tertiary,
                    label: 'Scan Student Sheet',
                    subtitle: 'Add students via camera',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScanSheetScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _DrawerItem(
                    icon: Icons.restore_rounded,
                    iconColor: AppColors.primary,
                    label: 'Reset Sample Data',
                    subtitle: 'Load demo students',
                    onTap: () {
                      Navigator.pop(context);
                      appState.resetDummyData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dataset reset to sample students!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                    label: 'Clear All Data',
                    subtitle: 'Remove all student records',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all data?'),
                          content: const Text(
                              'This will remove all student records. This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                appState.clearAllDummyData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All data cleared.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.getOnSurfaceVariant(context),
                    label: 'About Rehnumai',
                    subtitle: 'v1.0.0 — AI risk analyzer',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'Rehnumai',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.school,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        children: [
                          const Text(
                            'AI-powered student risk analyzer for teachers. Identify at-risk students early and take timely action.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditProfileDialog(appState: appState),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _DrawerToggleItem extends StatelessWidget {
  const _DrawerToggleItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);

    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.appState});
  final AppState appState;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _educationCtrl;
  late final TextEditingController _occupationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.appState.teacherName);
    _ageCtrl = TextEditingController(text: widget.appState.teacherAge);
    _educationCtrl = TextEditingController(text: widget.appState.teacherEducation);
    _occupationCtrl = TextEditingController(text: widget.appState.teacherOccupation);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogBg = AppColors.getCardBg(context);

    return AlertDialog(
      backgroundColor: dialogBg,
      title: Row(
        children: [
          const Icon(Icons.person_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Edit Teacher Profile',
            style: AppTextStyles.headlineMd.copyWith(
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(_nameCtrl, 'Name', Icons.badge_rounded),
                const SizedBox(height: 12),
                _buildField(_ageCtrl, 'Age', Icons.cake_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildField(_educationCtrl, 'Education', Icons.school_rounded),
                const SizedBox(height: 12),
                _buildField(_occupationCtrl, 'Occupation / Subject',
                    Icons.work_rounded),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_rounded, size: 16),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.appState.saveProfile(
                name: _nameCtrl.text.trim(),
                age: _ageCtrl.text.trim(),
                education: _educationCtrl.text.trim(),
                occupation: _occupationCtrl.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final inputBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorderColor(context);

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

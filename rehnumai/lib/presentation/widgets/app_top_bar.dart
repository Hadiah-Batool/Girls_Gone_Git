import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/app_state.dart';

/// Shared top app bar used across all Rehnumai screens.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final initial = appState.teacherName.isNotEmpty
        ? appState.teacherName.trim()[0].toUpperCase()
        : 'T';

    return AppBar(
      backgroundColor: AppColors.surfaceBright,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primary),
        onPressed: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
        tooltip: 'Menu',
      ),
      title: Text(
        'رہنمائی',
        style: GoogleFonts.manrope(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showProfileSheet(context, appState),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceBright,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _TeacherProfileSheet(appState: appState),
    );
  }
}

// ─── Teacher Profile Bottom Sheet ─────────────────────────────────────────────

class _TeacherProfileSheet extends StatefulWidget {
  const _TeacherProfileSheet({required this.appState});
  final AppState appState;

  @override
  State<_TeacherProfileSheet> createState() => _TeacherProfileSheetState();
}

class _TeacherProfileSheetState extends State<_TeacherProfileSheet> {
  bool _isEditing = false;
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      widget.appState.saveProfile(
        name: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        education: _educationCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim(),
      );
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final initial = appState.teacherName.isNotEmpty
        ? appState.teacherName.trim()[0].toUpperCase()
        : 'T';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.teacherName.isNotEmpty
                            ? appState.teacherName
                            : 'Teacher',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 18,
                          color: AppColors.inkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (appState.teacherOccupation.isNotEmpty)
                        Text(
                          appState.teacherOccupation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                  icon: Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_isEditing) ...[
              // View mode — show profile info cards
              _ProfileInfoRow(
                icon: Icons.cake_rounded,
                label: 'Age',
                value: appState.teacherAge.isNotEmpty ? appState.teacherAge : '—',
              ),
              const SizedBox(height: 8),
              _ProfileInfoRow(
                icon: Icons.school_rounded,
                label: 'Education',
                value: appState.teacherEducation.isNotEmpty
                    ? appState.teacherEducation
                    : '—',
              ),
              const SizedBox(height: 8),
              _ProfileInfoRow(
                icon: Icons.work_rounded,
                label: 'Occupation',
                value: appState.teacherOccupation.isNotEmpty
                    ? appState.teacherOccupation
                    : '—',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else ...[
              // Edit mode — show form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(_nameCtrl, 'Name', Icons.badge_rounded),
                    const SizedBox(height: 12),
                    _buildField(_ageCtrl, 'Age', Icons.cake_rounded,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildField(_educationCtrl, 'Education', Icons.school_rounded),
                    const SizedBox(height: 12),
                    _buildField(
                        _occupationCtrl, 'Occupation / Subject', Icons.work_rounded),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkText,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/mock_students.dart';
import '../../../data/models/student_model.dart';
import '../../widgets/app_top_bar.dart';
import '../scan_sheet/scan_sheet_screen.dart';
import '../analysis/reasoning_trail_screen.dart';
import '../profile/settings_screen.dart';

// ─── Data model ─────────────────────────────────────────────────────────────

enum RiskLevel { stable, medium, high }

class StudentTile {
  const StudentTile({
    required this.initials,
    required this.name,
    required this.risk,
    this.lastLogged = '2 hrs ago',
  });
  final String initials;
  final String name;
  final RiskLevel risk;
  final String lastLogged;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _searchQuery = '';

  List<StudentTile> _getActiveStudents(List<Student> activeStudents) {
    if (activeStudents.isEmpty) return const [];
    return activeStudents.map((s) {
      final initials = s.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
      RiskLevel risk = RiskLevel.stable;
      if (s.hasFeeOverdue || s.attendanceRate < 60) {
        risk = RiskLevel.high;
      } else if (s.attendanceRate < 80 || (s.latestScore != null && s.latestScore! < 65)) {
        risk = RiskLevel.medium;
      }
      return StudentTile(
        initials: initials.isNotEmpty ? initials : 'ST',
        name: s.name,
        risk: risk,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentStudents = _getActiveStudents(appState.students);
    final highCount = currentStudents.where((s) => s.risk == RiskLevel.high).length;
    final mediumCount = currentStudents.where((s) => s.risk == RiskLevel.medium).length;
    final stableCount = currentStudents.where((s) => s.risk == RiskLevel.stable).length;

    final filteredStudents = _searchQuery.isEmpty
        ? currentStudents
        : currentStudents.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final bg = AppColors.getBg(context);
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: const AppTopBar(),
      drawer: _RehnumaiDrawer(appState: appState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanSheetScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Sheet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClassStatusCard(
              total: currentStudents.length,
              highCount: highCount,
              mediumCount: mediumCount,
              stableCount: stableCount,
            ),
            const SizedBox(height: 24),
            TextField(
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search student...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: textSecondary),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              "Ustaad's Eye",
              style: AppTextStyles.headlineMd.copyWith(
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (filteredStudents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No student records found.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        onPressed: () => appState.resetDummyData(),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Load Sample Students'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredStudents.map((student) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _StudentCard(
                    student: student,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─── Class Status Card ───────────────────────────────────────────────────────

class _ClassStatusCard extends StatelessWidget {
  const _ClassStatusCard({
    required this.total,
    required this.highCount,
    required this.mediumCount,
    required this.stableCount,
  });

  final int total;
  final int highCount;
  final int mediumCount;
  final int stableCount;

  @override
  Widget build(BuildContext context) {
    final sandBg = AppColors.getSandBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Container(
      decoration: BoxDecoration(
        color: sandBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Status',
                            style: AppTextStyles.headlineMd.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade 8 – English Section A',
                            style: AppTextStyles.bodySm.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          stable: total > 0 ? stableCount / total : 1.0,
                          medium: total > 0 ? mediumCount / total : 0.0,
                          high: total > 0 ? highCount / total : 0.0,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: textPrimary,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'TOTAL',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _LegendDot(
                      color: AppColors.riskHigh,
                      label: 'At-Risk ($highCount)',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: AppColors.riskMedium,
                      label: 'Moderate ($mediumCount)',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: AppColors.riskStable,
                      label: 'Stable ($stableCount)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(color: textPrimary),
        ),
      ],
    );
  }
}

// ─── Donut CustomPainter ─────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.stable,
    required this.medium,
    required this.high,
  });

  final double stable;
  final double medium;
  final double high;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 10.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const start = -math.pi / 2;
    final fullAngle = 2 * math.pi;

    void drawArc(double startAngle, double sweepAngle, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    double offset = start;
    final stableSweep = fullAngle * stable;
    drawArc(offset, stableSweep, AppColors.riskStable);
    offset += stableSweep;

    final mediumSweep = fullAngle * medium;
    drawArc(offset, mediumSweep, AppColors.riskMedium);
    offset += mediumSweep;

    final highSweep = fullAngle * high;
    drawArc(offset, highSweep, AppColors.riskHigh);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.stable != stable || old.medium != medium || old.high != high;
}

// ─── Student Components ───────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentTile student;
  const _StudentCard({required this.student});

  Color get _avatarBg => switch (student.risk) {
        RiskLevel.high => AppColors.primaryFixedDim,
        RiskLevel.medium => AppColors.secondaryFixed,
        RiskLevel.stable => AppColors.tertiaryFixed,
      };

  Student _getStudentModel(BuildContext context, StudentTile tile) {
    final appState = Provider.of<AppState>(context, listen: false);
    final match = appState.students.where((s) => s.name.toLowerCase() == tile.name.toLowerCase());
    if (match.isNotEmpty) return match.first;

    if (tile.risk == RiskLevel.high) {
      return mockStudents[0];
    } else if (tile.risk == RiskLevel.medium) {
      return mockStudents[1];
    } else {
      return mockStudents[2];
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetStudent = _getStudentModel(context, student);
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final borderColor = AppColors.getBorderColor(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReasoningTrailScreen(
              student: targetStudent,
              autoRun: false,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _avatarBg,
              child: Text(
                student.initials,
                style: AppTextStyles.dataMono.copyWith(color: AppColors.onPrimaryFixed),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _RiskBadge(risk: student.risk),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReasoningTrailScreen(
                            student: targetStudent,
                            autoRun: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 13),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReasoningTrailScreen(
                            student: targetStudent,
                            autoRun: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 13),
                    label: const Text('View Result'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Risk Badge ──────────────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});
  final RiskLevel risk;

  Color get _color => switch (risk) {
        RiskLevel.high => AppColors.riskHigh,
        RiskLevel.medium => AppColors.riskMedium,
        RiskLevel.stable => AppColors.riskStable,
      };

  String get _label => switch (risk) {
        RiskLevel.high => 'At Risk',
        RiskLevel.medium => 'Moderate',
        RiskLevel.stable => 'Stable',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Rehnumai Drawer ─────────────────────────────────────────────────────────

class _RehnumaiDrawer extends StatelessWidget {
  const _RehnumaiDrawer({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
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

// ─── Drawer Item Widgets ──────────────────────────────────────────────────────

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

// ─── Edit Profile Dialog ──────────────────────────────────────────────────────

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

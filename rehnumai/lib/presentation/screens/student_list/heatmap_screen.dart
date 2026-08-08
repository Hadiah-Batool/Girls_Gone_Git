import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../widgets/app_top_bar.dart';

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

const List<StudentTile> _students = [
  StudentTile(initials: 'AK', name: 'Ali', risk: RiskLevel.stable),
  StudentTile(initials: 'SM', name: 'Sara', risk: RiskLevel.stable),
  StudentTile(initials: 'ZB', name: 'Zain', risk: RiskLevel.stable),
  StudentTile(initials: 'HY', name: 'Haya', risk: RiskLevel.medium),
  StudentTile(initials: 'FT', name: 'Fatima', risk: RiskLevel.stable),
  StudentTile(initials: 'UF', name: 'Umar', risk: RiskLevel.high, lastLogged: '2 hrs ago'),
  StudentTile(initials: 'RN', name: 'Rana', risk: RiskLevel.stable),
  StudentTile(initials: 'LA', name: 'Laila', risk: RiskLevel.stable),
  StudentTile(initials: 'MS', name: 'Musa', risk: RiskLevel.medium),
  StudentTile(initials: 'DK', name: 'Danish', risk: RiskLevel.stable),
  StudentTile(initials: 'TJ', name: 'Taj', risk: RiskLevel.stable),
  StudentTile(initials: 'WQ', name: 'Waqas', risk: RiskLevel.high),
  StudentTile(initials: 'PL', name: 'Pal', risk: RiskLevel.stable),
  StudentTile(initials: 'GH', name: 'Ghani', risk: RiskLevel.stable),
  StudentTile(initials: 'ER', name: 'Erum', risk: RiskLevel.high),
  StudentTile(initials: 'TY', name: 'Tayyab', risk: RiskLevel.stable),
  StudentTile(initials: 'UI', name: 'Umair', risk: RiskLevel.stable),
  StudentTile(initials: 'OP', name: 'Omer', risk: RiskLevel.medium),
  StudentTile(initials: 'AS', name: 'Asad', risk: RiskLevel.stable),
  StudentTile(initials: 'DF', name: 'Daud', risk: RiskLevel.stable),
  StudentTile(initials: 'CV', name: 'Cavi', risk: RiskLevel.stable),
  StudentTile(initials: 'NB', name: 'Nadia', risk: RiskLevel.stable),
  StudentTile(initials: 'KR', name: 'Kamran', risk: RiskLevel.medium),
  StudentTile(initials: 'SI', name: 'Sania', risk: RiskLevel.stable),
  StudentTile(initials: 'YA', name: 'Yasir', risk: RiskLevel.stable),
  StudentTile(initials: 'BH', name: 'Bushra', risk: RiskLevel.stable),
  StudentTile(initials: 'TK', name: 'Tariq', risk: RiskLevel.stable),
  StudentTile(initials: 'MZ', name: 'Maaz', risk: RiskLevel.high),
  StudentTile(initials: 'RB', name: 'Rabail', risk: RiskLevel.stable),
  StudentTile(initials: 'IQ', name: 'Iqra', risk: RiskLevel.stable),
  StudentTile(initials: 'SH', name: 'Shams', risk: RiskLevel.high),
  StudentTile(initials: 'FQ', name: 'Faiqa', risk: RiskLevel.stable),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen>
    with SingleTickerProviderStateMixin {
  StudentTile? _selectedStudent;
  late AnimationController _popoverController;
  late Animation<double> _popoverAnimation;

  @override
  void initState() {
    super.initState();
    _popoverController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _popoverAnimation = CurvedAnimation(
      parent: _popoverController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  void _selectStudent(StudentTile student) {
    setState(() => _selectedStudent = student);
    _popoverController.forward();
  }

  void _closePopover() {
    _popoverController.reverse().then((_) {
      if (mounted) setState(() => _selectedStudent = null);
    });
  }

  // Counts
  int get _highCount => _students.where((s) => s.risk == RiskLevel.high).length;
  int get _mediumCount =>
      _students.where((s) => s.risk == RiskLevel.medium).length;
  int get _stableCount =>
      _students.where((s) => s.risk == RiskLevel.stable).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
      body: Stack(
        children: [
          // ── Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClassStatusCard(
                  total: _students.length,
                  highCount: _highCount,
                  mediumCount: _mediumCount,
                  stableCount: _stableCount,
                ),
                const SizedBox(height: 24),
                _HeatmapSection(
                  students: _students,
                  selected: _selectedStudent,
                  onTap: _selectStudent,
                ),
              ],
            ),
          ),

          // ── Popover overlay
          if (_selectedStudent != null)
            GestureDetector(
              onTap: _closePopover,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          AnimatedBuilder(
            animation: _popoverAnimation,
            builder: (context, child) {
              return Positioned(
                left: 16,
                right: 16,
                bottom: 96 + (_popoverAnimation.value - 1) * 40,
                child: Opacity(
                  opacity: _popoverAnimation.value,
                  child: child,
                ),
              );
            },
            child: _selectedStudent != null
                ? _StudentPopover(
                    student: _selectedStudent!,
                    onClose: _closePopover,
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sandBg,
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
          // Decorative blur orb
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
                              color: AppColors.inkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade 8 – English Section A',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Donut chart
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          stable: stableCount / total,
                          medium: mediumCount / total,
                          high: highCount / total,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: AppColors.inkText,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'TOTAL',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: AppColors.onSurfaceVariant,
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
          style: AppTextStyles.labelCaps.copyWith(color: AppColors.inkText),
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

    // Start from top (-π/2), sweep full circle
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

// ─── Heatmap Section ─────────────────────────────────────────────────────────

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({
    required this.students,
    required this.selected,
    required this.onTap,
  });

  final List<StudentTile> students;
  final StudentTile? selected;
  final ValueChanged<StudentTile> onTap;

  static const int _columns = 7;

  @override
  Widget build(BuildContext context) {
    // Split into rows of 7
    final rows = <List<StudentTile>>[];
    for (var i = 0; i < students.length; i += _columns) {
      rows.add(
        students.sublist(i, math.min(i + _columns, students.length)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Ustaad's Eye",
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.inkText,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Filter',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: row.map((student) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _HeatmapCell(
                        student: student,
                        isSelected: selected == student,
                        onTap: () => onTap(student),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  final StudentTile student;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _bgColor {
    switch (student.risk) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.stable:
        return AppColors.riskStable;
    }
  }

  Color get _textColor {
    switch (student.risk) {
      case RiskLevel.high:
        return AppColors.onErrorContainer;
      case RiskLevel.medium:
        return AppColors.onSecondaryFixedVariant;
      case RiskLevel.stable:
        return AppColors.onTertiaryFixedVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Text(
                  student.initials,
                  style: AppTextStyles.dataMono.copyWith(color: _textColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          student.name,
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Student Popover ─────────────────────────────────────────────────────────

class _StudentPopover extends StatelessWidget {
  const _StudentPopover({required this.student, required this.onClose});

  final StudentTile student;
  final VoidCallback onClose;

  Color get _avatarBg => switch (student.risk) {
        RiskLevel.high => AppColors.primaryFixedDim,
        RiskLevel.medium => AppColors.secondaryFixed,
        RiskLevel.stable => AppColors.tertiaryFixed,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarBg,
                  child: Text(
                    student.initials,
                    style: AppTextStyles.dataMono.copyWith(
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkText,
                        ),
                      ),
                      Text(
                        'Last logged: ${student.lastLogged}',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Log'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkText,
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: AppTextStyles.labelCaps,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: AppTextStyles.labelCaps,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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


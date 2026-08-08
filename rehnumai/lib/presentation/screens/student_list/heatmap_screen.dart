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

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _searchQuery = '';

  // Counts
  int get _highCount => _students.where((s) => s.risk == RiskLevel.high).length;
  int get _mediumCount =>
      _students.where((s) => s.risk == RiskLevel.medium).length;
  int get _stableCount =>
      _students.where((s) => s.risk == RiskLevel.stable).length;

  List<StudentTile> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showLogDialog(StudentTile student) {
    showDialog(
      context: context,
      builder: (context) => _LogStudentDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
      drawer: Drawer(
        backgroundColor: AppColors.surfaceBright,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Text(
                'Rehnumai Menu',
                style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanning Attendance Sheet...')),
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
              total: _students.length,
              highCount: _highCount,
              mediumCount: _mediumCount,
              stableCount: _stableCount,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search student...',
                prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
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
                color: AppColors.inkText,
              ),
            ),
            const SizedBox(height: 12),
            ..._filteredStudents.map((student) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _StudentCard(
                  student: student,
                  onLog: () => _showLogDialog(student),
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

// ─── Student Components ───────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentTile student;
  final VoidCallback onLog;
  const _StudentCard({required this.student, required this.onLog});

  Color get _avatarBg => switch (student.risk) {
        RiskLevel.high => AppColors.primaryFixedDim,
        RiskLevel.medium => AppColors.secondaryFixed,
        RiskLevel.stable => AppColors.tertiaryFixed,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _avatarBg,
            child: Text(
              student.initials,
              style: AppTextStyles.dataMono.copyWith(color: AppColors.onPrimaryFixed),
            ),
          ),
          const SizedBox(width: 16),
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
                  'Risk: ${student.risk.name}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onLog,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Log'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.inkText,
              side: const BorderSide(color: AppColors.outline),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: AppTextStyles.labelCaps,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogStudentDialog extends StatefulWidget {
  final StudentTile student;
  const _LogStudentDialog({required this.student});

  @override
  State<_LogStudentDialog> createState() => _LogStudentDialogState();
}

class _LogStudentDialogState extends State<_LogStudentDialog> {
  final Set<String> _selectedTags = {};
  final List<String> _tags = ['Attendance', 'Academics', 'Behaviors'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceBright,
      title: Text('Log Data: ${widget.student.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select categories to log:'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor: AppColors.primaryContainer,
                checkmarkColor: AppColors.onPrimaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter log details...',
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
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged for ${widget.student.name}')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
          child: const Text('Save Log'),
        ),
      ],
    );
  }
}

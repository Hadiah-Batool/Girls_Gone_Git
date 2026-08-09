import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/student_model.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/rehnumai_drawer.dart';
import '../scan_sheet/scan_sheet_screen.dart';
import '../analysis/reasoning_trail_screen.dart';

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
      drawer: const RehnumaiDrawer(),
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
    if (appState.students.isNotEmpty) return appState.students.first;
    return Student(
      id: 'stu_temp',
      name: tile.name,
      grade: '8-A',
      attendance: const [],
      fees: const [],
      examScores: const {},
      teacherNotes: const [],
    );
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



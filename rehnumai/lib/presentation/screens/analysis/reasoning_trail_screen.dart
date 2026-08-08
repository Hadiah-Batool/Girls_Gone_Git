import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../widgets/app_top_bar.dart';

// ─── Data for the sparkline ───────────────────────────────────────────────────

const List<double> _attendanceData = [
  90, 88, 85, 80, 75, 70, 72, 68, 65, 60, 58, 55
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class ReasoningTrailScreen extends StatefulWidget {
  const ReasoningTrailScreen({super.key});

  @override
  State<ReasoningTrailScreen> createState() => _ReasoningTrailScreenState();
}

class _ReasoningTrailScreenState extends State<ReasoningTrailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;
  bool _teacherOverrideOn = false;
  final _correctionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _lineController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Student header card
            _StudentHeaderCard(),
            const SizedBox(height: 24),

            // ── Reasoning Trail section
            _SectionTitle(
              icon: Icons.psychology,
              title: 'Reasoning Trail',
            ),
            const SizedBox(height: 16),
            _ReasoningTimeline(),
            const SizedBox(height: 24),

            // ── Attendance sparkline
            _SectionTitle(
              icon: Icons.show_chart,
              title: 'Attendance Trend',
            ),
            const SizedBox(height: 12),
            _AttendanceSparkline(animation: _lineAnimation),
            const SizedBox(height: 24),

            // ── Confidence meter
            _ConfidenceMeter(confidence: 0.82),
            const SizedBox(height: 24),

            // ── Teacher override
            _TeacherOverrideCard(
              isOn: _teacherOverrideOn,
              onToggle: (v) => setState(() => _teacherOverrideOn = v),
              controller: _correctionController,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student Header Card ─────────────────────────────────────────────────────

class _StudentHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left accent bar
          Container(width: 4, color: AppColors.primary),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Text(
                'AB',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Amina B.',
                          style: AppTextStyles.headlineLgMobile.copyWith(
                            color: AppColors.inkText,
                          ),
                        ),
                      ),
                      // Risk badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.riskHigh.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.riskHigh),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 14,
                              color: AppColors.riskHigh,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'HIGH RISK',
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.riskHigh,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class 5-A  •  ID: 4920',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.inkText),
        ),
      ],
    );
  }
}

// ─── Reasoning Timeline ───────────────────────────────────────────────────────

class _ReasoningTimeline extends StatelessWidget {
  final List<_TrailStep> _steps = const [
    _TrailStep(
      number: '1',
      title: 'Pattern Analysis',
      body:
          'Attendance dropped 20% over the last 4 weeks. Missing predominantly Tuesday and Thursday morning sessions.',
      highlight: '20%',
      highlightColor: AppColors.riskHigh,
    ),
    _TrailStep(
      number: '2',
      title: 'Contextual Cross-Reference',
      body:
          'Cross-referencing with peer data — 3 other students in the same neighbourhood show a correlated dip, suggesting a systemic, not individual, cause.',
      highlight: '3 other students',
      highlightColor: AppColors.secondary,
    ),
    _TrailStep(
      number: '3',
      title: 'Confidence Assessment',
      body:
          'Based on the pattern and contextual factors, confidence in financial strain as root cause is 82%. Teacher input can refine this score.',
      highlight: '82%',
      highlightColor: AppColors.tertiary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: 1,
                  color: AppColors.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Steps
          Expanded(
            child: Column(
              children: _steps.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _TimelineStep(step: step),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailStep {
  const _TrailStep({
    required this.number,
    required this.title,
    required this.body,
    this.highlight,
    this.highlightColor,
  });
  final String number;
  final String title;
  final String body;
  final String? highlight;
  final Color? highlightColor;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step});
  final _TrailStep step;

  @override
  Widget build(BuildContext context) {
    final bodyParts = step.highlight != null
        ? step.body.split(step.highlight!)
        : [step.body];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot indicator
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 3, right: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.number}. ${step.title}',
                style: AppTextStyles.dataMono.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    children: step.highlight != null && bodyParts.length == 2
                        ? [
                            TextSpan(text: bodyParts[0]),
                            TextSpan(
                              text: step.highlight,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: step.highlightColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: bodyParts[1]),
                          ]
                        : [TextSpan(text: step.body)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Attendance Sparkline ────────────────────────────────────────────────────

class _AttendanceSparkline extends StatelessWidget {
  const _AttendanceSparkline({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _SparklinePainter(
              data: _attendanceData,
              progress: animation.value,
              lineColor: AppColors.primary,
              fillColor: AppColors.primary.withValues(alpha: 0.08),
              dotColor: AppColors.riskHigh,
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.data,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
  });

  final List<double> data;
  final double progress;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final points = List.generate(data.length, (i) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      return Offset(x, y);
    });

    // Number of points to draw based on animation progress
    final drawCount = (progress * (points.length - 1)).clamp(0.0, points.length - 1.0);
    final fullCount = drawCount.floor();
    final partial = drawCount - fullCount;

    // Build visible path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i <= fullCount; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (fullCount < points.length - 1 && partial > 0) {
      final p1 = points[fullCount];
      final p2 = points[fullCount + 1];
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * partial,
        p1.dy + (p2.dy - p1.dy) * partial,
      );
    }

    // Fill under line
    final fillPath = Path.from(path)
      ..lineTo(
        fullCount < points.length - 1
            ? points[fullCount].dx + (points[fullCount + 1].dx - points[fullCount].dx) * partial
            : points.last.dx,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    for (var i = 0; i <= fullCount; i++) {
      canvas.drawCircle(points[i], 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.progress != progress || old.data != data;
}

// ─── Confidence Meter ────────────────────────────────────────────────────────

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inverseOnSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.riskMedium.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Confidence: ${(confidence * 100).round()}%',
                  style: AppTextStyles.dataMono.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: AppColors.surfaceDim,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidence > 0.75 ? AppColors.riskHigh : AppColors.riskMedium,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Teacher Override Card ───────────────────────────────────────────────────

class _TeacherOverrideCard extends StatelessWidget {
  const _TeacherOverrideCard({
    required this.isOn,
    required this.onToggle,
    required this.controller,
  });

  final bool isOn;
  final ValueChanged<bool> onToggle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sandBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ustaad's Gut-Check",
                  style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 18,
                    color: AppColors.inkText,
                  ),
                ),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Is the AI missing something? Add your observation to refine future recommendations.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g., Amina mentioned her father was unwell last week...',
                filled: true,
                fillColor: AppColors.surfaceBright,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.inkText),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.onSurface,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: AppTextStyles.labelCaps,
                ),
                child: const Text('Save Note'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


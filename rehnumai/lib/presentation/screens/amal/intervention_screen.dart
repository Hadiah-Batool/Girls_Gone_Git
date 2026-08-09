import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/student_model.dart';
import '../../widgets/app_top_bar.dart';

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key});

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  final TextEditingController _gutCheckController = TextEditingController();
  bool _messageSent = false;
  Student? _selectedStudent;

  @override
  void dispose() {
    _gutCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final students = appState.students;

    if (_selectedStudent == null && students.isNotEmpty) {
      _selectedStudent = students.first;
    }
    if (_selectedStudent != null &&
        !students.any((s) => s.id == _selectedStudent!.id)) {
      _selectedStudent = students.isNotEmpty ? students.first : null;
    }

    final bg = AppColors.getBg(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Student Selector ─────────────────────────────────────────
            _StudentSelectorCard(
              students: students,
              selectedStudent: _selectedStudent,
              onChanged: (student) {
                setState(() {
                  _selectedStudent = student;
                  _messageSent = false;
                });
              },
            ),
            const SizedBox(height: 16),

            if (students.isEmpty)
              _EmptyState()
            else ...[
              // ── Context header
              _ContextHeader(student: _selectedStudent),
              const SizedBox(height: 20),

              // ── AI Diagnosis Banner
              _DiagnosisBanner(student: _selectedStudent),
              const SizedBox(height: 20),

              // ── Draft parent message card
              _ParentMessageCard(
                student: _selectedStudent,
                isSent: _messageSent,
                onSend: () => setState(() => _messageSent = true),
              ),
              const SizedBox(height: 12),

              // ── Escalate
              _ActionListTile(
                icon: Icons.supervisor_account,
                iconBg: AppColors.secondaryContainer,
                iconColor: AppColors.onSecondaryContainer,
                title: 'Escalate to Counselor',
                subtitle: 'Request a formal financial review',
              ),
              const SizedBox(height: 12),

              // ── Home visit
              _ActionListTile(
                icon: Icons.home_work,
                iconBg: AppColors.isDark(context) ? const Color(0xFF382F28) : AppColors.surfaceContainerHigh,
                iconColor: AppColors.getTextSecondary(context),
                title: 'Schedule Home Visit',
                subtitle: 'Check-in personally with the family',
              ),
              const SizedBox(height: 24),

              // ── Gut-check
              _GutCheckCard(controller: _gutCheckController),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              'No students found.',
              style: AppTextStyles.headlineMd.copyWith(fontSize: 16, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan a sheet or reset sample data first.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => appState.resetDummyData(),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Load Sample Students'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student Selector Card ────────────────────────────────────────────────────

class _StudentSelectorCard extends StatelessWidget {
  const _StudentSelectorCard({
    required this.students,
    required this.selectedStudent,
    required this.onChanged,
  });
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<Student?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: students.isEmpty
                ? Text(
                    'No students — scan a sheet first',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  )
                : DropdownButton<Student>(
                    value: selectedStudent,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: cardBg,
                    items: students
                        .map(
                          (s) => DropdownMenuItem<Student>(
                            value: s,
                            child: Text(
                              '${s.name} · ${s.grade}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Context Header ───────────────────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({required this.student});
  final Student? student;

  @override
  Widget build(BuildContext context) {
    final name = student?.name ?? 'Student';
    final grade = student?.grade ?? '';
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervention Hub',
          style: AppTextStyles.headlineMd.copyWith(color: textPrimary),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMd.copyWith(
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: 'Recommended actions for '),
              TextSpan(
                text: name,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (grade.isNotEmpty) TextSpan(text: ' ($grade)'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── AI Diagnosis Banner ──────────────────────────────────────────────────────

class _DiagnosisBanner extends StatelessWidget {
  const _DiagnosisBanner({required this.student});
  final Student? student;

  String _getDiagnosis(Student? s) {
    if (s == null) return 'No student selected.';
    if (s.hasFeeOverdue && s.attendanceRate < 70) {
      return 'Pattern of absences coinciding with fee overdue. High probability of financial strain.';
    } else if (s.hasFeeOverdue) {
      return 'Fee payments are overdue. Risk of dropout due to financial difficulty.';
    } else if (s.attendanceRate < 60) {
      return 'Critically low attendance rate (${s.attendanceRate.toStringAsFixed(0)}%). Immediate action required.';
    } else if (s.attendanceRate < 80) {
      return 'Below-average attendance (${s.attendanceRate.toStringAsFixed(0)}%). Monitor closely and follow up.';
    } else if (s.latestScore != null && s.latestScore! < 50) {
      return 'Latest exam score critically low (${s.latestScore!.toStringAsFixed(0)}%). May need academic support.';
    } else if (s.latestScore != null && s.latestScore! < 65) {
      return 'Below average exam performance (${s.latestScore!.toStringAsFixed(0)}%). Consider extra support sessions.';
    }
    return 'No major risk indicators detected. Continue regular monitoring.';
  }

  @override
  Widget build(BuildContext context) {
    final bannerBg = AppColors.isDark(context) ? const Color(0xFF2A231C) : AppColors.inverseOnSurface;
    final textSecondary = AppColors.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.riskMedium, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI DIAGNOSIS',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDiagnosis(student),
                  style: AppTextStyles.bodySm.copyWith(
                    color: textSecondary,
                    height: 1.5,
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

// ─── Parent Message Card ──────────────────────────────────────────────────────

class _ParentMessageCard extends StatefulWidget {
  const _ParentMessageCard({
    required this.student,
    required this.isSent,
    required this.onSend,
  });
  final Student? student;
  final bool isSent;
  final VoidCallback onSend;

  @override
  State<_ParentMessageCard> createState() => _ParentMessageCardState();
}

class _ParentMessageCardState extends State<_ParentMessageCard> {
  bool _isEditing = false;
  late TextEditingController _editController;

  String _buildMessage(Student? s) {
    final name = s?.name ?? 'the student';
    return 'Assalam-o-Alaikum, I am $name\'s class teacher. I noticed $name has missed a few sessions recently. We value their presence and want to support them. If there\'s any difficulty — academic or otherwise — please know the school is here to help. Let\'s connect soon.';
  }

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: _buildMessage(widget.student));
  }

  @override
  void didUpdateWidget(_ParentMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student?.id != widget.student?.id) {
      _editController.text = _buildMessage(widget.student);
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final bubbleBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                color: AppColors.primary.withValues(alpha: 0.05),
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
                    const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Draft Parent Message',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 18,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Recommended',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: _isEditing
                      ? TextField(
                          controller: _editController,
                          maxLines: 5,
                          style: AppTextStyles.bodySm.copyWith(
                            color: textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          widget.isSent
                              ? '✅ Message sent to ${widget.student?.name ?? 'student'}\'s parent'
                              : _editController.text,
                          style: AppTextStyles.bodySm.copyWith(
                            color: widget.isSent
                                ? AppColors.tertiary
                                : textSecondary,
                            height: 1.6,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.isSent) ...[
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          size: 20,
                          color: textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _isEditing = !_isEditing);
                        },
                        tooltip: _isEditing ? 'Done editing' : 'Edit message',
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: widget.onSend,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Approve & Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: AppTextStyles.labelCaps,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ] else
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Send Another',
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
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

// ─── Action List Tile ─────────────────────────────────────────────────────────

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gut-Check Card ───────────────────────────────────────────────────────────

class _GutCheckCard extends StatelessWidget {
  const _GutCheckCard({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final sandBg = AppColors.getSandBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final inputBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sandBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Ustaad's Gut-Check",
                style: AppTextStyles.headlineMd.copyWith(
                  fontSize: 18,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Is the AI missing something? Add your personal observation to improve future recommendations.',
            style: AppTextStyles.bodySm.copyWith(
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            style: AppTextStyles.bodyMd.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., Student mentioned their parent was unwell...',
              hintStyle: TextStyle(color: textSecondary),
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
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Observation saved!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  controller.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: AppTextStyles.labelCaps,
              ),
              child: const Text('Save Note'),
            ),
          ),
        ],
      ),
    );
  }
}

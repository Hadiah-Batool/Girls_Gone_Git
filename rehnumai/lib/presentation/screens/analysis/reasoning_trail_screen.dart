// lib/presentation/screens/analysis/reasoning_trail_screen.dart
//
// Live reasoning trail UI — executes the multi-agent LLM analysis chain
// (Pattern Analyst, Root-Cause Reasoner, Self-Critique Agent, Intervention Planner)
// using the OpenRouter/Gemini API for a selected student or scanned sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/gemini_service.dart';
import '../../../data/models/student_model.dart';
import '../../../domain/agents/agent_orchestrator.dart';
import '../../../domain/agents/agent_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/rehnumai_drawer.dart';

class ReasoningTrailScreen extends StatefulWidget {
  final String? scannedText;
  final Student? student;
  final bool autoRun;

  const ReasoningTrailScreen({
    super.key,
    this.scannedText,
    this.student,
    this.autoRun = false,
  });

  @override
  State<ReasoningTrailScreen> createState() => _ReasoningTrailScreenState();
}

class _ReasoningTrailScreenState extends State<ReasoningTrailScreen> {
  final List<AgentReasoningEvent> _events = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _overrideController = TextEditingController();

  bool _isRunning = false;
  bool _isComplete = false;
  bool _isStructuring = false;
  bool _teacherOverrideOn = false;
  String? _errorMessage;
  Student? _currentStudent;
  Map<String, dynamic>? _finalSummary;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _currentStudent = widget.student;
    }
    if (widget.autoRun || widget.scannedText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStudent == null) {
          final appState = Provider.of<AppState>(context, listen: false);
          if (appState.students.isNotEmpty) {
            _currentStudent = appState.students.first;
          }
        }
        _runLiveAnalysis();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  Future<void> _runLiveAnalysis() async {
    setState(() {
      _isStructuring = widget.scannedText != null && widget.scannedText!.trim().isNotEmpty;
      _errorMessage = null;
      _events.clear();
      _isComplete = false;
      _isRunning = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    Student? targetStudent = _currentStudent ?? (appState.students.isNotEmpty ? appState.students.first : null);

    if (widget.scannedText != null && widget.scannedText!.trim().isNotEmpty) {
      try {
        targetStudent = await _structureOcrText(widget.scannedText!);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isStructuring = false;
          _isRunning = false;
          _errorMessage = 'OCR Structuring Error: $e';
        });
        return;
      }
    }

    if (targetStudent == null) {
      if (!mounted) return;
      setState(() {
        _isStructuring = false;
        _isRunning = false;
        _errorMessage = 'No student available for analysis. Please scan a sheet or add student data.';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentStudent = targetStudent;
      _isStructuring = false;
    });

    try {
      final orchestrator = AgentOrchestrator();
      await for (final event in orchestrator.analyzeStudentRisk(targetStudent)) {
        if (!mounted) return;

        setState(() {
          _events.add(event);

          if (event.step == AgentStep.complete) {
            _isComplete = true;
            _isRunning = false;
            _finalSummary = event.outputJson;
          }
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _isStructuring = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<Student> _structureOcrText(String ocrText) async {
    const systemPrompt = '''
You are a data extraction specialist. Extract structured student data from raw OCR text into JSON:
{
  "id": "stu_scan_001",
  "name": "<student name or 'Scanned Student'>",
  "grade": "<grade or '7-B'>",
  "attendance": [{"date": "2026-07-01", "is_present": true}],
  "fees": [{"due_date": "2026-07-01", "paid_date": null, "amount_due": 2500.0, "amount_paid": 0.0}],
  "exam_scores": [{"date": "2026-07-01", "score": 55.0}],
  "teacher_notes": []
}
''';
    final response = await OpenRouterService.instance.chatWithFallback(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': ocrText},
      ],
      temperature: 0.2,
      maxTokens: 1000,
    );
    return _parseStudentFromJson(response);
  }

  Student _parseStudentFromJson(Map<String, dynamic> json) {
    final attendanceList = <AttendanceRecord>[];
    if (json['attendance'] is List) {
      for (final a in json['attendance'] as List) {
        try {
          attendanceList.add(AttendanceRecord(
            date: DateTime.parse(a['date'] as String),
            isPresent: a['is_present'] as bool? ?? true,
          ));
        } catch (_) {}
      }
    }
    final feeList = <FeeRecord>[];
    if (json['fees'] is List) {
      for (final f in json['fees'] as List) {
        try {
          feeList.add(FeeRecord(
            dueDate: DateTime.parse(f['due_date'] as String),
            paidDate: f['paid_date'] != null ? DateTime.parse(f['paid_date'] as String) : null,
            amountDue: (f['amount_due'] as num?)?.toDouble() ?? 2500.0,
            amountPaid: (f['amount_paid'] as num?)?.toDouble() ?? 0.0,
          ));
        } catch (_) {}
      }
    }
    final scores = <DateTime, double>{};
    if (json['exam_scores'] is List) {
      for (final s in json['exam_scores'] as List) {
        try {
          scores[DateTime.parse(s['date'] as String)] = (s['score'] as num?)?.toDouble() ?? 50.0;
        } catch (_) {}
      }
    }

    return Student(
      id: json['id'] as String? ?? 'stu_scan_001',
      name: json['name'] as String? ?? 'Scanned Student',
      grade: json['grade'] as String? ?? '7-B',
      attendance: attendanceList,
      fees: feeList,
      examScores: scores,
      teacherNotes: const [],
    );
  }

  void _showPerformanceCharts(BuildContext context, Student student) {
    final bg = AppColors.getBg(context);
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student.name}\'s Analytics',
                          style: AppTextStyles.headlineMd.copyWith(color: textPrimary),
                        ),
                        Text(
                          'Academic Scores & Attendance Trends',
                          style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textPrimary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attendance Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance Rate',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                        ),
                        Text(
                          '${student.attendanceRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: student.attendanceRate >= 80
                                ? AppColors.success
                                : student.attendanceRate >= 60
                                    ? AppColors.riskMedium
                                    : AppColors.riskHigh,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (student.attendanceRate / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: borderColor,
                        color: student.attendanceRate >= 80
                            ? AppColors.success
                            : student.attendanceRate >= 60
                                ? AppColors.riskMedium
                                : AppColors.riskHigh,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Logs: ${student.attendance.length} days | Present: ${student.attendance.where((a) => a.isPresent).length} days',
                      style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Exam Performance Graph Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Score Progression',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                    ),
                    const SizedBox(height: 14),
                    if (student.examScores.isEmpty)
                      Text('No exam scores recorded yet.', style: TextStyle(color: textSecondary))
                    else
                      ...student.examScores.entries.map((entry) {
                        final dateStr = entry.key.toIso8601String().split('T').first;
                        final score = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateStr, style: AppTextStyles.bodySm.copyWith(color: textPrimary)),
                                  Text(
                                    '${score.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: score >= 75
                                          ? AppColors.success
                                          : score >= 50
                                              ? AppColors.riskMedium
                                              : AppColors.riskHigh,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (score / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: borderColor,
                                  color: score >= 75
                                      ? AppColors.success
                                      : score >= 50
                                          ? AppColors.riskMedium
                                          : AppColors.riskHigh,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Risk Signals Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Factor Risk Signals',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildRiskRow(context, 'Financial Strain', student.hasFeeOverdue ? 'Overdue Fee' : 'Clear', student.hasFeeOverdue),
                    const SizedBox(height: 8),
                    _buildRiskRow(context, 'Attendance Drop', student.attendanceRate < 75 ? 'Low Attendance' : 'Stable', student.attendanceRate < 75),
                    const SizedBox(height: 8),
                    _buildRiskRow(context, 'Academic Struggle', (student.latestScore ?? 100) < 60 ? 'Declining Scores' : 'On Track', (student.latestScore ?? 100) < 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskRow(BuildContext context, String title, String status, bool isRisk) {
    final textPrimary = AppColors.getTextPrimary(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyMd.copyWith(color: textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isRisk ? AppColors.riskHigh.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isRisk ? AppColors.riskHigh : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBg(context);
    return Scaffold(
      backgroundColor: bg,
      appBar: const AppTopBar(),
      drawer: const RehnumaiDrawer(),
      body: Column(
        children: [
          if (_isRunning || _isStructuring)
            const LinearProgressIndicator(
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Student Picker (shown when opened as a tab without a pre-set student)
                  if (widget.student == null && widget.scannedText == null)
                    _StudentPickerForAnalysis(
                      selectedStudent: _currentStudent,
                      onChanged: (s) {
                        setState(() {
                          _currentStudent = s;
                          _events.clear();
                          _isComplete = false;
                          _finalSummary = null;
                          _errorMessage = null;
                        });
                      },
                    ),
                  if (_currentStudent != null) ...[
                    _StudentHeaderCard(
                      student: _currentStudent!,
                      isRunning: _isRunning,
                      onRunAnalysis: _runLiveAnalysis,
                      onViewResults: () => _showPerformanceCharts(context, _currentStudent!),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reasoning Trail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      if (!_isRunning && !_isStructuring)
                        TextButton.icon(
                          onPressed: _runLiveAnalysis,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Re-run'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    _buildErrorCard()
                  else if (_isStructuring)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('Structuring scanned sheet text with Gemini AI...')),
                    )
                  else if (_events.isEmpty && !_isRunning)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Tap "Run AI Analysis" above to analyze ${_currentStudent?.name}\'s risk profile live.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._events.map((e) => _AgentEventCard(event: e)),
                  const SizedBox(height: 20),
                  _TeacherOverrideCard(
                    isOn: _teacherOverrideOn,
                    onToggle: (v) => setState(() => _teacherOverrideOn = v),
                    controller: _overrideController,
                  ),
                ],
              ),
            ),
          ),
          if (_isComplete && _finalSummary != null) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'LLM Execution Error',
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onErrorContainer),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _runLiveAnalysis,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final message = _finalSummary?['whatsapp_message'] as String? ?? 'No message.';
    final rootCause = _finalSummary?['root_cause'] as String? ?? 'Financial Strain';
    final confidence = _finalSummary?['confidence'] as String? ?? 'High';

    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  rootCause,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer),
                ),
                backgroundColor: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context) ? const Color(0xFF382F28) : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Confidence: $confidence',
                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Suggested Intervention Message',
            style: AppTextStyles.labelCaps.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.isDark(context) ? const Color(0xFF26211D) : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(color: textPrimary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied to clipboard')),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16, color: textPrimary),
                  label: Text('Copy', style: TextStyle(color: textPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(text: message));
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentHeaderCard extends StatelessWidget {
  final Student student;
  final bool isRunning;
  final VoidCallback onRunAnalysis;
  final VoidCallback onViewResults;

  const _StudentHeaderCard({
    required this.student,
    required this.isRunning,
    required this.onRunAnalysis,
    required this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  student.name.isNotEmpty ? student.name[0] : 'S',
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grade: ${student.grade}  •  Attendance: ${student.attendanceRate.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRunning ? null : onRunAnalysis,
                  icon: isRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(isRunning ? 'Analyzing...' : 'Run AI Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewResults,
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text('View Results'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentEventCard extends StatelessWidget {
  final AgentReasoningEvent event;

  const _AgentEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.isDark(context) ? const Color(0xFF382F28) : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(event.step.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.agentName,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    if (event.isDone)
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.statusMessage,
                  style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherOverrideCard extends StatelessWidget {
  final bool isOn;
  final ValueChanged<bool> onToggle;
  final TextEditingController controller;

  const _TeacherOverrideCard({
    required this.isOn,
    required this.onToggle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teacher Override',
                style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              style: AppTextStyles.bodyMd.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Add teacher context or correction note...',
                hintStyle: TextStyle(color: AppColors.getTextSecondary(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Student Picker for Standalone View Tab ───────────────────────────────────

class _StudentPickerForAnalysis extends StatelessWidget {
  const _StudentPickerForAnalysis({
    required this.selectedStudent,
    required this.onChanged,
  });
  final Student? selectedStudent;
  final ValueChanged<Student?> onChanged;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final students = appState.students;
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Select a Student to Analyze',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: students.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No students available. Scan a sheet or reset sample data.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => appState.resetDummyData(),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Load Sample Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : DropdownButton<Student>(
                  value: selectedStudent != null &&
                          students.any((s) => s.id == selectedStudent!.id)
                      ? selectedStudent
                      : students.first,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: cardBg,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
        const SizedBox(height: 16),
      ],
    );
  }
}

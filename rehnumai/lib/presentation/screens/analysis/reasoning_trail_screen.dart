// lib/presentation/screens/analysis/reasoning_trail_screen.dart
//
// Live reasoning trail UI — executes the multi-agent LLM analysis chain
// (Pattern Analyst, Root-Cause Reasoner, Self-Critique Agent, Intervention Planner)
// using the OpenRouter/Gemini API for a selected student or scanned sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/gemini_service.dart';
import '../../../data/models/mock_students.dart';
import '../../../data/models/student_model.dart';
import '../../../domain/agents/agent_orchestrator.dart';
import '../../../domain/agents/agent_state.dart';
import '../../widgets/app_top_bar.dart';

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
    _currentStudent = widget.student ?? mockStudents.first;
    if (widget.autoRun || widget.scannedText != null) {
      _runLiveAnalysis();
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

    Student targetStudent = _currentStudent ?? mockStudents.first;

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
      attendance: attendanceList.isNotEmpty ? attendanceList : mockStudents.first.attendance,
      fees: feeList.isNotEmpty ? feeList : mockStudents.first.fees,
      examScores: scores.isNotEmpty ? scores : mockStudents.first.examScores,
      teacherNotes: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
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
                  if (_currentStudent != null) ...[
                    _StudentHeaderCard(
                      student: _currentStudent!,
                      isRunning: _isRunning,
                      onRunAnalysis: _runLiveAnalysis,
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reasoning Trail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Confidence: $confidence',
                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Suggested Intervention Message',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
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
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outline),
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

  const _StudentHeaderCard({
    required this.student,
    required this.isRunning,
    required this.onRunAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
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
                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grade: ${student.grade}  •  Attendance: ${student.attendanceRate.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isRunning ? null : onRunAnalysis,
              icon: isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(isRunning ? 'Running LLM Analysis...' : 'Run AI Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
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
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    if (event.isDone)
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.statusMessage,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teacher Override',
                style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
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
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: const InputDecoration(
                hintText: 'Add teacher context or correction note...',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

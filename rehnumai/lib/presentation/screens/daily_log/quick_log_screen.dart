// lib/presentation/screens/daily_log/quick_log_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/log_entry_model.dart';
import '../../../data/models/student_model.dart';
import '../../widgets/app_top_bar.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  final _formKey = GlobalKey<FormState>();
  int _activeTabIndex = 0; // 0 = Add Log, 1 = View All Logs

  String? _selectedStudentId;
  LogType _selectedLogType = LogType.attendance;

  final _noteController = TextEditingController();
  final _scoreController = TextEditingController();
  final _amountController = TextEditingController();
  final _behaviourController = TextEditingController();
  bool _isPresent = true;
  bool _isFeePaid = true;

  @override
  void dispose() {
    _noteController.dispose();
    _scoreController.dispose();
    _amountController.dispose();
    _behaviourController.dispose();
    super.dispose();
  }

  void _submitLog() {
    final appState = Provider.of<AppState>(context, listen: false);
    final students = appState.students;

    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    final student = students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => students.first,
    );

    final now = DateTime.now();
    String detailsStr = '';
    String? valueStr;

    if (_selectedLogType == LogType.attendance) {
      valueStr = _isPresent ? 'Present' : 'Absent';
      detailsStr = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : (_isPresent ? 'Marked present' : 'Marked absent');
    } else if (_selectedLogType == LogType.marks) {
      final scoreVal = double.tryParse(_scoreController.text.trim()) ?? 75.0;
      valueStr = '${scoreVal.toStringAsFixed(1)}%';
      detailsStr = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'Exam score recorded';
    } else if (_selectedLogType == LogType.feeStatus) {
      valueStr = _isFeePaid ? 'Paid' : 'Overdue';
      final amt = _amountController.text.trim();
      detailsStr = amt.isNotEmpty ? 'Amount: Rs. $amt' : (_isFeePaid ? 'Fee paid in full' : 'Fee payment pending');
    } else if (_selectedLogType == LogType.behaviour) {
      detailsStr = _behaviourController.text.trim().isNotEmpty
          ? _behaviourController.text.trim()
          : 'Behaviour observation logged';
    } else {
      detailsStr = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'Teacher soft note logged';
    }

    final logEntry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: student.id,
      studentName: student.name,
      type: _selectedLogType,
      timestamp: now,
      details: detailsStr,
      value: valueStr,
    );

    appState.addLogEntry(logEntry);

    // Also update student entity in repository for backwards compatibility
    final updatedAttendance = List<AttendanceRecord>.from(student.attendance);
    final updatedScores = Map<DateTime, double>.from(student.examScores);
    final updatedNotes = List<TaggedNote>.from(student.teacherNotes);

    if (_selectedLogType == LogType.attendance) {
      updatedAttendance.insert(
        0,
        AttendanceRecord(date: now, isPresent: _isPresent, note: detailsStr),
      );
    } else if (_selectedLogType == LogType.marks) {
      final scoreVal = double.tryParse(_scoreController.text.trim()) ?? 75.0;
      updatedScores[now] = scoreVal;
    } else if (_selectedLogType == LogType.notes || _selectedLogType == LogType.behaviour) {
      updatedNotes.insert(
        0,
        TaggedNote(date: now, authorTag: 'class_teacher', content: detailsStr),
      );
    }

    final updatedStudent = Student(
      id: student.id,
      name: student.name,
      grade: student.grade,
      attendance: updatedAttendance,
      fees: student.fees,
      examScores: updatedScores,
      teacherNotes: updatedNotes,
    );

    appState.addStudent(updatedStudent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Log recorded for ${student.name}!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _noteController.clear();
    _scoreController.clear();
    _amountController.clear();
    _behaviourController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final students = appState.students;
    final logs = appState.logs;

    final bg = AppColors.getBg(context);
    final cardBg = AppColors.getCardBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorderColor(context);

    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row (Fixed top-right overflow) ──────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Daily Logs',
                        style: AppTextStyles.headlineMd.copyWith(color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record & review student daily logs',
                        style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tab Switcher: Add Log vs View All Logs ─────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Add Log',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _activeTabIndex == 0 ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'View All Logs (${logs.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _activeTabIndex == 1 ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Tab 0: Add New Log Form ────────────────────────────────────
            if (_activeTabIndex == 0) ...[
              if (students.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context) ? const Color(0xFF332A22) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.isDark(context) ? Colors.amber.shade700 : Colors.amber.shade300),
                  ),
                  child: Text(
                    'No students available. Scan a sheet or reset sample data from menu.',
                    style: TextStyle(color: textPrimary),
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Student', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStudentId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: cardBg,
                        ),
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        dropdownColor: cardBg,
                        hint: Text(
                          'Choose a student...',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                        items: students
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.name} (${s.grade})',
                                    style: TextStyle(color: textPrimary, fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedStudentId = val),
                      ),
                      const SizedBox(height: 20),

                      // ── 5 Log Options Dropdown ─────────────────────────
                      Text('Log Category (5 Options)', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LogType>(
                        initialValue: _selectedLogType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: cardBg,
                        ),
                        style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                        dropdownColor: cardBg,
                        items: LogType.values
                            .map(
                              (type) => DropdownMenuItem<LogType>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(type.icon, color: type.color, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      type.label,
                                      style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLogType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Dynamic Input Fields Based on Selection ──────────
                      if (_selectedLogType == LogType.attendance) ...[
                        SwitchListTile(
                          title: Text('Student Present', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                          subtitle: Text('Toggle OFF if student was absent today', style: TextStyle(color: textSecondary)),
                          value: _isPresent,
                          onChanged: (v) => setState(() => _isPresent = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_selectedLogType == LogType.marks) ...[
                        TextFormField(
                          controller: _scoreController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Exam Score (%)',
                            labelStyle: TextStyle(color: textSecondary),
                            hintText: 'e.g. 78.5',
                            hintStyle: TextStyle(color: textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: cardBg,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedLogType == LogType.feeStatus) ...[
                        SwitchListTile(
                          title: Text('Fee Paid', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                          subtitle: Text('Toggle OFF if fee payment is overdue', style: TextStyle(color: textSecondary)),
                          value: _isFeePaid,
                          onChanged: (v) => setState(() => _isFeePaid = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Amount (Optional)',
                            labelStyle: TextStyle(color: textSecondary),
                            hintText: 'e.g. 2500',
                            hintStyle: TextStyle(color: textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: cardBg,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedLogType == LogType.behaviour) ...[
                        TextFormField(
                          controller: _behaviourController,
                          maxLines: 2,
                          style: TextStyle(color: textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Behaviour Observation',
                            labelStyle: TextStyle(color: textSecondary),
                            hintText: 'e.g. Attentive in class, helped peers...',
                            hintStyle: TextStyle(color: textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: cardBg,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // General Note Input
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Additional Notes / Comments',
                          labelStyle: TextStyle(color: textSecondary),
                          hintText: 'e.g. Student reported feeling unwell...',
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: cardBg,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitLog,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Observation Log'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // ── Tab 1: View All Logs Added ────────────────────────────────
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded, size: 48, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          'No logs recorded yet.',
                          style: AppTextStyles.headlineMd.copyWith(fontSize: 16, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Switch to "Add Log" to enter observations.',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final log = logs[index];
                    final dtStr = '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: log.type.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(log.type.icon, color: log.type.color, size: 22),
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
                                      log.studentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      dtStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: log.type.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.type.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: log.type.color,
                                        ),
                                      ),
                                    ),
                                    if (log.value != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        log.value!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (log.details.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    log.details,
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/presentation/screens/daily_log/quick_log_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/student_model.dart';
import '../../widgets/app_top_bar.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  String _logType = 'attendance'; // attendance, score, note, fee
  final _noteController = TextEditingController();
  final _scoreController = TextEditingController();
  bool _isPresent = false;

  @override
  void dispose() {
    _noteController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _submitLog() {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final student = appState.students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => appState.students.first,
    );

    final now = DateTime.now();

    final updatedAttendance = List<AttendanceRecord>.from(student.attendance);
    final updatedScores = Map<DateTime, double>.from(student.examScores);
    final updatedNotes = List<TaggedNote>.from(student.teacherNotes);

    if (_logType == 'attendance') {
      updatedAttendance.insert(
        0,
        AttendanceRecord(
          date: now,
          isPresent: _isPresent,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        ),
      );
    } else if (_logType == 'score') {
      final scoreVal = double.tryParse(_scoreController.text.trim()) ?? 75.0;
      updatedScores[now] = scoreVal;
    } else if (_logType == 'note') {
      updatedNotes.insert(
        0,
        TaggedNote(
          date: now,
          authorTag: 'class_teacher',
          content: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Observation logged',
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final students = appState.students;

    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class Daily Log', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 2),
                      Text('Log student observations, marks, or absences', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (students.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Text('No students available. Scan a sheet or reset dummy data from settings.'),
                )
              else ...[
                Text('Select Student', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStudentId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Choose a student...'),
                  items: students
                      .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.grade})')))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                ),
                const SizedBox(height: 20),

                Text('Log Type', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'attendance', label: Text('Absence'), icon: Icon(Icons.event_busy)),
                    ButtonSegment(value: 'score', label: Text('Exam Mark'), icon: Icon(Icons.assignment_turned_in)),
                    ButtonSegment(value: 'note', label: Text('Note'), icon: Icon(Icons.note_alt)),
                  ],
                  selected: {_logType},
                  onSelectionChanged: (val) => setState(() => _logType = val.first),
                ),
                const SizedBox(height: 20),

                if (_logType == 'attendance') ...[
                  SwitchListTile(
                    title: const Text('Student is Present'),
                    subtitle: const Text('Toggle OFF if student was absent today'),
                    value: _isPresent,
                    onChanged: (v) => setState(() => _isPresent = v),
                    activeThumbColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                ],

                if (_logType == 'score') ...[
                  TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Exam Score (%)',
                      hintText: 'e.g. 68.5',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Teacher Soft Note / Reason',
                    hintText: 'e.g. Student reported headache; missed test...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}

// lib/data/models/log_entry_model.dart
import 'package:flutter/material.dart';

enum LogType {
  attendance,
  marks,
  feeStatus,
  behaviour,
  notes,
}

extension LogTypeExtension on LogType {
  String get label => switch (this) {
        LogType.attendance => 'Attendance',
        LogType.marks => 'Marks / Exam',
        LogType.feeStatus => 'Fee Status',
        LogType.behaviour => 'Behaviour',
        LogType.notes => 'Notes',
      };

  IconData get icon => switch (this) {
        LogType.attendance => Icons.event_busy_rounded,
        LogType.marks => Icons.assignment_turned_in_rounded,
        LogType.feeStatus => Icons.payments_rounded,
        LogType.behaviour => Icons.psychology_rounded,
        LogType.notes => Icons.note_alt_rounded,
      };

  Color get color => switch (this) {
        LogType.attendance => const Color(0xFFF26D5B),
        LogType.marks => const Color(0xFF43664D),
        LogType.feeStatus => const Color(0xFF735B0D),
        LogType.behaviour => const Color(0xFF8B7CF6),
        LogType.notes => const Color(0xFFA8372A),
      };
}

class LogEntry {
  final String id;
  final String studentId;
  final String studentName;
  final LogType type;
  final DateTime timestamp;
  final String details;
  final String? value;

  LogEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.timestamp,
    required this.details,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'student_name': studentName,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
        'value': value,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? 'Student',
      type: LogType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LogType.notes,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      details: json['details'] as String? ?? '',
      value: json['value'] as String?,
    );
  }
}

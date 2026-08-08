// lib/data/models/student_model.dart
//
// Pure Dart data models for the Rehnumai multi-agent risk analysis pipeline.
// These classes are intentionally free of Isar annotations – they are used
// exclusively in-memory to feed the OpenRouter LLM chain.

/// A single daily attendance entry for a student.
class AttendanceRecord {
  final DateTime date;
  final bool isPresent;
  final String? note; // Optional teacher note for the day

  const AttendanceRecord({
    required this.date,
    required this.isPresent,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'is_present': isPresent,
        if (note != null) 'note': note,
      };
}

/// A single fee record representing one billing cycle.
class FeeRecord {
  final DateTime dueDate;
  final DateTime? paidDate; // null = not yet paid
  final double amountDue;
  final double amountPaid;

  const FeeRecord({
    required this.dueDate,
    this.paidDate,
    required this.amountDue,
    required this.amountPaid,
  });

  /// Returns true when the fee was not paid by the due date.
  bool get isOverdue =>
      paidDate == null
          ? DateTime.now().isAfter(dueDate)
          : paidDate!.isAfter(dueDate);

  /// Returns the number of days the payment was/is overdue.
  /// Returns 0 if paid on time or not yet due.
  int get overdueDays {
    if (!isOverdue) return 0;
    final resolvedDate = paidDate ?? DateTime.now();
    return resolvedDate.difference(dueDate).inDays;
  }

  Map<String, dynamic> toJson() => {
        'due_date': dueDate.toIso8601String().split('T').first,
        'paid_date': paidDate?.toIso8601String().split('T').first,
        'amount_due': amountDue,
        'amount_paid': amountPaid,
        'is_overdue': isOverdue,
        'overdue_days': overdueDays,
      };
}

/// A soft qualitative note tagged by a teacher or coordinator.
class TaggedNote {
  final DateTime date;
  final String authorTag; // e.g. "class_teacher", "coordinator"
  final String content;

  const TaggedNote({
    required this.date,
    required this.authorTag,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'author_tag': authorTag,
        'content': content,
      };
}

/// The top-level student entity consumed by the agent orchestrator.
///
/// [examScores] maps each exam/test date to a percentage score (0–100).
/// [teacherNotes] are soft qualitative observations from teachers.
class Student {
  final String id;
  final String name;
  final String grade;
  final List<AttendanceRecord> attendance;
  final List<FeeRecord> fees;
  final Map<DateTime, double> examScores; // date → score (0–100)
  final List<TaggedNote> teacherNotes;

  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.attendance,
    required this.fees,
    required this.examScores,
    required this.teacherNotes,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// Attendance rate as a percentage over the full record window.
  double get attendanceRate {
    if (attendance.isEmpty) return 100.0;
    final present = attendance.where((r) => r.isPresent).length;
    return (present / attendance.length) * 100;
  }

  /// Most recent exam score; null if no scores recorded.
  double? get latestScore {
    if (examScores.isEmpty) return null;
    final sorted = examScores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.last.value;
  }

  /// Whether any fee record is currently overdue.
  bool get hasFeeOverdue => fees.any((f) => f.isOverdue);

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Converts the student to a JSON-safe map for embedding in LLM prompts.
  Map<String, dynamic> toJson() {
    // Sort exam scores chronologically for readable prompt context
    final sortedScores = (examScores.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map(
          (e) => {
            'date': e.key.toIso8601String().split('T').first,
            'score': e.value,
          },
        )
        .toList();

    return {
      'id': id,
      'name': name,
      'grade': grade,
      'attendance_rate_pct': double.parse(attendanceRate.toStringAsFixed(1)),
      'has_fee_overdue': hasFeeOverdue,
      'latest_score': latestScore,
      'attendance': attendance.map((r) => r.toJson()).toList(),
      'fees': fees.map((f) => f.toJson()).toList(),
      'exam_scores': sortedScores,
      'teacher_notes': teacherNotes.map((n) => n.toJson()).toList(),
    };
  }
}

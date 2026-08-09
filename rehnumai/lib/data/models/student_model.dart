// lib/data/models/student_model.dart
//
// Pure Dart data models for the Rehnumai multi-agent risk analysis pipeline.

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

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      isPresent: json['is_present'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }
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

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    return FeeRecord(
      dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ?? DateTime.now(),
      paidDate: json['paid_date'] != null ? DateTime.tryParse(json['paid_date'] as String) : null,
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 2500.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }
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

  factory TaggedNote.fromJson(Map<String, dynamic> json) {
    return TaggedNote(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      authorTag: json['author_tag'] as String? ?? 'class_teacher',
      content: json['content'] as String? ?? '',
    );
  }
}

/// The top-level student entity consumed by the agent orchestrator.
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

  Map<String, dynamic> toJson() {
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
      'attendance': attendance.map((r) => r.toJson()).toList(),
      'fees': fees.map((f) => f.toJson()).toList(),
      'exam_scores': sortedScores,
      'teacher_notes': teacherNotes.map((n) => n.toJson()).toList(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final attendanceList = <AttendanceRecord>[];
    if (json['attendance'] is List) {
      for (final a in json['attendance'] as List) {
        try {
          attendanceList.add(AttendanceRecord.fromJson(a as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    final feeList = <FeeRecord>[];
    if (json['fees'] is List) {
      for (final f in json['fees'] as List) {
        try {
          feeList.add(FeeRecord.fromJson(f as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    final scoresMap = <DateTime, double>{};
    if (json['exam_scores'] is List) {
      for (final s in json['exam_scores'] as List) {
        try {
          final dt = DateTime.tryParse(s['date'] as String? ?? '');
          final val = (s['score'] as num?)?.toDouble();
          if (dt != null && val != null) {
            scoresMap[dt] = val;
          }
        } catch (_) {}
      }
    }

    final notesList = <TaggedNote>[];
    if (json['teacher_notes'] is List) {
      for (final n in json['teacher_notes'] as List) {
        try {
          notesList.add(TaggedNote.fromJson(n as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    return Student(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Student',
      grade: json['grade'] as String? ?? 'Grade 8',
      attendance: attendanceList,
      fees: feeList,
      examScores: scoresMap,
      teacherNotes: notesList,
    );
  }
}

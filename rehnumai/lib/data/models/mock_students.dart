// lib/data/models/mock_students.dart
//
// Seeded test dataset with three distinct temporal profiles.
// All event dates are anchored to baseDate = 2026-07-01 so
// delta-t values are deterministic and predictable for agent testing.

import 'student_model.dart';

/// Base anchor date for all mock event timelines.
final _base = DateTime(2026, 7, 1);

/// Helper: offset from base date by [days].
DateTime _d(int days) => _base.add(Duration(days: days));

// ────────────────────────────────────────────────────────────────────────────
// Profile 1 – Amina Khan (Financial Strain)
// Arc: Fee overdue Day 1 → Attendance drop Day 6 → Score drop Day 9
// ────────────────────────────────────────────────────────────────────────────

final aminaKhan = Student(
  id: 'stu_001',
  name: 'Amina Khan',
  grade: '7-B',
  fees: [
    // Fee due on Day 0 – never paid (overdue from Day 1 onwards)
    FeeRecord(
      dueDate: _d(0),
      paidDate: null, // NOT paid
      amountDue: 2500.0,
      amountPaid: 0.0,
    ),
  ],
  attendance: [
    // Days 0–5: Present
    for (int i = 0; i <= 5; i++) AttendanceRecord(date: _d(i), isPresent: true),
    // Days 6–14: Absent (attendance drop begins Day 6, 9 consecutive absences)
    for (int i = 6; i <= 14; i++)
      AttendanceRecord(
        date: _d(i),
        isPresent: false,
        note: i == 6 ? 'No prior notice from family' : null,
      ),
    // Days 15–21: Returns but irregular
    AttendanceRecord(date: _d(15), isPresent: true),
    AttendanceRecord(date: _d(16), isPresent: false),
    AttendanceRecord(date: _d(17), isPresent: true),
    AttendanceRecord(date: _d(18), isPresent: true),
    AttendanceRecord(date: _d(19), isPresent: false),
    AttendanceRecord(date: _d(20), isPresent: true),
    AttendanceRecord(date: _d(21), isPresent: true),
  ],
  examScores: {
    // Strong baseline before financial strain
    _d(-14): 82.0, // 2 weeks before incident
    _d(-7): 79.0,  // 1 week before
    // Score drops on Day 9 (first exam after attendance collapse)
    _d(9): 51.0,
    _d(16): 48.0,
  },
  teacherNotes: [
    TaggedNote(
      date: _d(3),
      authorTag: 'class_teacher',
      content:
          'Amina mentioned at recess that her family had some financial issues '
          'this month. She seemed stressed but did not elaborate.',
    ),
    TaggedNote(
      date: _d(8),
      authorTag: 'coordinator',
      content:
          'Family has not responded to two SMS messages regarding fee overdue. '
          'Father is known to be self-employed (daily wages).',
    ),
    TaggedNote(
      date: _d(12),
      authorTag: 'class_teacher',
      content:
          'Amina came in today briefly, said she has been helping at home. '
          'She looked visibly tired and left early.',
    ),
  ],
);

// ────────────────────────────────────────────────────────────────────────────
// Profile 2 – Tariq Ahmed (Academic Struggle)
// Arc: Score drop Day 1 → Attendance drop Day 7 → Fee paid on time
// ────────────────────────────────────────────────────────────────────────────

final tariqAhmed = Student(
  id: 'stu_002',
  name: 'Tariq Ahmed',
  grade: '8-A',
  fees: [
    // Fee paid two days before due date – no financial stress
    FeeRecord(
      dueDate: _d(14),
      paidDate: _d(12), // paid early
      amountDue: 2500.0,
      amountPaid: 2500.0,
    ),
  ],
  attendance: [
    // Days 0–6: Present (score dropped but still attending)
    for (int i = 0; i <= 6; i++) AttendanceRecord(date: _d(i), isPresent: true),
    // Days 7–13: Starts missing school (avoidance behaviour)
    AttendanceRecord(date: _d(7),  isPresent: false, note: 'No reason given'),
    AttendanceRecord(date: _d(8),  isPresent: true),
    AttendanceRecord(date: _d(9),  isPresent: false),
    AttendanceRecord(date: _d(10), isPresent: false),
    AttendanceRecord(date: _d(11), isPresent: true),
    AttendanceRecord(date: _d(12), isPresent: false),
    AttendanceRecord(date: _d(13), isPresent: false, note: 'Parents called – said "not feeling well"'),
    // Days 14–21: Irregular return
    for (int i = 14; i <= 21; i++)
      AttendanceRecord(date: _d(i), isPresent: i.isEven),
  ],
  examScores: {
    // Previously strong student
    _d(-21): 88.0,
    _d(-14): 84.0,
    _d(-7): 80.0,
    // Sharp drop beginning Day 1
    _d(1): 52.0,
    _d(8): 44.0,  // Missed some classes → worse
    _d(15): 46.0,
  },
  teacherNotes: [
    TaggedNote(
      date: _d(2),
      authorTag: 'maths_teacher',
      content:
          'Tariq failed the surprise quiz today – scored 11/25. He looked '
          'confused during the lesson and did not ask questions. This is unusual '
          'for him; he was one of our top students last term.',
    ),
    TaggedNote(
      date: _d(5),
      authorTag: 'class_teacher',
      content:
          'Tariq submitted his English assignment two days late and it was '
          'incomplete. He said he "forgot" but seemed embarrassed.',
    ),
    TaggedNote(
      date: _d(9),
      authorTag: 'coordinator',
      content:
          'Parents confirmed fee payment is fine. Academic stress seems to be '
          'the primary concern. Recommend a learning support meeting.',
    ),
  ],
);

// ────────────────────────────────────────────────────────────────────────────
// Profile 3 – Bilal Raza (False Positive / Sick Week)
// Arc: 1 bad attendance week (viral illness) – stable historical scores
// ────────────────────────────────────────────────────────────────────────────

final bilalRaza = Student(
  id: 'stu_003',
  name: 'Bilal Raza',
  grade: '7-A',
  fees: [
    // Fee paid on time
    FeeRecord(
      dueDate: _d(7),
      paidDate: _d(7),
      amountDue: 2500.0,
      amountPaid: 2500.0,
    ),
  ],
  attendance: [
    // Days 0–4: Perfect attendance pre-illness
    for (int i = 0; i <= 4; i++) AttendanceRecord(date: _d(i), isPresent: true),
    // Days 5–9: Sick – confirmed by medical certificate
    for (int i = 5; i <= 9; i++)
      AttendanceRecord(
        date: _d(i),
        isPresent: false,
        note: i == 5 ? 'Medical leave – viral fever (certificate submitted)' : null,
      ),
    // Days 10–21: Full recovery – back to perfect attendance
    for (int i = 10; i <= 21; i++)
      AttendanceRecord(date: _d(i), isPresent: true),
  ],
  examScores: {
    // Consistently strong, no academic red flags
    _d(-28): 85.0,
    _d(-21): 87.0,
    _d(-14): 83.0,
    _d(-7): 89.0,
    // Missed exam on Day 6 (sick), sat make-up on Day 11 – still good
    _d(11): 84.0,
    _d(18): 86.0,
  },
  teacherNotes: [
    TaggedNote(
      date: _d(5),
      authorTag: 'class_teacher',
      content:
          'Bilal\'s father called school to report viral fever. Medical '
          'certificate from JPMC submitted via WhatsApp. Expected back by Day 10.',
    ),
    TaggedNote(
      date: _d(10),
      authorTag: 'class_teacher',
      content:
          'Bilal returned today looking much better. He requested notes for '
          'the week he missed and caught up on homework independently.',
    ),
    TaggedNote(
      date: _d(12),
      authorTag: 'coordinator',
      content:
          'Make-up exam administered. Bilal scored 84% – consistent with his '
          'historical performance. No concerns.',
    ),
  ],
);

// ────────────────────────────────────────────────────────────────────────────
// Exported collection
// ────────────────────────────────────────────────────────────────────────────

/// All mock students in insertion order:
/// [0] Amina Khan  – Financial Strain
/// [1] Tariq Ahmed – Academic Struggle
/// [2] Bilal Raza  – False Positive (sick week)
final List<Student> mockStudents = [aminaKhan, tariqAhmed, bilalRaza];

// lib/data/repositories/student_repository.dart
import '../models/mock_students.dart';
import '../models/student_model.dart';

class StudentRepository {
  static final StudentRepository instance = StudentRepository._internal();
  StudentRepository._internal() {
    // Initialize with mock dataset by default
    _students.addAll(mockStudents);
  }

  final List<Student> _students = [];

  List<Student> get students => List.unmodifiable(_students);

  /// Clears all students (wipes dummy data completely).
  void clearAll() {
    _students.clear();
  }

  /// Resets dataset back to initial sample mock students.
  void resetToMock() {
    _students.clear();
    _students.addAll(mockStudents);
  }

  /// Adds a single student record.
  void addStudent(Student student) {
    _students.removeWhere((s) => s.id == student.id);
    _students.insert(0, student);
  }

  /// Imports multiple students parsed from OCR scan sheet.
  void importFromOcr(List<Student> imported) {
    for (final student in imported) {
      _students.removeWhere((s) => s.name.toLowerCase() == student.name.toLowerCase());
      _students.insert(0, student);
    }
  }
}

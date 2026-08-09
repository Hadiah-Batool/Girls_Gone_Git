// lib/data/repositories/student_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_entry_model.dart';
import '../models/mock_students.dart';
import '../models/student_model.dart';

class StudentRepository {
  static final StudentRepository instance = StudentRepository._internal();
  StudentRepository._internal();

  final List<Student> _students = [];
  final List<LogEntry> _logs = [];
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<Student> get students => List.unmodifiable(_students);
  List<LogEntry> get logs => List.unmodifiable(_logs);

  static const String _studentsPrefKey = 'rehnumai_saved_students_v1';
  static const String _logsPrefKey = 'rehnumai_saved_logs_v1';

  /// Initializes persistence and loads stored data or sample data.
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadFromPrefs();
    _isInitialized = true;
  }

  Future<void> _loadFromPrefs() async {
    _students.clear();
    _logs.clear();

    final studentsJsonStr = _prefs?.getString(_studentsPrefKey);
    if (studentsJsonStr != null && studentsJsonStr.isNotEmpty) {
      try {
        final List dynamicList = jsonDecode(studentsJsonStr) as List;
        for (final item in dynamicList) {
          if (item is Map<String, dynamic>) {
            _students.add(Student.fromJson(item));
          }
        }
      } catch (_) {
        _students.addAll(mockStudents);
      }
    } else {
      _students.addAll(mockStudents);
      await _saveStudentsToPrefs();
    }

    final logsJsonStr = _prefs?.getString(_logsPrefKey);
    if (logsJsonStr != null && logsJsonStr.isNotEmpty) {
      try {
        final List dynamicList = jsonDecode(logsJsonStr) as List;
        for (final item in dynamicList) {
          if (item is Map<String, dynamic>) {
            _logs.add(LogEntry.fromJson(item));
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveStudentsToPrefs() async {
    if (_prefs == null) return;
    final jsonList = _students.map((s) => s.toJson()).toList();
    await _prefs!.setString(_studentsPrefKey, jsonEncode(jsonList));
  }

  Future<void> _saveLogsToPrefs() async {
    if (_prefs == null) return;
    final jsonList = _logs.map((l) => l.toJson()).toList();
    await _prefs!.setString(_logsPrefKey, jsonEncode(jsonList));
  }

  /// Clears all students and logs completely.
  Future<void> clearAll() async {
    _students.clear();
    _logs.clear();
    await _saveStudentsToPrefs();
    await _saveLogsToPrefs();
  }

  /// Resets dataset back to initial sample mock students.
  Future<void> resetToMock() async {
    _students.clear();
    _students.addAll(mockStudents);
    await _saveStudentsToPrefs();
  }

  /// Adds or updates a student record.
  Future<void> addStudent(Student student) async {
    _students.removeWhere((s) => s.id == student.id);
    _students.insert(0, student);
    await _saveStudentsToPrefs();
  }

  /// Adds a new log entry and persists it.
  Future<void> addLogEntry(LogEntry entry) async {
    _logs.insert(0, entry);
    await _saveLogsToPrefs();
  }

  /// Imports multiple students parsed from OCR scan sheet.
  Future<void> importFromOcr(List<Student> imported) async {
    for (final student in imported) {
      _students.removeWhere((s) => s.name.toLowerCase() == student.name.toLowerCase());
      _students.insert(0, student);
    }
    await _saveStudentsToPrefs();
  }
}

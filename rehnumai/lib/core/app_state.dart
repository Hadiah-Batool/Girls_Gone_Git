import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/student_model.dart';
import '../data/repositories/student_repository.dart';

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  bool _isDarkMode = false;
  String _teacherName = '';
  String _teacherAge = '';
  String _teacherEducation = '';
  String _teacherOccupation = '';

  List<Student> get students => StudentRepository.instance.students;

  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  String get teacherName => _teacherName;
  String get teacherAge => _teacherAge;
  String get teacherEducation => _teacherEducation;
  String get teacherOccupation => _teacherOccupation;
  bool get isProfileComplete => _teacherName.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _teacherName = _prefs.getString('teacherName') ?? '';
    _teacherAge = _prefs.getString('teacherAge') ?? '';
    _teacherEducation = _prefs.getString('teacherEducation') ?? '';
    _teacherOccupation = _prefs.getString('teacherOccupation') ?? '';
    _isInitialized = true;
    notifyListeners();
  }

  void clearAllDummyData() {
    StudentRepository.instance.clearAll();
    notifyListeners();
  }

  void resetDummyData() {
    StudentRepository.instance.resetToMock();
    notifyListeners();
  }

  void addStudent(Student student) {
    StudentRepository.instance.addStudent(student);
    notifyListeners();
  }

  void importStudents(List<Student> imported) {
    StudentRepository.instance.importFromOcr(imported);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      await _prefs.setBool('isDarkMode', _isDarkMode);
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required String name,
    required String age,
    required String education,
    required String occupation,
  }) async {
    _teacherName = name;
    _teacherAge = age;
    _teacherEducation = education;
    _teacherOccupation = occupation;
    
    await _prefs.setString('teacherName', name);
    await _prefs.setString('teacherAge', age);
    await _prefs.setString('teacherEducation', education);
    await _prefs.setString('teacherOccupation', occupation);
    notifyListeners();
  }
  
  Future<void> clearProfile() async {
    _teacherName = '';
    _teacherAge = '';
    _teacherEducation = '';
    _teacherOccupation = '';
    
    await _prefs.remove('teacherName');
    await _prefs.remove('teacherAge');
    await _prefs.remove('teacherEducation');
    await _prefs.remove('teacherOccupation');
    notifyListeners();
  }
}

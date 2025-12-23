import 'package:flutter/foundation.dart';
import '../data/student.dart';
import '../api/student_service.dart';
import '../data/auth_helper.dart';

class StudentProvider with ChangeNotifier {
  Student? _student;
  bool _isLoading = false;
  String? _error;

  Student? get student => _student;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _student != null;

  // Initialize student from saved data or email
  Future<void> initialize({String? email, bool forceRefresh = false}) async {
    if (_student != null && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email != null) {
        // Fetch from API
        final apiStudent = await StudentService.fetchStudentByEmail(email);
        if (apiStudent != null) {
          _student = apiStudent;
          await AuthHelper.saveLoginData(apiStudent);
        } else {
          // Try to load from saved data
          final savedStudent = await AuthHelper.getSavedLoginData();
          if (savedStudent != null && savedStudent.email == email) {
            _student = savedStudent;
          }
        }
      } else {
        // Load from saved data
        final savedStudent = await AuthHelper.getSavedLoginData();
        if (savedStudent != null) {
          _student = savedStudent;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing student: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update student data
  void updateStudent(Student updatedStudent) {
    _student = updatedStudent;
    AuthHelper.saveLoginData(updatedStudent).catchError((e) {
      debugPrint('Error saving student data: $e');
    });
    notifyListeners();
  }

  // Refresh student data from API
  Future<void> refreshStudent() async {
    if (_student == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiStudent = await StudentService.fetchStudentByEmail(_student!.email);
      if (apiStudent != null) {
        _student = apiStudent;
        await AuthHelper.saveLoginData(apiStudent);
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing student: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set student (for login)
  void setStudent(Student student) {
    _student = student;
    _error = null;
    AuthHelper.saveLoginData(student).catchError((e) {
      debugPrint('Error saving student data: $e');
    });
    notifyListeners();
  }

  // Clear student (for logout)
  void clearStudent() {
    _student = null;
    _error = null;
    AuthHelper.clearLoginData().catchError((e) {
      debugPrint('Error clearing login data: $e');
    });
    notifyListeners();
  }
}

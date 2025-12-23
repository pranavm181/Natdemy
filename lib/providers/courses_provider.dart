import 'package:flutter/foundation.dart';
import '../data/course_catalog.dart';
import '../api/course_service.dart';

class CoursesProvider with ChangeNotifier {
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCourses => _courses.isNotEmpty;

  // Fetch courses from API
  Future<void> fetchCourses({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final courses = await CourseService.fetchCourses(forceRefresh: forceRefresh);
      _courses = courses;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get course by ID
  Course? getCourseById(int courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Clear courses
  void clearCourses() {
    _courses = [];
    _error = null;
    notifyListeners();
  }
}

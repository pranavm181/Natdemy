import 'package:flutter/foundation.dart';
import '../data/joined_courses.dart';

class EnrolledCoursesProvider with ChangeNotifier {
  List<JoinedCourse> _enrolledCourses = [];
  bool _isLoading = false;
  String? _error;
  String? _currentEmail;
  Set<String> _loadedChapters = {};

  List<JoinedCourse> get enrolledCourses => _enrolledCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEnrolledCourses => _enrolledCourses.isNotEmpty;
  Set<String> get loadedChapters => _loadedChapters;

  // Initialize enrolled courses
  Future<void> initialize(String email, {bool forceRefresh = false}) async {
    if (_currentEmail == email && !forceRefresh && _enrolledCourses.isNotEmpty) {
      return; // Already loaded
    }

    _currentEmail = email;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await JoinedCourses.instance.initialize(email, forceRefresh: forceRefresh);
      _enrolledCourses = JoinedCourses.instance.all;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing enrolled courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chapters for a specific course
  Future<void> loadChaptersForCourse(int courseId, int streamId) async {
    final courseKey = '$courseId-$streamId';
    if (_loadedChapters.contains(courseKey)) {
      return; // Already loaded
    }

    _isLoading = true;
    notifyListeners();

    try {
      await JoinedCourses.instance.loadChaptersForCourse(courseId, streamId);
      _enrolledCourses = JoinedCourses.instance.all;
      _loadedChapters.add(courseKey);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chapters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get enrolled course by ID and stream ID
  JoinedCourse? getEnrolledCourse(int? courseId, int? streamId) {
    if (courseId == null || streamId == null) return null;
    try {
      return _enrolledCourses.firstWhere(
        (course) => course.courseId == courseId && course.streamId == streamId,
      );
    } catch (e) {
      return null;
    }
  }

  // Refresh enrolled courses
  Future<void> refresh() async {
    if (_currentEmail == null) return;
    await initialize(_currentEmail!, forceRefresh: true);
  }

  // Clear cache
  Future<void> clearCache() async {
    await JoinedCourses.instance.clearCache();
    _enrolledCourses = [];
    _loadedChapters.clear();
    notifyListeners();
  }
}

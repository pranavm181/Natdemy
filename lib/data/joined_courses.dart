import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'course_catalog.dart';
import 'material.dart';
import '../api/student_service.dart';

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class CourseVideo {
  const CourseVideo({
    this.id,
    this.lessonId,
    required this.name,
    this.order,
    this.vimeoId,
    this.videoUrl,
    this.durationSeconds,
    this.thumbnailUrl,
    this.isWatched,
    this.watchedDurationSeconds,
  });

  final int? id;
  final int? lessonId;
  final String name;
  final int? order;
  final String? vimeoId;
  final String? videoUrl;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final bool? isWatched;
  final int? watchedDurationSeconds;

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    return CourseVideo(
      id: _asInt(json['id']),
      lessonId: _asInt(json['lesson_id']),
      name: json['name']?.toString() ?? 'Video',
      order: _asInt(json['order']),
      vimeoId: json['vimeo_id']?.toString(),
      videoUrl: json['video_url']?.toString(),
      durationSeconds: _asInt(json['duration_seconds']),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      isWatched: json['is_watched'] as bool?,
      watchedDurationSeconds: _asInt(json['watched_duration_seconds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'name': name,
      'order': order,
      'vimeo_id': vimeoId,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      'thumbnail_url': thumbnailUrl,
      'is_watched': isWatched,
      'watched_duration_seconds': watchedDurationSeconds,
    };
  }
}

class CourseLesson {
  const CourseLesson({
    this.id,
    this.chapterId,
    required this.title,
    this.order,
    this.isCompleted,
    this.isLocked,
    this.description,
    this.videos = const [],
    this.materials = const [],
  });

  final int? id;
  final int? chapterId;
  final String title;
  final int? order;
  final bool? isCompleted;
  final bool? isLocked;
  final String? description;
  final List<CourseVideo> videos;
  final List<CourseMaterial> materials;

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'];
    final materialsJson = json['materials'];
    return CourseLesson(
      id: _asInt(json['id']),
      chapterId: _asInt(json['chapter_id']),
      title: json['title']?.toString() ?? 'Lesson',
      order: _asInt(json['order']),
      isCompleted: json['is_completed'] as bool?,
      isLocked: json['is_locked'] as bool?,
      description: json['description']?.toString(),
      videos: videosJson is List
          ? videosJson
              .whereType<Map<String, dynamic>>()
              .map(CourseVideo.fromJson)
              .toList()
          : const [],
      materials: materialsJson is List
          ? materialsJson
              .whereType<Map<String, dynamic>>()
              .map(CourseMaterial.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'title': title,
      'order': order,
      'is_completed': isCompleted,
      'is_locked': isLocked,
      'description': description,
      'videos': videos.map((v) => v.toJson()).toList(),
      'materials': materials.map((m) => m.toJson()).toList(),
    };
  }
}

class CourseChapter {
  const CourseChapter({
    this.id,
    this.courseId,
    required this.title,
    this.order,
    this.isCompleted,
    this.description,
    this.lessons = const [],
  });

  final int? id;
  final int? courseId;
  final String title;
  final int? order;
  final bool? isCompleted;
  final String? description;
  final List<CourseLesson> lessons;

  factory CourseChapter.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'];
    return CourseChapter(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      title: json['title']?.toString() ?? 'Chapter',
      order: _asInt(json['order']),
      isCompleted: json['is_completed'] as bool?,
      description: json['description']?.toString(),
      lessons: lessonsJson is List
          ? lessonsJson
              .whereType<Map<String, dynamic>>()
              .map(CourseLesson.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'order': order,
      'is_completed': isCompleted,
      'description': description,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}

class JoinedCourse {
  JoinedCourse({
    this.courseId,
    required this.title,
    required this.color,
    required this.description,
    required this.rating,
    this.streamId,
    this.streamName,
    this.whatYoullLearn = const [],
    this.thumbnailUrl,
    this.durationHours,
    this.duration,
    this.studentCount,
    this.price,
    this.lessonsCount,
    this.chaptersCount,
    this.topics,
    this.progressPercentage,
    this.enrolledAt,
    this.lastAccessedAt,
    this.chapters = const [],
  });

  final int? courseId;
  final String title;
  final Color color;
  final String description;
  final double rating;
  final int? streamId;
  final String? streamName;
  final List<String> whatYoullLearn;
  final String? thumbnailUrl;
  final int? durationHours;
  final int? duration;
  final int? studentCount;
  final double? price;
  final int? lessonsCount;
  final int? chaptersCount;
  final dynamic topics;
  final double? progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? lastAccessedAt;
  final List<CourseChapter> chapters;

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'title': title,
      'color': color.value,
      'description': description,
      'rating': rating,
      'stream_id': streamId,
      'stream_name': streamName,
      'what_youll_learn': whatYoullLearn,
      'thumbnail_url': thumbnailUrl,
      'duration_hours': durationHours,
      'duration': duration,
      'student_count': studentCount,
      'price': price,
      'lessons_count': lessonsCount,
      'chapters_count': chaptersCount,
      'topics': topics,
      'progress_percentage': progressPercentage,
      'enrolled_at': enrolledAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'chapters': chapters.map((c) => c.toJson()).toList(),
    };
  }

  factory JoinedCourse.fromJson(Map<String, dynamic> json) {
    final streamNameRaw = json['stream_name'];
    String? streamName;
    if (streamNameRaw is String) {
      final trimmed = streamNameRaw.trim();
      if (trimmed.isNotEmpty) {
        streamName = trimmed;
      }
    } else if (streamNameRaw != null) {
      final converted = streamNameRaw.toString().trim();
      if (converted.isNotEmpty) {
        streamName = converted;
      }
    }

    return JoinedCourse(
      courseId: _asInt(json['course_id']),
      title: json['title'] as String,
      color: Color(json['color'] as int),
      description: json['description'] as String,
      rating: (json['rating'] as num).toDouble(),
      streamId: _asInt(json['stream_id']),
      streamName: streamName,
      whatYoullLearn: json['what_youll_learn'] != null
          ? List<String>.from(json['what_youll_learn'] as List)
          : const [],
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationHours: json['duration_hours'] as int?,
      duration: json['duration'] as int?,
      studentCount: json['student_count'] as int?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      lessonsCount: json['lessons_count'] as int?,
      chaptersCount: json['chapters_count'] as int?,
      topics: json['topics'],
      progressPercentage: _asDouble(json['progress_percentage']),
      enrolledAt: _parseDate(json['enrolled_at']),
      lastAccessedAt: _parseDate(json['last_accessed_at']),
      chapters: (json['chapters'] is List)
          ? (json['chapters'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CourseChapter.fromJson)
              .toList()
          : const [],
    );
  }
}

class JoinedCourses {
  JoinedCourses._();
  static final JoinedCourses instance = JoinedCourses._();

  final List<JoinedCourse> _joined = <JoinedCourse>[];
  String? _currentEmail;

  List<JoinedCourse> get all => List.unmodifiable(_joined);

  Future<void> initialize(String email, {bool forceRefresh = false}) async {
    if (_currentEmail != email) {
      _currentEmail = email;
      await _loadCourses(forceRefresh: forceRefresh);
    } else if (_joined.isEmpty && _currentEmail != null) {
      await _loadCourses(forceRefresh: forceRefresh);
    } else if (forceRefresh) {
      // Force refresh even if email matches and we have data
      await _loadCourses(forceRefresh: true);
    }
  }

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    if (_currentEmail == null) return;

    int retries = 3;
    for (int i = 0; i < retries; i++) {
      try {
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 100 * i));
        }

        // Try to load from API first (always try API if forceRefresh is true)
        try {
          final apiCourses = await _loadCoursesFromAPI();
          _joined
            ..clear()
            ..addAll(apiCourses);
          debugPrint('✅ Loaded ${_joined.length} course(s) from API for $_currentEmail');
          await _saveCourses();
          return;
        } catch (e) {
          debugPrint('⚠️ Failed to load from API, trying local storage: $e');
          if (forceRefresh) {
            _joined.clear();
            await _clearCache();
            return;
          }
        }

        // Fallback to local storage only if not forcing refresh
        if (!forceRefresh) {
          final prefs = await SharedPreferences.getInstance();
          final key = 'joined_courses_$_currentEmail';
          final coursesJson = prefs.getString(key);

          _joined.clear();

          if (coursesJson != null && coursesJson.isNotEmpty) {
            final List<dynamic> decoded = json.decode(coursesJson);
            _joined.addAll(decoded
                .map((json) => JoinedCourse.fromJson(json as Map<String, dynamic>))
                .toList());

            debugPrint('✅ Loaded ${_joined.length} courses from local storage for $_currentEmail');
            return;
          } else {
            debugPrint('ℹ️ No saved courses found for $_currentEmail');
            return;
          }
        }
      } catch (e) {
        if (i == retries - 1) {
          // Last retry failed
          debugPrint('❌ Error loading joined courses after $retries attempts: $e');
          _joined.clear();
        } else {
          debugPrint('⚠️ Attempt ${i + 1} failed, retrying... Error: $e');
        }
      }
    }
  }
  
  Future<void> _clearCache() async {
    if (_currentEmail == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'joined_courses_$_currentEmail';
      await prefs.remove(key);
      debugPrint('🗑️ Cleared cache for $_currentEmail');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }
  
  // Load courses from API
  Future<List<JoinedCourse>> _loadCoursesFromAPI() async {
    if (_currentEmail == null) return [];
    
    try {
      return await StudentService.fetchEnrolledCourses(_currentEmail!);
    } catch (e) {
      debugPrint('❌ Error loading courses from API: $e');
      rethrow;
    }
  }

  Future<void> _saveCourses() async {
    if (_currentEmail == null) return;

    int retries = 3;
    for (int i = 0; i < retries; i++) {
      try {

        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 100 * i));
        }

        final prefs = await SharedPreferences.getInstance();
        final key = 'joined_courses_$_currentEmail';
        final coursesJson =
            json.encode(_joined.map((course) => course.toJson()).toList());
        final success = await prefs.setString(key, coursesJson);

        if (success) {
          debugPrint('💾 Saved ${_joined.length} courses for $_currentEmail');
          return; // Success, exit retry loop
        } else {
          if (i == retries - 1) {
            debugPrint('⚠️ Failed to save courses for $_currentEmail');
          }
        }
      } catch (e) {
        if (i == retries - 1) {
          // Last retry failed
          debugPrint('❌ Error saving joined courses after $retries attempts: $e');
        } else {
          debugPrint('⚠️ Save attempt ${i + 1} failed, retrying... Error: $e');
        }
      }
    }
  }

  Future<void> addFromCourse(Course course) async {
    if (_currentEmail == null) {
      debugPrint('⚠️ Cannot add course — no email initialized');
      return;
    }

    final exists = _joined.any((c) => c.title == course.title);
    if (exists) {
      debugPrint('ℹ️ Course ${course.title} already joined');
      return;
    }

    _joined.add(JoinedCourse(
      courseId: course.id,
      title: course.title,
      color: course.color,
      description: course.description,
      rating: course.rating,
      whatYoullLearn: course.whatYoullLearn,
      thumbnailUrl: course.thumbnailUrl,
      durationHours: course.durationHours,
      duration: course.duration,
      studentCount: course.studentCount,
      price: course.price,
      lessonsCount: course.lessonsCount,
      chaptersCount: course.chaptersCount,
      topics: course.topics,
      chapters: const [],
    ));

    await _saveCourses();
  }

  Future<void> removeCourse(String title) async {
    _joined.removeWhere((c) => c.title == title);
    await _saveCourses();
  }

  Future<void> clear() async {
    _joined.clear();
    _currentEmail = null;
    debugPrint('🧹 Cleared in-memory joined courses.');
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'course_catalog.dart';
import 'course_stream.dart';
import 'material.dart';
import '../api/student_service.dart';
import '../api/course_service.dart';
import '../api/api_client.dart';

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
    this.materialUrl,
    this.materialName,
    this.mcqUrl,
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
  final String? materialUrl; // PDF material URL for this video
  final String? materialName; // Material name/title
  final String? mcqUrl; // MCQ/Question Bank URL for this video

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    // Parse material - can be a string URL or an object with url/name
    String? materialUrl;
    String? materialName;
    
    final materialField = json['material'];
    if (materialField != null) {
      if (materialField is String && materialField.isNotEmpty) {
        materialUrl = materialField;
        materialName = json['name']?.toString() ?? 'Video Material';
      } else if (materialField is Map<String, dynamic>) {
        materialUrl = materialField['url']?.toString() ?? 
                     materialField['file']?.toString() ?? 
                     materialField['file_url']?.toString();
        materialName = materialField['name']?.toString() ?? 
                      materialField['title']?.toString() ?? 
                      'Video Material';
      }
    }
    
    // Parse MCQ - can be a string URL or an object with url
    String? mcqUrl;
    final mcqField = json['mcq'];
    if (mcqField != null) {
      if (mcqField is String && mcqField.isNotEmpty) {
        mcqUrl = mcqField;
        debugPrint('📝 Video "${json['name']}": Found MCQ: $mcqUrl');
      } else if (mcqField is Map<String, dynamic>) {
        mcqUrl = mcqField['url']?.toString() ?? 
                 mcqField['file']?.toString() ?? 
                 mcqField['file_url']?.toString();
        if (mcqUrl != null && mcqUrl.isNotEmpty) {
          debugPrint('📝 Video "${json['name']}": Found MCQ (object): $mcqUrl');
        }
      }
    }
    
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
      materialUrl: materialUrl,
      materialName: materialName,
      mcqUrl: mcqUrl,
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
      'material': materialUrl != null ? {'url': materialUrl, 'name': materialName} : null,
      'mcq': mcqUrl,
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
    
    // Try multiple field names for materials (materials, attachments, files)
    dynamic materialsJson = json['materials'] ?? json['attachments'] ?? json['files'];
    
    // Parse materials
    final List<CourseMaterial> materials = materialsJson is List
        ? materialsJson
            .whereType<Map<String, dynamic>>()
            .map((materialJson) {
              try {
                return CourseMaterial.fromJson(materialJson);
              } catch (e) {
                debugPrint('⚠️ Error parsing material in lesson "${json['title']}": $e');
                debugPrint('   Material data: $materialJson');
                return null;
              }
            })
            .whereType<CourseMaterial>()
            .toList()
        : <CourseMaterial>[];
    
    // Also check if there's a single file/attachment URL directly on the lesson
    if (materials.isEmpty) {
      final fileUrl = json['file'] ?? json['attachment'] ?? json['material_url'];
      if (fileUrl != null && fileUrl is String && fileUrl.isNotEmpty) {
        try {
          final singleMaterial = CourseMaterial(
            name: json['title']?.toString() ?? 'Lesson Material',
            url: fileUrl,
            fileType: 'pdf',
          );
          materials.add(singleMaterial);
          debugPrint('📄 Lesson "${json['title']}": Found single material attachment');
        } catch (e) {
          debugPrint('⚠️ Error creating material from file URL: $e');
        }
      }
    }
    
    if (materials.isNotEmpty) {
      debugPrint('📄 Lesson "${json['title']}": Found ${materials.length} material(s)');
    }
    
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
      materials: materials,
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
    this.isEnrolled = true, // Default to true (enrolled) - false means pending/locked
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
  final bool isEnrolled; // true = enrolled and unlocked, false = pending/locked

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
        isEnrolled: json['is_enrolled'] != null
            ? (json['is_enrolled'] is bool
                ? json['is_enrolled'] as bool
                : json['is_enrolled'].toString().toLowerCase() == 'true')
            : true, // Default to enrolled if not specified
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
    } else {
      // Skip API call if we already have data - verified status check is expensive
      // Only check if courses list is empty or we need to verify status
      // This significantly improves performance on subsequent loads
      if (_joined.isEmpty) {
        // Only load if we have no courses
        await _loadCourses(forceRefresh: false);
      }
      // Otherwise, use cached data - much faster!
    }
  }

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    if (_currentEmail == null) return;

    // Try to load from local storage first (fast) if not forcing refresh
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'joined_courses_$_currentEmail';
      final coursesJson = prefs.getString(key);

      if (coursesJson != null && coursesJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(coursesJson);
          _joined.clear();
          _joined.addAll(decoded
              .map((json) => JoinedCourse.fromJson(json as Map<String, dynamic>))
              .toList());

          debugPrint('✅ Loaded ${_joined.length} courses from local storage for $_currentEmail');
          
          // Refresh from API in background (non-blocking)
          _loadCoursesFromAPI().then((apiCourses) {
            if (apiCourses.isNotEmpty) {
              _joined
                ..clear()
                ..addAll(apiCourses);
              _saveCourses();
              debugPrint('🔄 Updated ${_joined.length} courses from API in background');
            }
          }).catchError((e) {
            debugPrint('⚠️ Background API refresh failed: $e');
          });
          
          return;
        } catch (e) {
          debugPrint('⚠️ Error loading from local storage: $e');
        }
      }
    }

    // Load from API (either force refresh or no cache available)
    int retries = 3;
    for (int i = 0; i < retries; i++) {
      try {
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 100 * i));
        }

        try {
          final apiCourses = await _loadCoursesFromAPI();
          _joined
            ..clear()
            ..addAll(apiCourses);
          debugPrint('✅ Loaded ${_joined.length} course(s) from API for $_currentEmail');
          await _saveCourses();
          return;
        } catch (e) {
          debugPrint('⚠️ Failed to load from API: $e');
          if (forceRefresh) {
            _joined.clear();
            await _clearCache();
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
      final enrolledCourses = await StudentService.fetchEnrolledCourses(_currentEmail!);
      
      // Also check if student has a selected course/stream from registration
      // The verified field in student data determines if course should be locked/unlocked
      try {
        final studentData = await StudentService.fetchStudentDataWithCourseStream(_currentEmail!);
        if (studentData != null) {
          // Extract course_id, stream_id, and verified from student data
          int? studentCourseId;
          int? studentStreamId;
          bool? studentVerified;
          
          // Try different possible field names for course_id
          var rawCourseId = studentData['course_id'] ?? 
                           studentData['courseId'] ?? 
                           studentData['course'];
          
          // If course is an object, extract its ID
          if (rawCourseId is Map<String, dynamic>) {
            rawCourseId = rawCourseId['id'] ?? rawCourseId['course_id'];
          }
          
          if (rawCourseId != null) {
            if (rawCourseId is int) {
              studentCourseId = rawCourseId;
            } else if (rawCourseId is String) {
              studentCourseId = int.tryParse(rawCourseId);
            } else if (rawCourseId is double) {
              studentCourseId = rawCourseId.toInt();
            }
          }
          
          // Try different possible field names for stream_id
          var rawStreamId = studentData['stream_id'] ?? 
                           studentData['streamId'] ?? 
                           studentData['stream'];
          
          // If stream is an object, extract its ID
          if (rawStreamId is Map<String, dynamic>) {
            rawStreamId = rawStreamId['id'] ?? rawStreamId['stream_id'];
          }
          
          if (rawStreamId != null) {
            if (rawStreamId is int) {
              studentStreamId = rawStreamId;
            } else if (rawStreamId is String) {
              studentStreamId = int.tryParse(rawStreamId);
            } else if (rawStreamId is double) {
              studentStreamId = rawStreamId.toInt();
            }
          }
          
          // Extract verified/verification field from student data
          var rawVerified = studentData['verification'] ?? studentData['verified'];
          if (rawVerified != null) {
            if (rawVerified is bool) {
              studentVerified = rawVerified;
            } else if (rawVerified is String) {
              studentVerified = rawVerified.toLowerCase() == 'true';
            } else if (rawVerified is int) {
              studentVerified = rawVerified == 1;
            }
          }
          
          // Check if we already have an enrollment for this course/stream
          bool hasEnrollment = enrolledCourses.any((course) => 
            course.courseId == studentCourseId && course.streamId == studentStreamId);
          
          // If student has course/stream selected, add it (locked or unlocked based on verified)
          if (studentCourseId != null && studentStreamId != null) {
            try {
              // Fetch courses (this also loads streams into cache)
              final allCourses = await CourseService.fetchCourses();
              
              Course? selectedCourse;
              try {
                selectedCourse = allCourses.firstWhere((c) => c.id == studentCourseId);
              } catch (e) {
                // Course not found, skip
              }
              
              if (selectedCourse != null) {
                // Find stream name
                final streams = CourseService.cachedStreams;
                CourseStream? selectedStream;
                try {
                  selectedStream = streams.firstWhere((s) => s.id == studentStreamId);
                } catch (e) {
                  // Stream not found, skip
                }
                
                if (selectedStream != null) {
                  // Determine if course should be locked based on verified field
                  final isEnrolled = studentVerified == true;
                  
                  // Skip fetching chapters - load them on-demand for better performance
                  // Chapters will be loaded when user navigates to course detail
                  List<CourseChapter> chapters = [];
                  
                  // Create course entry (locked or unlocked based on verified status)
                  final studentCourse = JoinedCourse(
                    courseId: selectedCourse.id,
                    title: selectedCourse.title,
                    color: selectedCourse.color,
                    description: selectedCourse.description.isNotEmpty 
                        ? selectedCourse.description 
                        : 'Description not available.',
                    rating: selectedCourse.rating,
                    streamId: selectedStream.id,
                    streamName: selectedStream.name,
                    whatYoullLearn: selectedCourse.whatYoullLearn,
                    thumbnailUrl: selectedCourse.thumbnailUrl,
                    durationHours: selectedCourse.durationHours,
                    duration: selectedCourse.duration,
                    studentCount: selectedCourse.studentCount,
                    price: selectedCourse.price,
                    lessonsCount: selectedCourse.lessonsCount,
                    chaptersCount: selectedCourse.chaptersCount,
                    topics: selectedCourse.topics,
                    chapters: chapters,
                    isEnrolled: isEnrolled,
                  );
                  
                  // Add course if not already in list
                  if (!hasEnrollment) {
                    enrolledCourses.add(studentCourse);
                  } else {
                    // Update existing enrollment with verified status from student data
                    final existingIndex = enrolledCourses.indexWhere((c) => 
                      c.courseId == studentCourseId && c.streamId == studentStreamId);
                    if (existingIndex >= 0) {
                      final existingCourse = enrolledCourses[existingIndex];
                      final finalIsEnrolled = studentVerified != null ? isEnrolled : existingCourse.isEnrolled;
                      
                      enrolledCourses[existingIndex] = JoinedCourse(
                        courseId: existingCourse.courseId,
                        title: existingCourse.title,
                        color: existingCourse.color,
                        description: existingCourse.description,
                        rating: existingCourse.rating,
                        streamId: existingCourse.streamId,
                        streamName: existingCourse.streamName,
                        whatYoullLearn: existingCourse.whatYoullLearn,
                        thumbnailUrl: existingCourse.thumbnailUrl,
                        durationHours: existingCourse.durationHours,
                        duration: existingCourse.duration,
                        studentCount: existingCourse.studentCount,
                        price: existingCourse.price,
                        lessonsCount: existingCourse.lessonsCount,
                        chaptersCount: existingCourse.chaptersCount,
                        topics: existingCourse.topics,
                        progressPercentage: existingCourse.progressPercentage,
                        enrolledAt: existingCourse.enrolledAt,
                        lastAccessedAt: existingCourse.lastAccessedAt,
                        chapters: existingCourse.chapters,
                        isEnrolled: finalIsEnrolled,
                      );
                    }
                  }
                }
              }
            } catch (e) {
              // Silently handle errors
            }
          }
        }
      } catch (e) {
        // Silently handle errors
      }
      
      return enrolledCourses;
    } catch (e) {
      debugPrint('❌ Error loading courses from API: $e');
      rethrow;
    }
  }

  // Public method to fetch chapters for a specific course and stream (lazy loading)
  Future<List<CourseChapter>> fetchChaptersForCourseStream(int courseId, int streamId) async {
    return await _fetchChaptersForCourseStream(courseId, streamId);
  }

  // Update chapters for a specific course in the list
  Future<void> loadChaptersForCourse(int courseId, int streamId) async {
    try {
      final chapters = await _fetchChaptersForCourseStream(courseId, streamId);
      final index = _joined.indexWhere((c) => c.courseId == courseId && c.streamId == streamId);
      if (index >= 0) {
        final course = _joined[index];
        _joined[index] = JoinedCourse(
          courseId: course.courseId,
          title: course.title,
          color: course.color,
          description: course.description,
          rating: course.rating,
          streamId: course.streamId,
          streamName: course.streamName,
          whatYoullLearn: course.whatYoullLearn,
          thumbnailUrl: course.thumbnailUrl,
          durationHours: course.durationHours,
          duration: course.duration,
          studentCount: course.studentCount,
          price: course.price,
          lessonsCount: course.lessonsCount,
          chaptersCount: course.chaptersCount,
          topics: course.topics,
          progressPercentage: course.progressPercentage,
          enrolledAt: course.enrolledAt,
          lastAccessedAt: course.lastAccessedAt,
          chapters: chapters,
          isEnrolled: course.isEnrolled,
        );
        await _saveCourses();
        debugPrint('✅ Loaded ${chapters.length} chapter(s) for course $courseId, stream $streamId');
      }
    } catch (e) {
      debugPrint('❌ Error loading chapters for course $courseId, stream $streamId: $e');
      rethrow;
    }
  }

  // Fetch chapters for a specific course and stream from the API (private)
  Future<List<CourseChapter>> _fetchChaptersForCourseStream(int courseId, int streamId) async {
    try {
      debugPrint('🔄 Fetching chapters for course $courseId, stream $streamId...');
      
      // Try admin web course endpoint first (may have full structure)
      try {
        debugPrint('🔄 Trying admin web course endpoint...');
        final adminResponse = await ApiClient.get('/admin/web/course/', queryParams: {'format': 'json'}, includeAuth: false);
        
        if (adminResponse.statusCode == 200) {
          final isHtml = adminResponse.body.trim().startsWith('<!DOCTYPE') || 
                         adminResponse.body.trim().startsWith('<html') ||
                         adminResponse.body.trim().startsWith('<HTML');
          
          if (!isHtml) {
            try {
              final adminData = json.decode(adminResponse.body);
              debugPrint('✅ Admin endpoint returned JSON data');
              
              // Handle different response structures
              List<dynamic>? coursesList;
              if (adminData is List) {
                coursesList = adminData;
              } else if (adminData is Map<String, dynamic>) {
                coursesList = adminData['results'] ?? adminData['courses'] ?? adminData['data'];
                if (coursesList is! List) {
                  coursesList = null;
                }
              }
              
              if (coursesList != null) {
                debugPrint('📋 Found ${coursesList.length} course(s) in admin endpoint');
                
                // Find the course matching courseId
                for (final courseJson in coursesList) {
                  if (courseJson is! Map<String, dynamic>) continue;
                  
                  final courseIdFromApi = _asInt(courseJson['id']);
                  if (courseIdFromApi == courseId) {
                    debugPrint('✅ Found matching course in admin endpoint');
                    
                    // Check if course has streams with chapters
                    final streamsJson = courseJson['streams'] ?? courseJson['course_streams'];
                    if (streamsJson is List) {
                      for (final streamJson in streamsJson) {
                        if (streamJson is! Map<String, dynamic>) continue;
                        
                        final streamIdFromApi = _asInt(streamJson['id']);
                        if (streamIdFromApi == streamId) {
                          debugPrint('✅ Found matching stream in admin endpoint');
                          
                          // Get chapters from stream
                          final chaptersJson = streamJson['chapters'];
                          if (chaptersJson is List && chaptersJson.isNotEmpty) {
                            debugPrint('📚 Found ${chaptersJson.length} chapter(s) in stream');
                            
                            // Also get lessons from the main API response to merge
                            List<dynamic>? allLessonsJson;
                            try {
                              final homeResponse = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
                              if (homeResponse.statusCode == 200) {
                                final homeData = json.decode(homeResponse.body);
                                final homeDataMap = homeData['data'] as Map<String, dynamic>?;
                                allLessonsJson = homeDataMap?['lessons'] as List<dynamic>?;
                                debugPrint('📥 Fetched ${allLessonsJson?.length ?? 0} lesson(s) from home API for merging');
                              }
                            } catch (e) {
                              debugPrint('⚠️ Could not fetch lessons from home API: $e');
                            }
                            
                            final chapters = <CourseChapter>[];
                            for (final chapterJson in chaptersJson) {
                              if (chapterJson is! Map<String, dynamic>) continue;
                              try {
                                final chapterId = _asInt(chapterJson['id']);
                                final chapterLessons = <CourseLesson>[];
                                
                                // First, check if lessons are already nested in the chapter
                                final nestedLessonsJson = chapterJson['lessons'];
                                if (nestedLessonsJson is List && nestedLessonsJson.isNotEmpty) {
                                  debugPrint('   📚 Chapter "${chapterJson['title']}": Found ${nestedLessonsJson.length} nested lesson(s)');
                                  for (final lessonJson in nestedLessonsJson) {
                                    if (lessonJson is Map<String, dynamic>) {
                                      try {
                                        final lesson = CourseLesson.fromJson(lessonJson);
                                        chapterLessons.add(lesson);
                                        debugPrint('     ✅ Added nested lesson "${lesson.title}"');
                                      } catch (e) {
                                        debugPrint('     ⚠️ Error parsing nested lesson: $e');
                                      }
                                    }
                                  }
                                }
                                
                                // Also match lessons from the main lessons array
                                if (allLessonsJson != null && allLessonsJson.isNotEmpty) {
                                  debugPrint('   🔍 Also searching ${allLessonsJson.length} lesson(s) from main array for chapter $chapterId...');
                                  for (final lessonJson in allLessonsJson) {
                                    if (lessonJson is! Map<String, dynamic>) continue;
                                    
                                    // Extract chapter ID from lesson
                                    int? lessonChapterId;
                                    final lessonChapterField = lessonJson['chapter'];
                                    if (lessonChapterField is int) {
                                      lessonChapterId = lessonChapterField;
                                    } else if (lessonChapterField is Map<String, dynamic>) {
                                      lessonChapterId = _asInt(lessonChapterField['id']);
                                    } else if (lessonChapterField != null) {
                                      lessonChapterId = _asInt(lessonChapterField);
                                    }
                                    
                                    if (lessonChapterId == null) {
                                      lessonChapterId = _asInt(lessonJson['chapter_id']);
                                    }
                                    
                                    // Only add if not already added from nested lessons
                                    if (lessonChapterId == chapterId && 
                                        !chapterLessons.any((l) => l.id == _asInt(lessonJson['id']))) {
                                      try {
                                        final lesson = CourseLesson.fromJson(lessonJson);
                                        chapterLessons.add(lesson);
                                        debugPrint('     ✅ Added lesson from main array "${lesson.title}"');
                                      } catch (e) {
                                        debugPrint('     ⚠️ Error parsing lesson from main array: $e');
                                      }
                                    }
                                  }
                                }
                                
                                final chapter = CourseChapter.fromJson(chapterJson);
                                // Create chapter with merged lessons
                                final chapterWithLessons = CourseChapter(
                                  id: chapter.id,
                                  title: chapter.title,
                                  order: chapter.order,
                                  description: chapter.description,
                                  isCompleted: chapter.isCompleted,
                                  lessons: chapterLessons,
                                );
                                chapters.add(chapterWithLessons);
                                debugPrint('   ✅ Chapter "${chapter.title}": Total ${chapterLessons.length} lesson(s)');
                              } catch (e) {
                                debugPrint('   ⚠️ Error parsing chapter: $e');
                              }
                            }
                            
                            if (chapters.isNotEmpty) {
                              debugPrint('✅ Returning ${chapters.length} chapter(s) from admin endpoint with merged lessons');
                              return chapters;
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing admin endpoint response: $e');
            }
          } else {
            debugPrint('⚠️ Admin endpoint returned HTML (login page?)');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Admin endpoint failed: $e');
      }
      
      // Fallback to home API which contains chapters and lessons
      debugPrint('🔄 Falling back to home API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final dataMap = data['data'] as Map<String, dynamic>?;
        
        if (dataMap != null) {
          // Get chapters and lessons from API
          final chaptersJson = dataMap['chapters'] as List<dynamic>?;
          final lessonsJson = dataMap['lessons'] as List<dynamic>?;
          
          debugPrint('📋 Found ${chaptersJson?.length ?? 0} chapter(s) and ${lessonsJson?.length ?? 0} lesson(s) in API');
          
          // Also check if chapters are nested within streams
          final streamsJson = dataMap['streams'] as List<dynamic>?;
          if (streamsJson != null) {
            debugPrint('🌊 Found ${streamsJson.length} stream(s) in API, checking for nested chapters...');
            for (final streamJson in streamsJson) {
              if (streamJson is Map<String, dynamic>) {
                final streamIdFromApi = _asInt(streamJson['id']);
                if (streamIdFromApi == streamId) {
                  final nestedChapters = streamJson['chapters'] as List<dynamic>?;
                  if (nestedChapters != null && nestedChapters.isNotEmpty) {
                    debugPrint('   ✅ Found ${nestedChapters.length} chapter(s) nested in stream $streamId');
                    // Use nested chapters if available, but also fetch lessons from lessons array
                    final filteredChapters = <CourseChapter>[];
                    
                    // Get lessons array from dataMap to match with chapters
                    final lessonsJson = dataMap['lessons'] as List<dynamic>?;
                    
                    for (final chapterJson in nestedChapters) {
                      if (chapterJson is! Map<String, dynamic>) continue;
                      try {
                        final chapterId = _asInt(chapterJson['id']);
                        final chapterLessons = <CourseLesson>[];
                        
                        // First, check if lessons are already nested in the chapter
                        final nestedLessonsJson = chapterJson['lessons'];
                        if (nestedLessonsJson is List && nestedLessonsJson.isNotEmpty) {
                          debugPrint('   📚 Chapter "${chapterJson['title']}": Found ${nestedLessonsJson.length} nested lesson(s)');
                          for (final lessonJson in nestedLessonsJson) {
                            if (lessonJson is Map<String, dynamic>) {
                              try {
                                final lesson = CourseLesson.fromJson(lessonJson);
                                chapterLessons.add(lesson);
                                debugPrint('     ✅ Added nested lesson "${lesson.title}"');
                              } catch (e) {
                                debugPrint('     ⚠️ Error parsing nested lesson: $e');
                              }
                            }
                          }
                        }
                        
                        // Also match lessons from the main lessons array
                        if (lessonsJson != null && lessonsJson.isNotEmpty) {
                          debugPrint('   🔍 Searching ${lessonsJson.length} lesson(s) from main array for nested chapter $chapterId...');
                          for (final lessonJson in lessonsJson) {
                            if (lessonJson is! Map<String, dynamic>) continue;
                            
                            // Extract chapter ID from lesson
                            int? lessonChapterId;
                            final lessonChapterField = lessonJson['chapter'];
                            if (lessonChapterField is int) {
                              lessonChapterId = lessonChapterField;
                            } else if (lessonChapterField is Map<String, dynamic>) {
                              lessonChapterId = _asInt(lessonChapterField['id']);
                            } else if (lessonChapterField != null) {
                              lessonChapterId = _asInt(lessonChapterField);
                            }
                            
                            // Also check chapter_id field as fallback
                            if (lessonChapterId == null) {
                              lessonChapterId = _asInt(lessonJson['chapter_id']);
                            }
                            
                            if (lessonChapterId == chapterId) {
                              // Check if lesson is already added (by ID or title)
                              final lessonId = _asInt(lessonJson['id']);
                              final lessonTitle = lessonJson['title']?.toString();
                              final alreadyAdded = chapterLessons.any((l) => 
                                (l.id != null && l.id == lessonId) || 
                                (lessonTitle != null && l.title == lessonTitle)
                              );
                              
                              if (!alreadyAdded) {
                                try {
                                  final lesson = CourseLesson.fromJson(lessonJson);
                                  chapterLessons.add(lesson);
                                  debugPrint('     ✅ Added lesson from main array "${lesson.title}"');
                                } catch (e) {
                                  debugPrint('     ⚠️ Error parsing lesson for nested chapter: $e');
                                }
                              }
                            }
                          }
                        }
                        
                        final chapter = CourseChapter.fromJson(chapterJson);
                        // Create chapter with fetched lessons
                        final chapterWithLessons = CourseChapter(
                          id: chapter.id,
                          title: chapter.title,
                          order: chapter.order,
                          description: chapter.description,
                          isCompleted: chapter.isCompleted,
                          lessons: chapterLessons,
                        );
                        filteredChapters.add(chapterWithLessons);
                        debugPrint('   📚 Chapter "${chapter.title}": ${chapterLessons.length} lesson(s), ${chapterLessons.fold<int>(0, (sum, l) => sum + l.videos.length)} video(s)');
                      } catch (e) {
                        debugPrint('   ⚠️ Error parsing nested chapter: $e');
                      }
                    }
                    if (filteredChapters.isNotEmpty) {
                      debugPrint('📚 Returning ${filteredChapters.length} chapter(s) from nested stream structure');
                      return filteredChapters;
                    }
                  }
                }
              }
            }
          }
          
          if (chaptersJson != null && lessonsJson != null) {
            // Filter chapters for this course and stream
            final filteredChapters = <CourseChapter>[];
            
            for (final chapterJson in chaptersJson) {
              if (chapterJson is! Map<String, dynamic>) continue;
              
              // Extract course ID - can be direct ID, nested object, or nested in stream
              int? chapterCourseId;
              final courseField = chapterJson['course'];
              if (courseField is int) {
                chapterCourseId = courseField;
              } else if (courseField is Map<String, dynamic>) {
                chapterCourseId = _asInt(courseField['id']);
              } else if (courseField != null) {
                chapterCourseId = _asInt(courseField);
              }
              
              // Extract stream ID - can be direct ID or nested object
              int? chapterStreamId;
              final streamField = chapterJson['stream'];
              if (streamField is int) {
                chapterStreamId = streamField;
              } else if (streamField is Map<String, dynamic>) {
                chapterStreamId = _asInt(streamField['id']);
                
                // If course ID is null, try to get it from nested stream.course
                if (chapterCourseId == null) {
                  final nestedCourse = streamField['course'];
                  if (nestedCourse is int) {
                    chapterCourseId = nestedCourse;
                  } else if (nestedCourse is Map<String, dynamic>) {
                    chapterCourseId = _asInt(nestedCourse['id']);
                  } else if (nestedCourse != null) {
                    chapterCourseId = _asInt(nestedCourse);
                  }
                }
              } else if (streamField != null) {
                chapterStreamId = _asInt(streamField);
              }
              
              debugPrint('   Chapter "${chapterJson['title']}": course=$chapterCourseId, stream=$chapterStreamId (target: course=$courseId, stream=$streamId)');
              
              // Match chapter to course and stream
              // Match by stream ID first (most reliable), then verify course ID if available
              bool matches = chapterStreamId == streamId;
              if (matches && chapterCourseId != null) {
                // If course ID is available, verify it matches too
                matches = chapterCourseId == courseId;
              }
              
              if (matches) {
                debugPrint('   ✅ Matched chapter "${chapterJson['title']}"');
                
                // Find lessons for this chapter from the lessons array
                final chapterId = _asInt(chapterJson['id']);
                final chapterLessons = <CourseLesson>[];
                
                // First, check if lessons are already nested in the chapter JSON
                final nestedLessonsJson = chapterJson['lessons'];
                if (nestedLessonsJson is List && nestedLessonsJson.isNotEmpty) {
                  debugPrint('   📚 Chapter "${chapterJson['title']}": Found ${nestedLessonsJson.length} nested lesson(s)');
                  for (final lessonJson in nestedLessonsJson) {
                    if (lessonJson is Map<String, dynamic>) {
                      try {
                        final lesson = CourseLesson.fromJson(lessonJson);
                        chapterLessons.add(lesson);
                        debugPrint('     ✅ Added nested lesson "${lesson.title}" (${lesson.videos.length} video(s))');
                      } catch (e) {
                        debugPrint('     ⚠️ Error parsing nested lesson: $e');
                      }
                    }
                  }
                }
                
                // Also match lessons from the main lessons array
                if (lessonsJson != null && lessonsJson.isNotEmpty) {
                  debugPrint('   🔍 Searching ${lessonsJson.length} lesson(s) from main array for chapter $chapterId...');
                  
                  int matchedCount = 0;
                  int skippedCount = 0;
                  
                  for (final lessonJson in lessonsJson) {
                    if (lessonJson is! Map<String, dynamic>) continue;
                    
                    // Extract chapter ID from lesson - can be direct ID or nested object
                    int? lessonChapterId;
                    final lessonChapterField = lessonJson['chapter'];
                    if (lessonChapterField is int) {
                      lessonChapterId = lessonChapterField;
                    } else if (lessonChapterField is Map<String, dynamic>) {
                      lessonChapterId = _asInt(lessonChapterField['id']);
                    } else if (lessonChapterField != null) {
                      lessonChapterId = _asInt(lessonChapterField);
                    }
                    
                    // Also check chapter_id field as fallback
                    if (lessonChapterId == null) {
                      lessonChapterId = _asInt(lessonJson['chapter_id']);
                    }
                    
                    if (lessonChapterId == chapterId) {
                      // Check if lesson is already added (by ID or title)
                      final lessonId = _asInt(lessonJson['id']);
                      final lessonTitle = lessonJson['title']?.toString();
                      final alreadyAdded = chapterLessons.any((l) => 
                        (l.id != null && l.id == lessonId) || 
                        (lessonTitle != null && l.title == lessonTitle)
                      );
                      
                      if (!alreadyAdded) {
                        try {
                          final lesson = CourseLesson.fromJson(lessonJson);
                          chapterLessons.add(lesson);
                          matchedCount++;
                          debugPrint('     ✅ Added lesson "${lesson.title}" (${lesson.videos.length} video(s))');
                        } catch (e, stackTrace) {
                          debugPrint('     ⚠️ Error parsing lesson: $e');
                          debugPrint('        Stack trace: $stackTrace');
                          debugPrint('        Lesson data: $lessonJson');
                        }
                      } else {
                        skippedCount++;
                        debugPrint('     ⏭️ Skipped duplicate lesson "${lessonTitle ?? 'Unknown'}"');
                      }
                    }
                  }
                  
                  debugPrint('   📊 Matched: $matchedCount, Skipped duplicates: $skippedCount');
                }
                
                debugPrint('   📚 Found ${chapterLessons.length} total lesson(s) with ${chapterLessons.fold<int>(0, (sum, l) => sum + l.videos.length)} video(s) for chapter "${chapterJson['title']}"');
                
                // Create chapter with lessons
                try {
                  final chapter = CourseChapter.fromJson(chapterJson);
                  // Create a new chapter with the fetched lessons
                  final chapterWithLessons = CourseChapter(
                    id: chapter.id,
                    title: chapter.title,
                    order: chapter.order,
                    description: chapter.description,
                    isCompleted: chapter.isCompleted,
                    lessons: chapterLessons,
                  );
                  
                  filteredChapters.add(chapterWithLessons);
                } catch (e, stackTrace) {
                  debugPrint('   ⚠️ Error parsing chapter: $e');
                  debugPrint('      Stack trace: $stackTrace');
                }
              }
            }
            
            debugPrint('📚 Found ${filteredChapters.length} chapter(s) for course $courseId, stream $streamId');
            if (filteredChapters.isEmpty) {
              debugPrint('   ⚠️ No chapters matched. Available chapters:');
              for (final chapterJson in chaptersJson) {
                if (chapterJson is Map<String, dynamic>) {
                  final courseField = chapterJson['course'];
                  final streamField = chapterJson['stream'];
                  debugPrint('     - "${chapterJson['title']}": course=$courseField, stream=$streamField');
                }
              }
            }
            return filteredChapters;
          } else {
            debugPrint('⚠️ Chapters or lessons data missing from API');
          }
        } else {
          debugPrint('⚠️ Data map not found in API response');
        }
      } else {
        debugPrint('❌ API request failed with status ${response.statusCode}');
      }
      
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching chapters for course/stream: $e');
      debugPrint('   Stack trace: $stackTrace');
      return [];
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

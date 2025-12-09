import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/student.dart';
import '../data/course_catalog.dart';
import '../data/joined_courses.dart';
import 'api_client.dart';
import 'course_service.dart';
import '../utils/json_parser.dart';

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

class StudentService {
  // Fetch student by email from students API
  static Future<Student?> fetchStudentByEmail(String email) async {
    try {
      debugPrint('🔄 Fetching student data for: $email');
      final response = await ApiClient.get('/api/students/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final List<dynamic> studentsJson = await JsonParser.parseJsonList(response.body);
        
        // Find student by email (case-insensitive)
        final normalizedEmail = email.toLowerCase().trim();
        for (var studentJson in studentsJson) {
          final studentData = studentJson as Map<String, dynamic>;
          final studentEmail = studentData['email']?.toString()?.toLowerCase()?.trim();
          if (studentEmail == normalizedEmail) {
            debugPrint('✅ Found student: ${studentData['name']} (ID: ${studentData['id']})');
            return _parseStudentFromJson(studentData);
          }
        }
        
        debugPrint('⚠️ Student not found with email: $email');
        return null;
      } else {
        debugPrint('❌ Failed to fetch students: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching student: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }

  // Fetch student by ID from students API
  static Future<Student?> fetchStudentById(int studentId) async {
    try {
      debugPrint('🔄 Fetching student data for ID: $studentId');
      final response = await ApiClient.get('/api/students/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final List<dynamic> studentsJson = await JsonParser.parseJsonList(response.body);
        
        // Find student by ID
        for (var studentJson in studentsJson) {
          final studentData = studentJson as Map<String, dynamic>;
          final id = _asDouble(studentData['id'])?.toInt();
          if (id == studentId) {
            debugPrint('✅ Found student by ID: ${studentData['name']} (Email: ${studentData['email']})');
            return _parseStudentFromJson(studentData);
          }
        }
        
        debugPrint('⚠️ Student not found with ID: $studentId');
        return null;
      } else {
        debugPrint('❌ Failed to fetch students: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching student by ID: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }

  // Fetch student data with course_id and stream_id
  static Future<Map<String, dynamic>?> fetchStudentDataWithCourseStream(String email) async {
    try {
      debugPrint('🔄 Fetching student course/stream data for: $email');
      final response = await ApiClient.get('/api/students/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final List<dynamic> studentsJson = await JsonParser.parseJsonList(response.body);
        
        // Find student by email
        for (var studentJson in studentsJson) {
          final studentData = studentJson as Map<String, dynamic>;
          if (studentData['email'] == email) {
            debugPrint('✅ Found student data with course/stream');
            // Return the full student data including course_id and stream_id
            return studentData;
          }
        }
        
        debugPrint('⚠️ Student not found with email: $email');
        return null;
      } else {
        debugPrint('❌ Failed to fetch student data: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching student course/stream data: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }

  // Fetch student by student_id (e.g. "STD1762865095514341")
  static Future<Student?> fetchStudentByStudentCode(String studentCode) async {
    if (studentCode.trim().isEmpty) {
      debugPrint('⚠️ Empty student code provided, skipping lookup');
      return null;
    }

    try {
      debugPrint('🔄 Fetching student data for student code: $studentCode');
      final response = await ApiClient.get(
        '/api/students/',
        queryParams: {'format': 'json'},
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final List<dynamic> studentsJson = await JsonParser.parseJsonList(response.body);

        for (final studentJson in studentsJson) {
          if (studentJson is! Map<String, dynamic>) continue;

          final rawCode = studentJson['student_id']?.toString();
          if (rawCode != null && rawCode.trim().toLowerCase() == studentCode.trim().toLowerCase()) {
            debugPrint('✅ Found student for code $studentCode: ${studentJson['name']}');
            return _parseStudentFromJson(studentJson);
          }
        }

        debugPrint('⚠️ Student not found with student_id: $studentCode');
        return null;
      } else {
        debugPrint('❌ Failed to fetch students by code: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching student by student code: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Fetch all students (for admin or other purposes)
  static Future<List<Student>> fetchAllStudents() async {
    try {
      final response = await ApiClient.get('/api/students/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final List<dynamic> studentsJson = await JsonParser.parseJsonList(response.body);
        return studentsJson
            .map((json) => _parseStudentFromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching students: $e');
      return [];
    }
  }
  
  // Fetch enrolled courses for a student by email
  static Future<List<JoinedCourse>> fetchEnrolledCourses(String email) async {
    try {
      debugPrint('🔄 Fetching enrolled courses for: $email');
      int? targetStudentId;

      try {
        final student = await fetchStudentByEmail(email);
        targetStudentId = student?.id;
      } catch (e) {
        debugPrint('⚠️ Unable to resolve student ID for $email: $e');
      }
      
      // Try home API endpoint first (has enrollments with chapters/lessons)
      try {
        final homeResponse = await ApiClient.get(
          '/api/home/',
          queryParams: {'format': 'json'},
          includeAuth: false,
        );

        if (homeResponse.statusCode == 200) {
          // Parse JSON in background thread
          final Map<String, dynamic> homeData = await JsonParser.parseJson(homeResponse.body);
          final homeDataMap = homeData['data'];
          if (homeDataMap is Map<String, dynamic>) {
            final enrollments = homeDataMap['enrollments'];
            if (enrollments is List && enrollments.isNotEmpty) {
              debugPrint('✅ Found enrollments in home API');
              return await _parseEnrollmentsFromList(
                enrollments,
                email,
                studentId: targetStudentId,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Home API failed, trying enrollments endpoint: $e');
      }
      
      // Fallback to enrollments endpoint
      final response = await ApiClient.get(
        '/api/enrollments/',
        queryParams: {'format': 'json'},
        includeAuth: false,
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to fetch enrollments: ${response.statusCode}');
        throw Exception('Failed to fetch enrollments: ${response.statusCode}');
      }

      // Parse JSON in background thread
      final Map<String, dynamic> data = await JsonParser.parseJson(response.body);
      final dataMap = data['data'];
      if (dataMap is! Map<String, dynamic>) {
        debugPrint('⚠️ Enrollments response did not contain data map');
        return [];
      }

      final enrollments = dataMap['enrollments'];
      if (enrollments is! List) {
        debugPrint('⚠️ Enrollments list missing in response');
        return [];
      }
      
      return await _parseEnrollmentsFromList(
        enrollments,
        email,
        studentId: targetStudentId,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching enrolled courses: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Helper method to parse enrollments list
  static Future<List<JoinedCourse>> _parseEnrollmentsFromList(
    List enrollments,
    String email, {
    int? studentId,
  }) async {
    final List<JoinedCourse> joinedCourses = [];
    final normalizedEmail = email.toLowerCase().trim();
    
    debugPrint('🔍 Parsing ${enrollments.length} enrollment(s) for email: $email (ID: $studentId)');

    for (final enrollment in enrollments) {
      if (enrollment is! Map<String, dynamic>) continue;

      // Extract student information from enrollment
      final studentData = enrollment['student'];
      String? studentEmail;
      int? enrollmentStudentId;
      
      // Debug: Log raw enrollment structure
      debugPrint('   Raw enrollment keys: ${enrollment.keys.toList()}');
      if (studentData != null) {
        debugPrint('   Student data type: ${studentData.runtimeType}');
        if (studentData is Map<String, dynamic>) {
          debugPrint('   Student data keys: ${studentData.keys.toList()}');
        }
      }
      
      if (studentData is Map<String, dynamic>) {
        studentEmail = studentData['email']?.toString()?.trim();
        enrollmentStudentId = _asDouble(studentData['id'])?.toInt();
        // Also check for nested student data
        if (studentEmail == null) {
          final nestedStudent = studentData['student'];
          if (nestedStudent is Map<String, dynamic>) {
            studentEmail = nestedStudent['email']?.toString()?.trim();
            enrollmentStudentId ??= _asDouble(nestedStudent['id'])?.toInt();
          }
        }
      } else if (studentData is int || studentData is String) {
        // Student data might just be an ID reference
        enrollmentStudentId = _asDouble(studentData)?.toInt();
        debugPrint('   Student data is ID reference: $enrollmentStudentId');
      }
      
      // Fallback to direct fields
      studentEmail ??= enrollment['student_email']?.toString()?.trim();
      enrollmentStudentId ??= _asDouble(enrollment['student_id'])?.toInt();
      
      // If we have student ID but no email, try to fetch student by ID to get email
      if (studentEmail == null && enrollmentStudentId != null) {
        try {
          final student = await fetchStudentById(enrollmentStudentId);
          if (student != null) {
            studentEmail = student.email;
            debugPrint('   ✅ Fetched student email from enrollment student ID $enrollmentStudentId: $studentEmail');
          }
        } catch (e) {
          debugPrint('   ⚠️ Could not fetch student by ID $enrollmentStudentId: $e');
        }
      }
      
      // Debug: Log enrollment details
      debugPrint('   Enrollment: studentEmail=$studentEmail, enrollmentStudentId=$enrollmentStudentId, targetEmail=$normalizedEmail, targetId=$studentId');

      // Match by email first (most reliable)
      bool matches = false;
      if (studentEmail != null && studentEmail.toLowerCase().trim() == normalizedEmail) {
        matches = true;
        debugPrint('   ✅ Matched by email: $studentEmail');
      }
      
      // Match by student ID if email didn't match
      if (!matches && studentId != null && enrollmentStudentId != null && enrollmentStudentId == studentId) {
        matches = true;
        debugPrint('   ✅ Matched by student ID: $enrollmentStudentId');
      }
      
      // If no match, skip this enrollment
      if (!matches) {
        debugPrint('   ⏭️ Skipping enrollment - no match');
        continue;
      }

      final courseJson = enrollment['course'];
      if (courseJson is! Map<String, dynamic>) {
        debugPrint('⚠️ Enrollment missing course data, skipping');
        continue;
      }

      final course = Course.fromJson(courseJson);
      final titleLower = course.title.toLowerCase().trim();
      if (titleLower == 'none' || course.title.isEmpty) {
        debugPrint('ℹ️ Skipping placeholder course in enrollment (id: ${course.id})');
        continue;
      }

      // Parse chapters from enrollment data (includes lessons, videos, materials, MCQs)
      final chaptersJson = enrollment['chapters'] as List<dynamic>?;
      final chapters = chaptersJson != null
          ? chaptersJson
              .whereType<Map<String, dynamic>>()
              .map((chapterJson) {
                try {
                  final chapter = CourseChapter.fromJson(chapterJson);
                  // Debug: Log materials and MCQs found in this chapter
                  for (final lesson in chapter.lessons) {
                    if (lesson.materials.isNotEmpty) {
                      debugPrint('📄 Chapter "${chapter.title}" - Lesson "${lesson.title}": Found ${lesson.materials.length} material(s)');
                    }
                    for (final video in lesson.videos) {
                      if (video.mcqUrl != null && video.mcqUrl!.isNotEmpty) {
                        debugPrint('📝 Chapter "${chapter.title}" - Lesson "${lesson.title}" - Video "${video.name}": Found MCQ');
                      }
                    }
                  }
                  return chapter;
                } catch (e, stackTrace) {
                  debugPrint('⚠️ Error parsing chapter: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Chapter data: $chapterJson');
                  return null;
                }
              })
              .whereType<CourseChapter>()
              .toList()
          : <CourseChapter>[];
      
      if (chapters.isNotEmpty) {
        debugPrint('📚 Parsed ${chapters.length} chapter(s) with lessons, materials, and MCQs');
      }

      final streamData = enrollment['stream'] ?? enrollment['course_stream'];
      int? streamId;
      String? streamName;
      if (streamData is Map<String, dynamic>) {
        streamId = _asDouble(streamData['id'])?.toInt();
        final rawName = streamData['name'] ?? streamData['title'];
        if (rawName != null && rawName.toString().trim().isNotEmpty) {
          streamName = rawName.toString().trim();
        }
      } else if (streamData != null) {
        final rawName = streamData.toString().trim();
        if (rawName.isNotEmpty) {
          streamName = rawName;
        }
      }

      final displayDescription = course.description.isEmpty
          ? 'Description not available.'
          : course.description;

      // Check if enrollment is verified (verified field from backend)
      // Also check is_enrolled for backward compatibility
      final enrolledAt = _parseDate(enrollment['enrolled_at']);
      final verified = enrollment['verified'] != null
          ? (enrollment['verified'] is bool
              ? enrollment['verified'] as bool
              : enrollment['verified'].toString().toLowerCase() == 'true')
          : null;
      
      final isEnrolledField = enrollment['is_enrolled'] != null
          ? (enrollment['is_enrolled'] is bool
              ? enrollment['is_enrolled'] as bool
              : enrollment['is_enrolled'].toString().toLowerCase() == 'true')
          : null;
      
      // Course is enrolled if verified is true, or is_enrolled is true, or enrolled_at exists
      final isEnrolled = verified == true 
          || isEnrolledField == true 
          || (verified == null && isEnrolledField == null && enrolledAt != null);

      final joinedCourse = JoinedCourse(
        courseId: course.id,
        title: course.title,
        color: course.color,
        description: displayDescription,
        rating: course.rating,
        streamId: streamId,
        streamName: streamName,
        whatYoullLearn: course.whatYoullLearn,
        thumbnailUrl: course.thumbnailUrl,
        durationHours: course.durationHours,
        duration: course.duration,
        studentCount: course.studentCount,
        price: course.price,
        lessonsCount: course.lessonsCount,
        chaptersCount: course.chaptersCount,
        topics: course.topics,
        progressPercentage:
            _asDouble(enrollment['progress_percentage']) ?? _asDouble(enrollment['progress']),
        enrolledAt: enrolledAt,
        lastAccessedAt: _parseDate(enrollment['last_accessed_at']),
        chapters: chapters,
        isEnrolled: isEnrolled,
      );

      joinedCourses.add(joinedCourse);
    }

    if (joinedCourses.isEmpty) {
      debugPrint('ℹ️ No enrollments found for $email');
    } else {
      debugPrint('✅ Loaded ${joinedCourses.length} enrollment(s) for $email');
    }

    return joinedCourses;
  }
  
  // Parse student from API JSON
  // API fields: 'name' and 'photo'
  static Student _parseStudentFromJson(Map<String, dynamic> json) {
    return Student.fromJson(json, baseUrl: ApiClient.baseUrl);
  }
  
  // Get full image URL from relative path
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    return '${ApiClient.baseUrl}$relativePath';
  }

  // Fetch unique stream names for a student using their student_id code
  static Future<List<String>> fetchStreamNamesByStudentCode(String studentCode) async {
    final student = await fetchStudentByStudentCode(studentCode);
    if (student == null) {
      return const [];
    }

    final targetStudentId = student.id;
    final targetEmail = student.email.trim().isNotEmpty ? student.email.trim() : null;
    final streamNames = <String>{};

    Future<void> _collectFromEndpoint(String endpoint) async {
      try {
        final response = await ApiClient.get(
          endpoint,
          queryParams: {'format': 'json'},
          includeAuth: false,
        );

        if (response.statusCode != 200) {
          debugPrint('⚠️ Stream lookup failed for $endpoint: ${response.statusCode}');
          return;
        }

        // Parse JSON in background thread
        final decoded = await JsonParser.parseJson(response.body);
        if (decoded is! Map<String, dynamic>) {
          debugPrint('⚠️ Unexpected response shape from $endpoint');
          return;
        }

        final data = decoded['data'];
        if (data is! Map<String, dynamic>) {
          debugPrint('⚠️ Missing data map in $endpoint response');
          return;
        }

        final enrollments = data['enrollments'];
        if (enrollments is! List) {
          debugPrint('ℹ️ No enrollments array in $endpoint response');
          return;
        }

        streamNames.addAll(
          _collectStreamNamesFromEnrollments(
            enrollments,
            targetStudentId: targetStudentId,
            targetEmail: targetEmail,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing $endpoint for student $studentCode: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    }

    // Try home endpoint first (typically includes enrollments)
    await _collectFromEndpoint('/api/home/');

    // Fallback to enrollments endpoint if needed
    if (streamNames.isEmpty) {
      await _collectFromEndpoint('/api/enrollments/');
    }

    if (streamNames.isEmpty) {
      debugPrint('ℹ️ No streams found for student code $studentCode');
    } else {
      debugPrint('✅ Found ${streamNames.length} stream(s) for student code $studentCode');
    }

    return streamNames.toList();
  }

  static List<String> _collectStreamNamesFromEnrollments(
    List<dynamic> enrollments, {
    int? targetStudentId,
    String? targetEmail,
  }) {
    final streamNames = <String>{};

    for (final enrollment in enrollments) {
      if (enrollment is! Map<String, dynamic>) continue;

      bool matchesTarget = false;

      if (targetStudentId != null) {
        final rawId = _asDouble(enrollment['student_id'])?.toInt();
        if (rawId != null && rawId == targetStudentId) {
          matchesTarget = true;
        }
      }

      if (!matchesTarget && targetEmail != null) {
        final studentData = enrollment['student'];
        String? enrollmentEmail;
        if (studentData is Map<String, dynamic>) {
          enrollmentEmail = studentData['email']?.toString();
        }
        enrollmentEmail ??= enrollment['student_email']?.toString();

        if (enrollmentEmail != null &&
            enrollmentEmail.toLowerCase().trim() == targetEmail.toLowerCase().trim()) {
          matchesTarget = true;
        }
      }

      if (!matchesTarget && targetStudentId != null) {
        final nestedStudent = enrollment['student'];
        if (nestedStudent is Map<String, dynamic>) {
          final nestedId = _asDouble(nestedStudent['id'])?.toInt();
          if (nestedId != null && nestedId == targetStudentId) {
            matchesTarget = true;
          }
        }
      }

      if (!matchesTarget) {
        continue;
      }

      final streamData = enrollment['stream'] ?? enrollment['course_stream'];
      String? streamName;

      if (streamData is Map<String, dynamic>) {
        final rawName = streamData['name'] ?? streamData['title'];
        if (rawName != null && rawName.toString().trim().isNotEmpty) {
          streamName = rawName.toString().trim();
        }
      } else if (streamData != null) {
        final rawName = streamData.toString().trim();
        if (rawName.isNotEmpty) {
          streamName = rawName;
        }
      }

      if (streamName != null && streamName.isNotEmpty) {
        streamNames.add(streamName);
      }
    }

    return streamNames.toList();
  }
}


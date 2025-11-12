import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/student.dart';
import '../data/course_catalog.dart';
import '../data/joined_courses.dart';
import 'api_client.dart';
import 'course_service.dart';

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
        final List<dynamic> studentsJson = json.decode(response.body);
        
        // Find student by email
        for (var studentJson in studentsJson) {
          final studentData = studentJson as Map<String, dynamic>;
          if (studentData['email'] == email) {
            debugPrint('✅ Found student: ${studentData['name']}');
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
        final List<dynamic> studentsJson = json.decode(response.body);

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
        final List<dynamic> studentsJson = json.decode(response.body);
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
          final Map<String, dynamic> homeData = json.decode(homeResponse.body);
          final homeDataMap = homeData['data'];
          if (homeDataMap is Map<String, dynamic>) {
            final enrollments = homeDataMap['enrollments'];
            if (enrollments is List && enrollments.isNotEmpty) {
              debugPrint('✅ Found enrollments in home API');
              return _parseEnrollmentsFromList(
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

      final Map<String, dynamic> data = json.decode(response.body);
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
      
      return _parseEnrollmentsFromList(
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
  static List<JoinedCourse> _parseEnrollmentsFromList(
    List enrollments,
    String email, {
    int? studentId,
  }) {
    final List<JoinedCourse> joinedCourses = [];

    for (final enrollment in enrollments) {
      if (enrollment is! Map<String, dynamic>) continue;

      // For home API, enrollments don't have student filter - show all enrollments
      // For enrollments API, filter by student email
      final studentData = enrollment['student'];
      final studentEmail = (studentData is Map<String, dynamic>)
          ? studentData['email']?.toString()
          : enrollment['student_email']?.toString();

      // If student_email is provided, filter by it; otherwise show all (home API case)
      if (studentEmail != null && studentEmail.toLowerCase() != email.toLowerCase()) {
        continue;
      }

      if (studentEmail == null && studentId != null) {
        final rawStudentId = _asDouble(enrollment['student_id'])?.toInt();
        final nestedStudentId = studentData is Map<String, dynamic>
            ? _asDouble(studentData['id'])?.toInt()
            : null;
        final matchesId = (rawStudentId != null && rawStudentId == studentId) ||
            (nestedStudentId != null && nestedStudentId == studentId);

        if (!matchesId) {
          continue;
        }
      }

      if (studentEmail != null &&
          studentEmail.toLowerCase() == email.toLowerCase() &&
          studentId != null) {
        final rawStudentId = _asDouble(enrollment['student_id'])?.toInt();
        final nestedStudentId = studentData is Map<String, dynamic>
            ? _asDouble(studentData['id'])?.toInt()
            : null;

        if (rawStudentId != null && rawStudentId != studentId && nestedStudentId != studentId) {
          continue;
        }
      }

      if (studentEmail == null && studentId == null) {
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

      final chaptersJson = enrollment['chapters'];
      final chapters = chaptersJson is List
          ? chaptersJson
              .whereType<Map<String, dynamic>>()
              .map(CourseChapter.fromJson)
              .toList()
          : const <CourseChapter>[];

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
        enrolledAt: _parseDate(enrollment['enrolled_at']),
        lastAccessedAt: _parseDate(enrollment['last_accessed_at']),
        chapters: chapters,
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

        final decoded = json.decode(response.body);
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


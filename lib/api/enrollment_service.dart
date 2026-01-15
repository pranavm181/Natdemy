import 'package:flutter/material.dart';
import '../data/joined_courses.dart';
import '../data/course_catalog.dart';
import 'home_service.dart';
import '../utils/json_parser.dart';

class EnrollmentService {
  // Fetch enrollments via HomeService (deduplicated)
  static Future<List<JoinedCourse>> fetchEnrollments() async {
    try {
      debugPrint('🔄 Fetching enrollments from HomeService...');
      final data = await HomeService.fetchHomeData();
      
      if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        
        if (dataMap.containsKey('enrollments') && dataMap['enrollments'] is List) {
          final List<dynamic> enrollmentsJson = dataMap['enrollments'] as List<dynamic>;
          debugPrint('📚 Found ${enrollmentsJson.length} enrollments in HomeService response');
          
          final enrollments = <JoinedCourse>[];
          for (var i = 0; i < enrollmentsJson.length; i++) {
            try {
              final enrollmentJson = enrollmentsJson[i] as Map<String, dynamic>;
              final courseJson = enrollmentJson['course'] as Map<String, dynamic>?;
              if (courseJson == null) continue;
              
              final course = Course.fromJson(courseJson);
              final chaptersJson = enrollmentJson['chapters'] as List<dynamic>?;
              final chapters = chaptersJson != null
                  ? chaptersJson
                      .whereType<Map<String, dynamic>>()
                      .map((chapterJson) => CourseChapter.fromJson(chapterJson))
                      .toList()
                  : <CourseChapter>[];
              
              final progressPercentage = enrollmentJson['progress_percentage'] != null
                  ? double.tryParse(enrollmentJson['progress_percentage'].toString())
                  : null;
              
              final enrolledAt = enrollmentJson['enrolled_at'] != null
                  ? DateTime.tryParse(enrollmentJson['enrolled_at'].toString())
                  : null;
              
              final lastAccessedAt = enrollmentJson['last_accessed_at'] != null
                  ? DateTime.tryParse(enrollmentJson['last_accessed_at'].toString())
                  : null;
              
              enrollments.add(JoinedCourse(
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
                progressPercentage: progressPercentage,
                enrolledAt: enrolledAt,
                lastAccessedAt: lastAccessedAt,
                chapters: chapters,
              ));
            } catch (e) {
              debugPrint('⚠️ Error parsing enrollment at index $i: $e');
            }
          }
          return enrollments;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Enrollment fetch failed: $e');
      return [];
    }
  }
}

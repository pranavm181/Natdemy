import 'package:flutter/material.dart';
import 'dart:convert';
import '../data/joined_courses.dart';
import '../data/course_catalog.dart';
import 'api_client.dart';

class EnrollmentService {
  // Fetch enrollments from home API
  static Future<List<JoinedCourse>> fetchEnrollments() async {
    try {
      debugPrint('🔄 Fetching enrollments from API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      debugPrint('📡 Enrollments API Response Status: ${response.statusCode}');
      
      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ Enrollments API returned HTML error page (status: ${response.statusCode})');
        return [];
      }
      
      if (response.statusCode == 200) {
        try {
          // Parse JSON in background thread to avoid blocking UI
          final Map<String, dynamic> data = await JsonParser.parseJson(response.body);
          debugPrint('✅ JSON decoded successfully');
          
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            
            if (dataMap.containsKey('enrollments') && dataMap['enrollments'] is List) {
              final List<dynamic> enrollmentsJson = dataMap['enrollments'] as List<dynamic>;
              debugPrint('📚 Found ${enrollmentsJson.length} enrollments in API response');
              
              final enrollments = <JoinedCourse>[];
              
              for (var i = 0; i < enrollmentsJson.length; i++) {
                try {
                  final enrollmentJson = enrollmentsJson[i] as Map<String, dynamic>;
                  
                  // Extract course data
                  final courseJson = enrollmentJson['course'] as Map<String, dynamic>?;
                  if (courseJson == null) {
                    debugPrint('⚠️ Enrollment $i has no course data, skipping');
                    continue;
                  }
                  
                  // Parse course
                  final course = Course.fromJson(courseJson);
                  
                  // Extract chapters
                  final chaptersJson = enrollmentJson['chapters'] as List<dynamic>?;
                  final chapters = chaptersJson != null
                      ? chaptersJson
                          .whereType<Map<String, dynamic>>()
                          .map((chapterJson) => CourseChapter.fromJson(chapterJson))
                          .toList()
                      : <CourseChapter>[];
                  
                  // Parse enrollment metadata
                  final progressPercentage = enrollmentJson['progress_percentage'] != null
                      ? double.tryParse(enrollmentJson['progress_percentage'].toString())
                      : null;
                  
                  final enrolledAt = enrollmentJson['enrolled_at'] != null
                      ? DateTime.tryParse(enrollmentJson['enrolled_at'].toString())
                      : null;
                  
                  final lastAccessedAt = enrollmentJson['last_accessed_at'] != null
                      ? DateTime.tryParse(enrollmentJson['last_accessed_at'].toString())
                      : null;
                  
                  // Create JoinedCourse from enrollment
                  final joinedCourse = JoinedCourse(
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
                  );
                  
                  enrollments.add(joinedCourse);
                  debugPrint('✅ Added enrollment: ${course.title} (${chapters.length} chapters, ${chapters.fold<int>(0, (sum, ch) => sum + ch.lessons.length)} lessons)');
                } catch (e, stackTrace) {
                  debugPrint('❌ Error parsing enrollment at index $i: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Enrollment data: ${enrollmentsJson[i]}');
                }
              }
              
              debugPrint('✅ Successfully fetched ${enrollments.length} enrollments from API');
              return enrollments;
            } else {
              debugPrint('⚠️ "enrollments" key not found or not a List in data');
              debugPrint('   Available keys: ${dataMap.keys.toList()}');
            }
          } else {
            debugPrint('⚠️ "data" key not found or not a Map');
            debugPrint('   Top-level keys: ${data.keys.toList()}');
          }
          
          debugPrint('⚠️ No enrollments found in API response');
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for enrollments: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        debugPrint('❌ Enrollments API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching enrollments: $e');
      debugPrint('   Stack trace: $stackTrace');
      return [];
    }
  }
}


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/course_catalog.dart';
import '../data/course_stream.dart';
import 'api_client.dart';

class CourseService {
  static List<CourseStream> _cachedStreams = [];

  static List<CourseStream> get cachedStreams => List.unmodifiable(_cachedStreams);

  // Fetch all courses from home API
  static Future<List<Course>> fetchCourses() async {
    try {
      debugPrint('🔄 Fetching courses from API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      debugPrint('📡 API Response Status: ${response.statusCode}');
      
      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ API returned HTML error page (status: ${response.statusCode}) - using fallback courses');
        throw Exception('Server error: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          debugPrint('✅ JSON decoded successfully');
          debugPrint('📦 Response keys: ${data.keys.toList()}');
          
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            debugPrint('📦 Data keys: ${dataMap.keys.toList()}');

            // Parse streams if available
            if (dataMap.containsKey('streams') && dataMap['streams'] is List) {
              final streamsJson = dataMap['streams'] as List;
              _cachedStreams = streamsJson
                  .whereType<Map<String, dynamic>>()
                  .map(CourseStream.fromJson)
                  .toList();
              debugPrint('🌊 Loaded ${_cachedStreams.length} stream(s) from API');
            } else {
              _cachedStreams = [];
              debugPrint('ℹ️ No streams found in API response');
            }
            
            if (dataMap.containsKey('courses') && dataMap['courses'] is List) {
              final List<dynamic> coursesJson = dataMap['courses'] as List<dynamic>;
              debugPrint('📚 Found ${coursesJson.length} courses in API response');
              
              final courses = <Course>[];
              
              for (var i = 0; i < coursesJson.length; i++) {
                try {
                  final courseJson = coursesJson[i] as Map<String, dynamic>;
                  final rawTitle = courseJson['title']?.toString() ?? '';
                  debugPrint('📖 Parsing course $i: "$rawTitle" (id: ${courseJson['id']})');
                  
                  final course = Course.fromJson(courseJson);
                  
                  // Skip placeholder/empty courses returned by API
                  final titleLower = course.title.toLowerCase().trim();
                  if (titleLower == 'none' || course.title.isEmpty) {
                    debugPrint('ℹ️ Skipping placeholder course (id: ${course.id})');
                    continue;
                  }
                  
                  courses.add(course);
                  debugPrint('✅ Added course: "${course.title}" (ID: ${course.id})');
                } catch (e, stackTrace) {
                  debugPrint('❌ Error parsing course at index $i: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Course data: ${coursesJson[i]}');
                }
              }
              
              debugPrint('✅ Successfully fetched ${courses.length} courses from API');
              return courses;
            } else {
              debugPrint('⚠️ "courses" key not found or not a List in data');
              debugPrint('   Available keys: ${dataMap.keys.toList()}');
            }
          } else {
            debugPrint('⚠️ "data" key not found or not a Map');
            debugPrint('   Top-level keys: ${data.keys.toList()}');
            _cachedStreams = [];
          }
          
          debugPrint('⚠️ No courses found in API response');
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          rethrow;
        }
      } else {
        // Handle non-200 status codes
        debugPrint('❌ API request failed: ${response.statusCode}');
        if (!isHtml) {
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        }
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching courses: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Fetch course by ID
  static Future<Course?> fetchCourseById(int courseId) async {
    try {
      final response = await ApiClient.get('/api/courses/$courseId/', includeAuth: false);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> courseJson = json.decode(response.body);
        return Course.fromJson(courseJson);
      } else {
        debugPrint('❌ Failed to fetch course: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching course: $e');
      return null;
    }
  }
  
  // Get full image URL from relative path
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty || relativePath == '/media/none') {
      return ''; // Return empty string if no valid image
    }
    
    // If already a full URL, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Construct full URL
    return '${ApiClient.baseUrl}$relativePath';
  }
}


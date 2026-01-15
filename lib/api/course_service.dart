import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/course_catalog.dart';
import '../data/course_stream.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'home_service.dart';

class CourseService {
  static List<CourseStream> _cachedStreams = [];
  static List<Course>? _cachedCourses;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24); // Cache for 24 hours
  static const String _cacheKeyCourses = 'cached_courses';
  static const String _cacheKeyStreams = 'cached_streams';
  static const String _cacheKeyTime = 'courses_cache_time';

  static List<CourseStream> get cachedStreams => List.unmodifiable(_cachedStreams);

  // Load courses from persistent cache
  static Future<List<Course>?> _loadCoursesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_cacheKeyCourses);
      final cacheTimeStr = prefs.getString(_cacheKeyTime);
      
      if (coursesJson != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final cacheAge = DateTime.now().difference(cacheTime);
        
        if (cacheAge < _cacheDuration) {
          final List<dynamic> decoded = json.decode(coursesJson);
          final courses = decoded
              .map((json) => Course.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _cachedCourses = courses;
          _cacheTime = cacheTime;
          
          debugPrint('📦 Loaded ${courses.length} courses from persistent cache (age: ${cacheAge.inMinutes}m)');
          return courses;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading courses from cache: $e');
    }
    return null;
  }

  // Save courses to persistent cache
  static Future<void> _saveCoursesToCache(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = json.encode(courses.map((c) => c.toJson()).toList());
      await prefs.setString(_cacheKeyCourses, coursesJson);
      await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());
      debugPrint('💾 Saved ${courses.length} courses to persistent cache');
    } catch (e) {
      debugPrint('⚠️ Error saving courses to cache: $e');
    }
  }

  // Load streams from persistent cache
  static Future<void> _loadStreamsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamsJson = prefs.getString(_cacheKeyStreams);
      
      if (streamsJson != null) {
        final List<dynamic> decoded = json.decode(streamsJson);
        _cachedStreams = decoded
            .map((json) => CourseStream.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('🌊 Loaded ${_cachedStreams.length} streams from persistent cache');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading streams from cache: $e');
    }
  }

  // Save streams to persistent cache
  static Future<void> _saveStreamsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamsData = _cachedStreams.map((s) {
        final map = <String, dynamic>{
          'id': s.id,
          'name': s.name,
        };
        if (s.courseId != null) {
          map['course_id'] = s.courseId;
        }
        if (s.course != null) {
          map['course'] = s.course!.toJson();
        }
        return map;
      }).toList();
      final streamsJson = json.encode(streamsData);
      await prefs.setString(_cacheKeyStreams, streamsJson);
      debugPrint('💾 Saved ${_cachedStreams.length} streams to persistent cache');
    } catch (e) {
      debugPrint('⚠️ Error saving streams to cache: $e');
    }
  }

  // Fetch all courses from home API (with persistent caching)
  static Future<List<Course>> fetchCourses({bool forceRefresh = false}) async {
    // Try to load from persistent cache first (if not forcing refresh)
    if (!forceRefresh) {
      // Check in-memory cache first
      if (_cachedCourses != null && _cacheTime != null) {
        final cacheAge = DateTime.now().difference(_cacheTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('📦 Using in-memory cached courses (age: ${cacheAge.inMinutes}m)');
          return _cachedCourses!;
        }
      }
      
      // Try persistent cache
      final cachedCourses = await _loadCoursesFromCache();
      if (cachedCourses != null) {
        // Also load streams from cache
        await _loadStreamsFromCache();
        return cachedCourses;
      }
    }
    try {
      debugPrint('🔄 Fetching courses from HomeService...');
      final data = await HomeService.fetchHomeData(forceRefresh: forceRefresh);
      
      if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;

        // Parse streams if available
        if (dataMap.containsKey('streams') && dataMap['streams'] is List) {
          final streamsJson = dataMap['streams'] as List;
          _cachedStreams = streamsJson
              .whereType<Map<String, dynamic>>()
              .map((streamJson) {
                try {
                  return CourseStream.fromJson(streamJson);
                } catch (e) {
                  debugPrint('⚠️ Error parsing stream: $e');
                  return null;
                }
              })
              .whereType<CourseStream>()
              .toList();
          debugPrint('🌊 Loaded ${_cachedStreams.length} stream(s) from HomeService');
        } else {
          _cachedStreams = [];
          debugPrint('ℹ️ No streams found in HomeService response');
        }
        
        if (dataMap.containsKey('courses') && dataMap['courses'] is List) {
          final List<dynamic> coursesJson = dataMap['courses'] as List<dynamic>;
          debugPrint('📚 Found ${coursesJson.length} courses in HomeService response');
          
          final courses = <Course>[];
          for (var json in coursesJson) {
            try {
              final course = Course.fromJson(json as Map<String, dynamic>);
              // Skip placeholder/empty courses
              if (course.title.isNotEmpty && course.title.toLowerCase() != 'none') {
                courses.add(course);
                debugPrint('✅ Added course: "${course.title}" (ID: ${course.id})');
              } else {
                debugPrint('ℹ️ Skipping placeholder course (id: ${course.id})');
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing course: $e');
            }
          }
          debugPrint('✅ Successfully processed ${courses.length} courses from HomeService');
          
          // Cache results
          _cachedCourses = courses;
          _cacheTime = DateTime.now();
          await _saveCoursesToCache(courses);
          await _saveStreamsToCache();
          
          return courses;
        } else {
          debugPrint('⚠️ "courses" key not found or not a List in HomeService data');
          debugPrint('   Available keys: ${dataMap.keys.toList()}');
        }
      } else {
        debugPrint('⚠️ "data" key not found or not a Map in HomeService response');
        debugPrint('   Top-level keys: ${data.keys.toList()}');
        _cachedStreams = [];
      }
      debugPrint('⚠️ No courses found in HomeService response');
      return _cachedCourses ?? []; // Return cached courses if available, even if HomeService failed to provide new ones
    } catch (e) {
      debugPrint('❌ Course fetch failed: $e');
      // Return cached courses if available, even on error
      if (_cachedCourses != null) {
        debugPrint('📦 Returning cached courses (error occurred during HomeService fetch)');
        return _cachedCourses!;
      }
      return [];
    }
  }
  
  // Fetch course by ID
  static Future<Course?> fetchCourseById(int courseId) async {
    try {
      final response = await ApiClient.get('/api/courses/$courseId/', includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final Map<String, dynamic> courseJson = await JsonParser.parseJson(response.body);
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
  
  // Clear course cache (useful for force refresh)
  static Future<void> clearCache() async {
    _cachedCourses = null;
    _cacheTime = null;
    _cachedStreams = [];
    
    // Clear persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyCourses);
      await prefs.remove(_cacheKeyStreams);
      await prefs.remove(_cacheKeyTime);
      debugPrint('🗑️ Cleared persistent course cache');
    } catch (e) {
      debugPrint('⚠️ Error clearing persistent cache: $e');
    }
  }
  
  // Initialize cache on app start (load from persistent storage)
  static Future<void> initializeCache() async {
    await _loadCoursesFromCache();
    await _loadStreamsFromCache();
  }
}


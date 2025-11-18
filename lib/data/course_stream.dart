import 'package:flutter/material.dart';
import 'course_catalog.dart';
import 'joined_courses.dart';

class CourseStream {
  const CourseStream({
    required this.id,
    required this.name,
    this.course,
    this.courseId,
    this.chapters = const [],
  });

  final int id;
  final String name;
  final Course? course;
  final int? courseId;
  final List<CourseChapter> chapters;

  int? get resolvedCourseId => course?.id ?? courseId;
  String get courseTitle => course?.title ?? '';

  factory CourseStream.fromJson(Map<String, dynamic> json) {
    final courseJson = json['course'];
    final chaptersJson = json['chapters'];
    int? parsedCourseId;
    
    // Try multiple field names for course_id
    var rawCourseId = json['course_id'] ?? 
                     json['courseId'] ?? 
                     json['course'];
    
    // If course is an object, extract its ID
    if (rawCourseId is Map<String, dynamic>) {
      rawCourseId = rawCourseId['id'] ?? rawCourseId['course_id'];
    }
    
    // Parse course_id from various types
    if (rawCourseId is int) {
      parsedCourseId = rawCourseId;
    } else if (rawCourseId is String) {
      parsedCourseId = int.tryParse(rawCourseId);
    } else if (rawCourseId is double) {
      parsedCourseId = rawCourseId.toInt();
    }
    
    // Also try to get course ID from nested course object if available
    Course? parsedCourse;
    if (courseJson is Map<String, dynamic>) {
      try {
        parsedCourse = Course.fromJson(courseJson);
        // If we don't have courseId yet, try to get it from the course object
        if (parsedCourseId == null && parsedCourse.id != null) {
          parsedCourseId = parsedCourse.id;
        }
      } catch (e) {
        // Silently handle parsing errors
      }
    }
    
    return CourseStream(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Stream',
      course: parsedCourse,
      courseId: parsedCourseId,
      chapters: chaptersJson is List
          ? chaptersJson
              .whereType<Map<String, dynamic>>()
              .map(CourseChapter.fromJson)
              .toList()
          : const [],
    );
  }
}


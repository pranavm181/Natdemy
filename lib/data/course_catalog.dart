import 'package:flutter/material.dart';
import 'dart:convert';

class Course {
  const Course({
    this.id,
    required this.title,
    required this.color,
    required this.description,
    required this.rating,
    this.whatYoullLearn = const [],
    this.thumbnailUrl,
    this.durationHours,
    this.duration,
    this.studentCount,
    this.price,
    this.lessonsCount,
    this.chaptersCount,
    this.topics,
  });
  
  final int? id; // Course ID from API
  final String title;
  final Color color;
  final String description;
  final double rating;
  final List<String> whatYoullLearn; // Learning points for "What you'll learn" section
  final String? thumbnailUrl; // Course image URL
  final int? durationHours; // Course duration in hours
  final int? duration; // Course duration (alternative field from API)
  final int? studentCount; // Number of enrolled students
  final double? price; // Course price (0 for free)
  final int? lessonsCount; // Total number of lessons
  final int? chaptersCount; // Total number of chapters
  final dynamic topics; // Course topics (can be string, list, or null)
  
  // Convert from JSON (API response)
  factory Course.fromJson(Map<String, dynamic> json) {
    // Parse what_youll_learn - can be null, string, or list
    List<String> whatYoullLearnList = [];
    if (json['what_youll_learn'] != null) {
      if (json['what_youll_learn'] is List) {
        whatYoullLearnList = List<String>.from(
          (json['what_youll_learn'] as List).map((item) => item.toString())
        );
      } else if (json['what_youll_learn'] is String) {
        // If it's a string, try to parse it
        final str = json['what_youll_learn'] as String;
        if (str.isNotEmpty) {
          whatYoullLearnList = [str];
        }
      }
    }
    
    // Parse topics - can be null, string, list, or other types
    dynamic topics;
    if (json['topics'] != null) {
      topics = json['topics'];
    }
    
    // Parse duration - can be null or number
    int? duration;
    if (json['duration'] != null) {
      if (json['duration'] is num) {
        duration = (json['duration'] as num).toInt();
      } else if (json['duration'] is String) {
        duration = int.tryParse(json['duration'] as String);
      }
    }
    
    // Parse thumbnail URL - handle relative paths
    String? thumbnailUrl;
    if (json['thumbnail'] != null && json['thumbnail'] != '/media/none') {
      final thumb = json['thumbnail'] as String;
      if (thumb.isNotEmpty && thumb != '/media/none') {
        // If it's a relative path, it will be converted to full URL in service
        thumbnailUrl = thumb;
      }
    }
    
    // Parse price - API returns as string "0.00"
    double? price;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price'] as String);
      } else if (json['price'] is num) {
        price = (json['price'] as num).toDouble();
      }
    }
    
    // Generate color from course ID or title hash for consistency
    Color courseColor;
    if (json['id'] != null) {
      // Use ID to generate consistent color
      final id = json['id'] as int;
      final colors = [
        const Color(0xFFFF6B6B), // Red
        const Color(0xFF4ECDC4), // Teal
        const Color(0xFFFFC300), // Yellow
        const Color(0xFF7FB800), // Green
        const Color(0xFF95A5A6), // Gray
        const Color(0xFF3498DB), // Blue
        const Color(0xFF9B59B6), // Purple
        const Color(0xFFE67E22), // Orange
      ];
      courseColor = colors[id % colors.length];
    } else {
      courseColor = const Color(0xFFFF6B6B); // Default color
    }
    
    // Handle both students_count and student_count fields
    int? studentCount;
    if (json['students_count'] != null) {
      studentCount = json['students_count'] as int?;
    } else if (json['student_count'] != null) {
      studentCount = json['student_count'] as int?;
    }
    
    return Course(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Untitled Course',
      color: courseColor,
      description: json['description'] as String? ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      whatYoullLearn: whatYoullLearnList,
      thumbnailUrl: thumbnailUrl,
      durationHours: json['duration_hours'] as int?,
      duration: duration,
      studentCount: studentCount,
      price: price ?? 0.0,
      lessonsCount: json['lessons_count'] as int?,
      chaptersCount: json['chapters_count'] as int?,
      topics: topics,
    );
  }
  
  // Convert to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
      'description': description,
      'rating': rating,
      'what_youll_learn': whatYoullLearn,
      'thumbnail': thumbnailUrl,
      'duration_hours': durationHours,
      'duration': duration,
      'students_count': studentCount,
      'student_count': studentCount,
      'price': price?.toString() ?? '0.00',
      'lessons_count': lessonsCount,
      'chapters_count': chaptersCount,
      'topics': topics,
    };
  }
}

const List<Course> courseCatalog = [
  Course(
    title: 'Flutter Basics',
    color: Color(0xFFFF6B6B),
    description: 'Build beautiful cross-platform apps with Flutter. Learn widgets, layouts, state, and navigation.',
    rating: 4.7,
  ),
  Course(
    title: 'Data Structures',
    color: Color(0xFF4ECDC4),
    description: 'Master arrays, lists, stacks, queues, trees and graphs with practical examples.',
    rating: 4.6,
  ),
  Course(
    title: 'Algebra Refresher',
    color: Color(0xFFFFC300),
    description: 'Strengthen your foundations: equations, functions, and problem solving strategies.',
    rating: 4.5,
  ),
  Course(
    title: 'Biology Insights',
    color: Color(0xFF7FB800),
    description: 'Explore cellular biology, genetics, and ecosystems with engaging visuals.',
    rating: 4.4,
  ),
];




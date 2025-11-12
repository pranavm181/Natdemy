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
    final rawCourseId = json['course_id'];
    if (rawCourseId is int) {
      parsedCourseId = rawCourseId;
    } else if (rawCourseId is String) {
      parsedCourseId = int.tryParse(rawCourseId);
    }
    return CourseStream(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Stream',
      course: courseJson is Map<String, dynamic> ? Course.fromJson(courseJson) : null,
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


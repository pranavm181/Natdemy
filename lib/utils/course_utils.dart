import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Utility class for course-related helper functions
class CourseUtils {
  CourseUtils._();

  /// Get the appropriate icon for a course based on its title
  static IconData getCourseIcon(String courseTitle) {
    final title = courseTitle.toLowerCase();
    if (title.contains('flutter')) {
      return FontAwesomeIcons.laptopCode; // Flutter/Development icon
    } else if (title.contains('data') || title.contains('structure')) {
      return FontAwesomeIcons.database; // Data icon
    } else if (title.contains('algebra') || title.contains('math')) {
      return FontAwesomeIcons.calculator; // Algebra/Math icon
    } else if (title.contains('biology') || title.contains('bio')) {
      return Icons.science;
    } else if (title.contains('chemistry')) {
      return Icons.science_outlined;
    } else if (title.contains('physics')) {
      return Icons.bolt;
    } else if (title.contains('history')) {
      return Icons.history_edu;
    } else if (title.contains('english') || title.contains('language')) {
      return Icons.menu_book;
    } else if (title.contains('computer') || title.contains('programming')) {
      return Icons.computer;
    } else if (title.contains('design')) {
      return Icons.palette;
    } else {
      return Icons.school;
    }
  }
}



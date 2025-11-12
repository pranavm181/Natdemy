import 'package:flutter/material.dart';

/// Course material model for API data
class CourseMaterial {
  const CourseMaterial({
    this.id,
    this.courseId,
    required this.name,
    required this.url,
    this.sizeBytes,
    this.sizeLabel,
    this.fileType,
    this.uploadedAt,
  });

  final String? id; // Material ID from API
  final String? courseId; // Course ID this material belongs to
  final String name; // Material name/title
  final String url; // Direct download/view URL
  final int? sizeBytes; // File size in bytes
  final String? sizeLabel; // Human-readable size (e.g., "1.2 MB")
  final String? fileType; // File type (usually "pdf")
  final DateTime? uploadedAt; // Upload date

  // Factory method to create CourseMaterial from API JSON
  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    // Extract course ID from nested course object or direct course_id field
    String? courseId;
    if (json.containsKey('course') && json['course'] is Map) {
      final courseObj = json['course'] as Map<String, dynamic>;
      courseId = courseObj['id']?.toString();
    } else if (json.containsKey('course_id')) {
      courseId = json['course_id']?.toString();
    }
    
    // Parse size_bytes (can be string or int)
    int? sizeBytes;
    if (json['size_bytes'] != null) {
      if (json['size_bytes'] is int) {
        sizeBytes = json['size_bytes'] as int;
      } else if (json['size_bytes'] is String) {
        sizeBytes = int.tryParse(json['size_bytes'] as String);
      }
    }
    
    // Parse uploaded_at date
    DateTime? uploadedAt;
    if (json['uploaded_at'] != null) {
      try {
        uploadedAt = DateTime.parse(json['uploaded_at'] as String);
      } catch (e) {
        debugPrint('Error parsing uploaded_at: $e');
      }
    }

    // Generate size label if not provided
    String? sizeLabel = json['size_label'] as String?;
    if (sizeLabel == null && sizeBytes != null) {
      if (sizeBytes < 1024) {
        sizeLabel = '$sizeBytes B';
      } else if (sizeBytes < 1024 * 1024) {
        sizeLabel = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeLabel = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    // Get full URL - convert relative path to full URL if needed
    String materialUrl = json['url'] as String? ?? '';
    if (materialUrl.isNotEmpty && 
        !materialUrl.startsWith('http://') && 
        !materialUrl.startsWith('https://')) {
      // Relative path - will be converted to full URL in service
      materialUrl = materialUrl;
    }

    return CourseMaterial(
      id: json['id']?.toString(),
      courseId: courseId,
      name: json['name'] as String? ?? 'Untitled Material',
      url: materialUrl,
      sizeBytes: sizeBytes,
      sizeLabel: sizeLabel,
      fileType: json['file_type'] as String? ?? 'pdf',
      uploadedAt: uploadedAt,
    );
  }

  // Convert CourseMaterial to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'url': url,
      'size_bytes': sizeBytes,
      'size_label': sizeLabel,
      'file_type': fileType,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}


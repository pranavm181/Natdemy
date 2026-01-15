import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/material.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'home_service.dart';

class MaterialService {
  // Fetch materials via HomeService (deduplicated)
  static Future<List<CourseMaterial>> fetchMaterials() async {
    try {
      debugPrint('🔄 Fetching materials from HomeService...');
      final data = await HomeService.fetchHomeData();
      
      if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        
        if (dataMap.containsKey('materials') && dataMap['materials'] is List) {
          final List<dynamic> materialsJson = dataMap['materials'] as List<dynamic>;
          debugPrint('📄 Found ${materialsJson.length} materials in HomeService response');
          
          final materials = <CourseMaterial>[];
          for (var i = 0; i < materialsJson.length; i++) {
            try {
              final materialJson = materialsJson[i] as Map<String, dynamic>;
              
              String? courseId;
              if (materialJson.containsKey('course') && materialJson['course'] is Map) {
                final courseObj = materialJson['course'] as Map<String, dynamic>;
                courseId = courseObj['id']?.toString();
              } else if (materialJson.containsKey('course_id')) {
                courseId = materialJson['course_id']?.toString();
              }
              
              int? sizeBytes;
              if (materialJson['size_bytes'] != null) {
                if (materialJson['size_bytes'] is int) {
                  sizeBytes = materialJson['size_bytes'] as int;
                } else if (materialJson['size_bytes'] is String) {
                  sizeBytes = int.tryParse(materialJson['size_bytes'] as String);
                }
              }
              
              DateTime? uploadedAt;
              if (materialJson['uploaded_at'] != null) {
                try {
                  uploadedAt = DateTime.parse(materialJson['uploaded_at'] as String);
                } catch (e) {}
              }
              
              String? sizeLabel = materialJson['size_label'] as String?;
              if (sizeLabel == null && sizeBytes != null) {
                if (sizeBytes < 1024) {
                  sizeLabel = '$sizeBytes B';
                } else if (sizeBytes < 1024 * 1024) {
                  sizeLabel = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
                } else {
                  sizeLabel = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                }
              }
              
              String materialUrl = materialJson['url'] as String? ?? 
                                 materialJson['file'] as String? ?? 
                                 materialJson['attachment'] as String? ?? 
                                 materialJson['file_url'] as String? ?? 
                                 '';
              
              if (materialUrl.isNotEmpty && 
                  !materialUrl.startsWith('http://') && 
                  !materialUrl.startsWith('https://')) {
                materialUrl = '${ApiClient.baseUrl}${materialUrl.startsWith('/') ? materialUrl : '/$materialUrl'}';
              }
              
              materials.add(CourseMaterial(
                id: materialJson['id']?.toString(),
                courseId: courseId,
                name: materialJson['name'] as String? ?? 'Untitled Material',
                url: materialUrl,
                sizeBytes: sizeBytes,
                sizeLabel: sizeLabel,
                fileType: materialJson['file_type'] as String? ?? 'pdf',
                uploadedAt: uploadedAt,
              ));
            } catch (e) {
              debugPrint('⚠️ Error parsing material: $e');
            }
          }
          return materials;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Material fetch failed: $e');
      return [];
    }
  }

  // Fetch materials for a specific course
  static Future<List<CourseMaterial>> fetchMaterialsForCourse(int? courseId) async {
    if (courseId == null) return [];
    
    try {
      final allMaterials = await fetchMaterials();
      return allMaterials.where((m) => m.courseId == courseId.toString()).toList();
    } catch (e) {
      debugPrint('❌ Error fetching materials for course: $e');
      return [];
    }
  }

  // Get full material URL from relative path
  static String getFullMaterialUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      debugPrint('⚠️ getFullMaterialUrl: Empty or null path');
      return '';
    }
    
    // If already a full URL, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      debugPrint('✅ getFullMaterialUrl: Already full URL: $relativePath');
      return relativePath;
    }
    
    // Ensure relative path starts with /
    final normalizedPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    final fullUrl = '${ApiClient.baseUrl}$normalizedPath';
    debugPrint('🔗 getFullMaterialUrl: Converted "$relativePath" to "$fullUrl"');
    return fullUrl;
  }
}


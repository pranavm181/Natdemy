import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/material.dart';
import 'api_client.dart';

class MaterialService {
  // Fetch materials from home API
  static Future<List<CourseMaterial>> fetchMaterials() async {
    try {
      debugPrint('🔄 Fetching materials from API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      debugPrint('📡 Materials API Response Status: ${response.statusCode}');
      
      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ Materials API returned HTML error page (status: ${response.statusCode})');
        return [];
      }
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            
            if (dataMap.containsKey('materials') && dataMap['materials'] is List) {
              final List<dynamic> materialsJson = dataMap['materials'] as List<dynamic>;
              debugPrint('📄 Found ${materialsJson.length} materials in API response');
              
              final materials = <CourseMaterial>[];
              
              for (var i = 0; i < materialsJson.length; i++) {
                try {
                  final materialJson = materialsJson[i] as Map<String, dynamic>;
                  
                  // Extract course ID from nested course object
                  String? courseId;
                  if (materialJson.containsKey('course') && materialJson['course'] is Map) {
                    final courseObj = materialJson['course'] as Map<String, dynamic>;
                    courseId = courseObj['id']?.toString();
                  } else if (materialJson.containsKey('course_id')) {
                    courseId = materialJson['course_id']?.toString();
                  }
                  
                  // Parse size_bytes (can be string or int)
                  int? sizeBytes;
                  if (materialJson['size_bytes'] != null) {
                    if (materialJson['size_bytes'] is int) {
                      sizeBytes = materialJson['size_bytes'] as int;
                    } else if (materialJson['size_bytes'] is String) {
                      sizeBytes = int.tryParse(materialJson['size_bytes'] as String);
                    }
                  }
                  
                  // Parse uploaded_at date
                  DateTime? uploadedAt;
                  if (materialJson['uploaded_at'] != null) {
                    try {
                      uploadedAt = DateTime.parse(materialJson['uploaded_at'] as String);
                    } catch (e) {
                      debugPrint('Error parsing uploaded_at: $e');
                    }
                  }
                  
                  // Generate size label if not provided
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
                  
                  // Get material URL
                  String materialUrl = materialJson['url'] as String? ?? '';
                  if (materialUrl.isNotEmpty && 
                      !materialUrl.startsWith('http://') && 
                      !materialUrl.startsWith('https://')) {
                    materialUrl = '${ApiClient.baseUrl}$materialUrl';
                  }
                  
                  final material = CourseMaterial(
                    id: materialJson['id']?.toString(),
                    courseId: courseId,
                    name: materialJson['name'] as String? ?? 'Untitled Material',
                    url: materialUrl,
                    sizeBytes: sizeBytes,
                    sizeLabel: sizeLabel,
                    fileType: materialJson['file_type'] as String? ?? 'pdf',
                    uploadedAt: uploadedAt,
                  );
                  
                  materials.add(material);
                  debugPrint('✅ Added material: ${material.name} (Course ID: $courseId)');
                } catch (e, stackTrace) {
                  debugPrint('❌ Error parsing material at index $i: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Material data: ${materialsJson[i]}');
                }
              }
              
              debugPrint('✅ Successfully fetched ${materials.length} materials from API');
              return materials;
            }
          }
          
          debugPrint('⚠️ No materials found in API response');
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for materials: $e');
          debugPrint('   Stack trace: $stackTrace');
          return [];
        }
      } else {
        debugPrint('❌ Materials API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching materials: $e');
      debugPrint('   Stack trace: $stackTrace');
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
      return '';
    }
    
    // If already a full URL, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Construct full URL
    return '${ApiClient.baseUrl}$relativePath';
  }
}


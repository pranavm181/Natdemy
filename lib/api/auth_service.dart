import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../data/student.dart';
import 'api_client.dart';
import 'course_service.dart';

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.token, required this.student});

  final String token;
  final Student student;
}

class AuthService {
  static const String _loginEndpoint = '/api/students/login/';
  static const String _registerEndpoint = '/api/students/register/';
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email,
      'password': password,
    };

    final response = await ApiClient.post(
      _loginEndpoint,
      body: body,
      includeAuth: false,
    );

    return _handleAuthResponse(response);
  }

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String studentId,
    String? photo,
    int? courseId,
  }) async {
    // Backend requires course_id (NOT NULL constraint), so fetch a valid one if not provided
    int? finalCourseId = courseId;
    if (finalCourseId == null) {
      try {
        debugPrint('🔄 No course_id provided, fetching valid course ID...');
        final courses = await CourseService.fetchCourses();
        if (courses.isNotEmpty && courses.first.id != null) {
          finalCourseId = courses.first.id;
          debugPrint('✅ Using course ID: $finalCourseId (${courses.first.title})');
        } else {
          debugPrint('⚠️ No courses available, using default course ID: 1');
          finalCourseId = 1; // Default fallback - course ID 1 exists in the API
        }
      } catch (e) {
        debugPrint('❌ Error fetching courses for registration: $e');
        debugPrint('   This might be a CORS issue in web browsers. Using default course ID: 1');
        // Use default course ID as fallback (course ID 1 exists in the API)
        finalCourseId = 1;
      }
    }

    final uri = Uri.parse('${ApiClient.baseUrl}$_registerEndpoint');
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'student_id': studentId,
      // Backend requires course_id (NOT NULL constraint)
      if (finalCourseId != null) 'course_id': finalCourseId.toString(),
    });

    Uint8List? photoBytes;
    if (photo != null && photo.isNotEmpty) {
      try {
        photoBytes = base64Decode(photo);
      } catch (e) {
        debugPrint('Invalid base64 photo provided: $e');
      }
    }

    photoBytes ??= await _loadPlaceholderPhoto();

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: 'placeholder.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    final headers = await ApiClient.getHeaders(includeAuth: false);
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleAuthResponse(response);
  }

  static AuthResult _handleAuthResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    Map<String, dynamic>? data;

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        data = {'errors': decoded};
      }
    } catch (e) {
      debugPrint('Auth response not JSON: $e');
    }

    try {
      debugPrint('🔍 Auth response (${response.request?.url}): $statusCode');
      debugPrint('📦 Response body: $body');
      if (statusCode >= 200 && statusCode < 300) {
        if (data == null) {
          debugPrint('❌ Response data is null or not JSON');
          throw AuthException('Invalid authentication response: not JSON', statusCode: statusCode);
        }

        debugPrint('📋 Response keys: ${data.keys.toList()}');
        
        // Try different possible response formats
        String? token = data['token'] as String?;
        Map<String, dynamic>? userData = data['user'] as Map<String, dynamic>?;
        
        // Backend uses 'student' instead of 'user' for registration
        if (userData == null) {
          userData = data['student'] as Map<String, dynamic>?;
          if (userData != null) {
            debugPrint('ℹ️ Found student data in "student" field');
          }
        }
        
        // Some APIs might return the user data directly (not nested in 'user' or 'student')
        if (userData == null && data.containsKey('id')) {
          debugPrint('ℹ️ User data not in "user" or "student" field, trying direct format...');
          userData = data;
        }
        
        // Check for alternative token field names
        if (token == null || token.isEmpty) {
          token = data['access_token'] as String? ?? 
                  data['access'] as String? ??
                  data['jwt_token'] as String?;
        }

        // Registration might not return a token - use empty string as placeholder
        // User will need to login separately to get a token
        if (token == null || token.isEmpty) {
          debugPrint('⚠️ Token not found in response (registration may not return token)');
          debugPrint('   Available keys: ${data.keys.toList()}');
          // Use empty token - user may need to login after registration
          token = '';
        }

        if (userData == null) {
          debugPrint('❌ User data not found in response. Available keys: ${data.keys.toList()}');
          throw AuthException('Invalid authentication response: missing user data', statusCode: statusCode);
        }

        debugPrint('✅ User data found, keys: ${userData.keys.toList()}');
        final student = Student.fromJson(userData, baseUrl: ApiClient.baseUrl);
        return AuthResult(token: token, student: student);
      }

      final errorMessage = (data != null ? _extractErrorMessage(data) : null) ??
          _extractPlainTextError(body) ??
          'Authentication failed';
      throw AuthException(errorMessage, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) {
        throw e;
      }

      debugPrint('Auth response parsing error: $e');
      throw AuthException('Unable to process authentication response');
    }
  }

  static String? _extractErrorMessage(Map<String, dynamic> data) {
    // Check for field-specific errors first (e.g., email, student_id)
    if (data.containsKey('email')) {
      final emailError = data['email'];
      if (emailError is List && emailError.isNotEmpty) {
        return 'Email: ${emailError.first}';
      } else if (emailError is String) {
        return 'Email: $emailError';
      }
    }
    
    if (data.containsKey('student_id')) {
      final studentIdError = data['student_id'];
      if (studentIdError is List && studentIdError.isNotEmpty) {
        return 'Student ID: ${studentIdError.first}';
      } else if (studentIdError is String) {
        return 'Student ID: $studentIdError';
      }
    }

    final message = data['message'] ?? data['detail'] ?? data['error'];
    if (message is String) {
      return message;
    }

    if (message is List && message.isNotEmpty && message.first is String) {
      return message.first as String;
    }

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is String && value.isNotEmpty) {
        return '$key: $value';
      }
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is String && first.isNotEmpty) {
          return '$key: $first';
        }
      }
    }

    return null;
  }

  static String? _extractPlainTextError(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    // Try to parse as JSON first to get structured error
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        // If it's JSON, let _extractErrorMessage handle it
        return null;
      }
    } catch (_) {
      // Not JSON, continue with plain text parsing
    }

    // Only show custom messages if we're very confident it's a duplicate error
    final lowerBody = trimmed.toLowerCase();
    if (lowerBody.contains('integrityerror') || lowerBody.contains('unique constraint')) {
      // Be more specific - only show email error if email is clearly mentioned
      if ((lowerBody.contains('email') || lowerBody.contains('students.email')) &&
          (lowerBody.contains('already exists') || 
           lowerBody.contains('duplicate') || 
           lowerBody.contains('unique'))) {
        return 'This email is already registered. Please use a different email or sign in.';
      }
      // Be more specific - only show student_id error if student_id is clearly mentioned
      if ((lowerBody.contains('student_id') || lowerBody.contains('student id')) &&
          (lowerBody.contains('already exists') || 
           lowerBody.contains('duplicate') || 
           lowerBody.contains('unique'))) {
        return 'This student ID is already in use. Please choose a different student ID.';
      }
      // Generic integrity error - but only if we're sure
      if (lowerBody.contains('already exists') || 
          lowerBody.contains('duplicate') || 
          lowerBody.contains('unique')) {
        return 'This email or student ID is already registered. Please use different values or sign in.';
      }
    }

    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
      return 'Server error occurred while processing the request.';
    }

    // Return the actual error message from backend
    return trimmed.length <= 200 ? trimmed : '${trimmed.substring(0, 200)}...';
  }

  static Future<Uint8List> _loadPlaceholderPhoto() async {
    final byteData = await rootBundle.load('assets/images/person-icon-8.png');
    return byteData.buffer.asUint8List();
  }

  // Logout
  static Future<void> logout() async {
    // Backend logout if needed
    try {
      // You can add backend logout endpoint here if available
      // await ApiClient.post('/api/auth/logout/', includeAuth: true);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    await ApiClient.removeToken();
  }
}



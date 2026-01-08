import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'https://lms.natdemy.com';
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(milliseconds: 500); // Reduced from 2 seconds
  
  // Get authentication token from storage
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
  
  // Save authentication token (for backward compatibility)
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }
  
  // Remove authentication token
  static Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error removing token: $e');
    }
  }
  
  // Get headers for API requests (optimized with gzip support)
  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate', // Enable compression
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Retry logic with exponential backoff
  static Future<http.Response> _retryRequest(
    Future<http.Response> Function() requestFn, {
    int maxRetries = maxRetries,
  }) async {
    int retries = 0;
    
    while (retries < maxRetries) {
      try {
        final response = await requestFn();
        
        // Retry on server errors (5xx) but not on client errors (4xx)
        if (response.statusCode >= 500 && retries < maxRetries - 1) {
          retries++;
          final delay = Duration(seconds: baseRetryDelay.inSeconds * retries);
          debugPrint('⚠️ Server error ${response.statusCode}, retrying in ${delay.inSeconds}s (attempt $retries/$maxRetries)');
          await Future.delayed(delay);
          continue;
        }
        
        return response;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          debugPrint('❌ Request failed after $maxRetries attempts: $e');
          rethrow;
        }
        
        final delay = Duration(seconds: baseRetryDelay.inSeconds * retries);
        debugPrint('⚠️ Request error, retrying in ${delay.inSeconds}s (attempt $retries/$maxRetries): $e');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Request failed after $maxRetries retries');
  }
  
  // GET request with retry logic
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    return _retryRequest(() async {
      var uri = Uri.parse('$baseUrl$endpoint');
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      return await http.get(
        uri,
        headers: await getHeaders(includeAuth: includeAuth),
      );
    });
  }
  
  // POST request with retry logic
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    return _retryRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      );
    });
  }
  
  // PUT request with retry logic
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    return _retryRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      );
    });
  }
  
  // DELETE request with retry logic
  static Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    return _retryRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(includeAuth: includeAuth),
      );
    });
  }
  
  // Handle API response and parse JSON
  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON decode error: $e');
        throw Exception('Invalid JSON response');
      }
    } else {
      debugPrint('API error: ${response.statusCode} - ${response.body}');
      throw Exception('API request failed: ${response.statusCode}');
    }
  }
}



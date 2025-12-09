import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for parsing JSON in background thread to avoid blocking UI
class JsonParser {
  /// Parse JSON string to Map in background thread
  static Future<Map<String, dynamic>> parseJson(String jsonString) async {
    return compute(_parseJsonInBackground, jsonString);
  }
  
  /// Parse JSON string to List in background thread
  static Future<List<dynamic>> parseJsonList(String jsonString) async {
    return compute(_parseJsonListInBackground, jsonString);
  }
  
  /// Background function for parsing JSON to Map
  static Map<String, dynamic> _parseJsonInBackground(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  
  /// Background function for parsing JSON to List
  static List<dynamic> _parseJsonListInBackground(String jsonString) {
    return json.decode(jsonString) as List<dynamic>;
  }
}



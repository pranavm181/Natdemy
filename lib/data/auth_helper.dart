import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import 'student.dart';

class AuthHelper {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserStudentId = 'user_student_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserProfileImage = 'user_profile_image';

  // Save login data
  static Future<bool> saveLoginData(Student student, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      if (student.id != null) {
        await prefs.setInt(_keyUserId, student.id!);
      } else {
        await prefs.remove(_keyUserId);
      }
      if (student.studentId != null && student.studentId!.isNotEmpty) {
        await prefs.setString(_keyUserStudentId, student.studentId!);
      } else {
        await prefs.remove(_keyUserStudentId);
      }
      await prefs.setString(_keyUserEmail, student.email);
      await prefs.setString(_keyUserName, student.name);
      await prefs.setString(_keyUserPhone, student.phone);
      if (student.profileImagePath != null) {
        await prefs.setString(_keyUserProfileImage, student.profileImagePath!);
      }
      if (token != null && token.isNotEmpty) {
        await ApiClient.saveToken(token);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving login data: $e');
      return false;
    }
  }

  // Get saved login data
  static Future<Student?> getSavedLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return null;

      final id = prefs.getInt(_keyUserId);
      final studentId = prefs.getString(_keyUserStudentId);
      final email = prefs.getString(_keyUserEmail);
      final name = prefs.getString(_keyUserName);
      final phone = prefs.getString(_keyUserPhone) ?? '';
      final profileImagePath = prefs.getString(_keyUserProfileImage);

      if (email != null && name != null) {
        return Student(
          id: id,
          studentId: studentId,
          name: name,
          email: email,
          phone: phone,
          profileImagePath: profileImagePath,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting saved login data: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Clear login data (logout)
  static Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserStudentId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyUserProfileImage);
      await ApiClient.removeToken();
    } catch (e) {
      debugPrint('Error clearing login data: $e');
    }
  }
}


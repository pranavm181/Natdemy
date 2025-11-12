import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'image_utils_io.dart' if (dart.library.html) 'image_utils_stub.dart' as io_utils;
import 'dart:io' if (dart.library.html) 'dart:html' as html;

/// Helper class to handle image loading across platforms (mobile and web)
class ImageUtils {
  /// Check if a file path exists (only works on non-web platforms)
  static bool fileExists(String? path) {
    if (kIsWeb || path == null) return false;
    try {
      return io_utils.fileExists(path);
    } catch (e) {
      return false;
    }
  }

  /// Get an ImageProvider for the profile image path
  /// Works on both web and mobile platforms
  /// Handles: local file paths, network URLs (http/https), data URLs, and API relative paths
  static ImageProvider? getProfileImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // Handle network URLs (from API) - works on both web and mobile
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }
    
    // Handle data URLs (base64 encoded images) - mainly for web
    if (imagePath.startsWith('data:')) {
      return NetworkImage(imagePath);
    }
    
    if (kIsWeb) {
      // On web, if it's not a URL or data URL, return null
      return null;
    } else {
      // On mobile, check if it's a local file
      if (fileExists(imagePath)) {
        return FileImage(io_utils.getFile(imagePath));
      }
      // If it's a relative path from API but file doesn't exist locally, 
      // it should have been converted to full URL in Student.fromJson
      // So return null here
      return null;
    }
  }

  /// Check if profile image exists and can be displayed
  /// Returns true for network URLs, data URLs, or existing local files
  static bool hasProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    // Network URLs from API
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return true;
    }
    
    // Data URLs (base64)
    if (imagePath.startsWith('data:')) {
      return true;
    }
    
    if (kIsWeb) {
      // On web, only network URLs and data URLs are valid
      return false;
    } else {
      // On mobile, check if local file exists
      return fileExists(imagePath);
    }
  }
}


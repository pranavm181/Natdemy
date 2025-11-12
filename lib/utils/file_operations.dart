// This file handles file operations with conditional imports
// On web, these will be stubs; on mobile, they'll use dart:io

import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional type definitions
import 'file_operations_stub.dart' if (dart.library.io) 'file_operations_io.dart';

/// Save profile image to storage
Future<String> saveProfileImage(String sourcePath, String email, int timestamp, String extension) async {
  if (kIsWeb) {
    throw UnsupportedError('File operations not supported on web');
  }
  return fileOperations.saveProfileImage(sourcePath, email, timestamp, extension);
}

/// Delete profile image file
Future<void> deleteProfileImage(String? imagePath) async {
  if (kIsWeb || imagePath == null) {
    return;
  }
  await fileOperations.deleteProfileImage(imagePath);
}


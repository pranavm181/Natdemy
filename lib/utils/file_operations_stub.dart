// Stub implementation for web
class FileOperations {
  Future<String> saveProfileImage(String sourcePath, String email, int timestamp, String fileExtension) {
    throw UnsupportedError('File operations not supported on web');
  }

  Future<void> deleteProfileImage(String imagePath) {
    // No-op on web
    return Future.value();
  }
}

final fileOperations = FileOperations();










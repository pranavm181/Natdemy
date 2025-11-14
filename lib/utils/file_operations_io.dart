import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileOperations {
  Future<String> saveProfileImage(String sourcePath, String email, int timestamp, String fileExtension) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    
    final String fileName = 'profile_${email}_${timestamp}$fileExtension';
    final String savedPath = path.join(appDocPath, fileName);
    
    final File imageFile = File(sourcePath);
    await imageFile.copy(savedPath);
    
    return savedPath;
  }

  Future<void> deleteProfileImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

final fileOperations = FileOperations();










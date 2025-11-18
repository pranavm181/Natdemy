import 'dart:io';

bool fileExists(String path) {
  return File(path).existsSync();
}

File getFile(String path) {
  return File(path);
}

Directory getDirectory(String path) {
  return Directory(path);
}















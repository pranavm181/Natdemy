
class Student {
  const Student({
    this.id,
    this.studentId,
    required this.name,
    required this.email,
    this.phone = '',
    this.profileImagePath,
  });
  
  final int? id; // Student ID from API
  final String? studentId; // Student ID string (e.g., "NOC25037")
  final String name; // Student name from API field 'name'
  final String email;
  final String phone;
  final String? profileImagePath; // Profile image from API field 'photo'
  
  // Factory method to create Student from API JSON
  // API fields: 'name' and 'photo'
  factory Student.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // Get photo URL - convert relative path to full URL if needed
    String? photoUrl;
    if (json['photo'] != null && json['photo'] != '') {
      final photo = json['photo'] as String;
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        photoUrl = photo;
      } else if (baseUrl != null) {
        photoUrl = '$baseUrl$photo';
      } else {
        photoUrl = photo;
      }
    }
    
    return Student(
      id: json['id'] as int?,
      studentId: json['student_id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImagePath: photoUrl,
    );
  }
  
  // Convert Student to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': profileImagePath,
    };
  }
}

class ClassItem {
  ClassItem({
    required this.title,
    required this.teacher,
    required this.startTime,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  final String title;
  final String teacher;
  final DateTime startTime;
  final String videoUrl;
  final String thumbnailUrl;
}

String _formatDate(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

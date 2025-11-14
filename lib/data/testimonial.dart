import 'package:flutter/material.dart';

class Testimonial {
  const Testimonial({
    required this.id,
    required this.name,
    this.department,
    required this.content,
    required this.rating,
    this.imageUrl,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? department;
  final String content;
  final int rating; // Rating out of 5
  final String? imageUrl; // Profile image URL
  final String? createdAt;

  factory Testimonial.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // Get image URL - convert relative path to full URL if needed
    String? imageUrl;
    if (json['image'] != null && json['image'] != '') {
      final image = json['image'] as String;
      if (image.startsWith('http://') || image.startsWith('https://')) {
        imageUrl = image;
      } else if (baseUrl != null) {
        imageUrl = '$baseUrl$image';
      } else {
        imageUrl = image;
      }
    }

    return Testimonial(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Anonymous',
      department: json['department'] as String?,
      content: json['content'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      imageUrl: imageUrl,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'content': content,
      'rating': rating,
      'image': imageUrl,
      'created_at': createdAt,
    };
  }
}





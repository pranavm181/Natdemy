import 'package:flutter/material.dart';

class AppBanner {
  const AppBanner({
    required this.id,
    required this.title,
    this.thumbnail,
    this.linkUrl,
    this.order,
    this.isActive,
  });

  final int id;
  final String title;
  final String? thumbnail; // Image URL (can be relative or absolute)
  final String? linkUrl; // Optional link when banner is clicked
  final int? order; // Display order
  final bool? isActive; // Whether banner is active

  factory AppBanner.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // Get thumbnail URL - convert relative path to full URL if needed
    String? thumbnailUrl;
    if (json['thumbnail'] != null && json['thumbnail'] != '') {
      final thumbnail = json['thumbnail'] as String;
      if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
        thumbnailUrl = thumbnail;
      } else if (baseUrl != null) {
        thumbnailUrl = '$baseUrl$thumbnail';
      } else {
        thumbnailUrl = thumbnail;
      }
    }

    return AppBanner(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      thumbnail: thumbnailUrl,
      linkUrl: json['link_url'] as String? ?? json['linkUrl'] as String?,
      order: json['order'] as int?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'link_url': linkUrl,
      'order': order,
      'is_active': isActive,
    };
  }
}


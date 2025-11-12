import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class ContactInfo {
  const ContactInfo({
    this.email,
    this.phone,
    this.whatsappNumber,
    this.whatsappGroupLink,
    this.website,
    this.address,
    this.socialMedia,
  });

  final String? email;
  final String? phone;
  final String? whatsappNumber;
  final String? whatsappGroupLink;
  final String? website;
  final String? address;
  final Map<String, String>? socialMedia;

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String? ?? json['whatsapp'] as String?,
      whatsappGroupLink: json['whatsapp_group_link'] as String? ?? json['whatsapp_link'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      socialMedia: json['social_media'] != null
          ? Map<String, String>.from(json['social_media'] as Map)
          : null,
    );
  }

  // Get default values if API data is missing
  static ContactInfo getDefault() {
    return const ContactInfo(
      email: 'support@natdemy.com',
      phone: '+91 89435 53164',
      whatsappNumber: '918943553164',
      whatsappGroupLink: 'https://chat.whatsapp.com/YourGroupLink',
      website: 'www.natdemy.com',
    );
  }
}

class ContactService {
  static ContactInfo? _cachedContactInfo;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Fetch contact information from API
  static Future<ContactInfo> fetchContactInfo({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh &&
        _cachedContactInfo != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      debugPrint('📞 Using cached contact info');
      return _cachedContactInfo!;
    }

    try {
      debugPrint('🔄 Fetching contact information from API...');
      final response = await ApiClient.get('/api/contact/', queryParams: {'format': 'json'}, includeAuth: false);

      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ Contact API returned HTML error page (status: ${response.statusCode}) - using defaults');
        return ContactInfo.getDefault();
      }

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          debugPrint('✅ Contact API response received');

          // Handle different response structures
          ContactInfo contactInfo;

          if (data.containsKey('data') && data['data'] is Map) {
            // If response has 'data' wrapper
            contactInfo = ContactInfo.fromJson(data['data'] as Map<String, dynamic>);
          } else if (data.containsKey('contacts') && data['contacts'] is List) {
            // If response has 'contacts' array, take first one
            final contacts = data['contacts'] as List<dynamic>;
            if (contacts.isNotEmpty) {
              contactInfo = ContactInfo.fromJson(contacts[0] as Map<String, dynamic>);
            } else {
              contactInfo = ContactInfo.getDefault();
            }
          } else {
            // Direct contact object
            contactInfo = ContactInfo.fromJson(data);
          }

          // Cache the result
          _cachedContactInfo = contactInfo;
          _cacheTime = DateTime.now();

          debugPrint('✅ Contact info loaded: email=${contactInfo.email}, phone=${contactInfo.phone}');
          return contactInfo;
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for contact info: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Using default contact information');
          return ContactInfo.getDefault();
        }
      } else {
        // Handle various error status codes
        String errorMessage;
        if (response.statusCode == 405) {
          errorMessage = 'Contact API method not allowed (405) - using defaults';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Contact API server error (${response.statusCode}) - using defaults';
        } else {
          errorMessage = 'Contact API returned status ${response.statusCode} - using defaults';
        }
        debugPrint('⚠️ $errorMessage');
        return ContactInfo.getDefault();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching contact info: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   Using default contact information');
      return ContactInfo.getDefault();
    }
  }

  // Get contact info (with caching)
  static Future<ContactInfo> getContactInfo() async {
    return await fetchContactInfo();
  }

  // Clear cache
  static void clearCache() {
    _cachedContactInfo = null;
    _cacheTime = null;
  }
}


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
      phone: '+91 92076 66621',
      whatsappNumber: '9192076666621',
      whatsappGroupLink: 'https://chat.whatsapp.com/LpNUsxNbGPq4eFgVgFGSL2?mode=wwt',
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
      // Try contactus API endpoint first (from admin contactus page)
      debugPrint('🔄 Fetching contact information from contactus API...');
      try {
        final contactusResponse = await ApiClient.get('/api/web/contactus/', queryParams: {'format': 'json'}, includeAuth: false);
        
        if (contactusResponse.statusCode == 200) {
          final isHtml = contactusResponse.body.trim().startsWith('<!DOCTYPE') || 
                         contactusResponse.body.trim().startsWith('<html') ||
                         contactusResponse.body.trim().startsWith('<HTML');
          
          if (!isHtml) {
            try {
              final Map<String, dynamic> contactusData = json.decode(contactusResponse.body);
              debugPrint('✅ Contactus API response received');
              
              // Handle different response structures
              ContactInfo? contactInfo;
              
              if (contactusData.containsKey('data') && contactusData['data'] is Map) {
                contactInfo = ContactInfo.fromJson(contactusData['data'] as Map<String, dynamic>);
              } else if (contactusData.containsKey('contacts') && contactusData['contacts'] is List) {
                final contacts = contactusData['contacts'] as List<dynamic>;
                if (contacts.isNotEmpty) {
                  contactInfo = ContactInfo.fromJson(contacts[0] as Map<String, dynamic>);
                }
              } else if (contactusData.containsKey('contact') && contactusData['contact'] is Map) {
                contactInfo = ContactInfo.fromJson(contactusData['contact'] as Map<String, dynamic>);
              } else {
                contactInfo = ContactInfo.fromJson(contactusData);
              }
              
              if (contactInfo != null && (contactInfo.phone != null || contactInfo.whatsappNumber != null)) {
                _cachedContactInfo = contactInfo;
                _cacheTime = DateTime.now();
                debugPrint('✅ Contact info loaded from contactus API: email=${contactInfo.email}, phone=${contactInfo.phone}');
                return contactInfo;
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing contactus API response: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Contactus API failed, trying home API: $e');
      }
      
      // Try home API to get contact info from data.contacts or data.whatsapp
      debugPrint('🔄 Fetching contact information from home API...');
      try {
        final homeResponse = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
        
        if (homeResponse.statusCode == 200) {
          final Map<String, dynamic> homeData = json.decode(homeResponse.body);
          
          if (homeData.containsKey('data') && homeData['data'] is Map) {
            final dataMap = homeData['data'] as Map<String, dynamic>;
            
            // Check for contacts array in home API
            if (dataMap.containsKey('contacts') && dataMap['contacts'] is List) {
              final contacts = dataMap['contacts'] as List<dynamic>;
              if (contacts.isNotEmpty) {
                debugPrint('✅ Found contacts in home API');
                final contactData = contacts[0] as Map<String, dynamic>;
                final contactInfo = ContactInfo.fromJson(contactData);
                
                // Cache and return
                _cachedContactInfo = contactInfo;
                _cacheTime = DateTime.now();
                debugPrint('✅ Contact info loaded from home API: email=${contactInfo.email}, phone=${contactInfo.phone}');
                return contactInfo;
              }
            }
            
            // Check for whatsapp array in home API (fallback)
            if (dataMap.containsKey('whatsapp') && dataMap['whatsapp'] is List) {
              final whatsappList = dataMap['whatsapp'] as List<dynamic>;
              if (whatsappList.isNotEmpty) {
                debugPrint('✅ Found whatsapp data in home API');
                final whatsappData = whatsappList[0] as Map<String, dynamic>;
                final whatsappNumber = whatsappData['number']?.toString();
                
                // Extract phone number from whatsapp number if available
                String? phoneNumber;
                String? whatsappNum;
                if (whatsappNumber != null) {
                  // Remove spaces and format
                  final cleaned = whatsappNumber.replaceAll(RegExp(r'[^0-9+]'), '');
                  whatsappNum = cleaned;
                  phoneNumber = whatsappNumber; // Keep formatted version for display
                }
                
                // Create ContactInfo from whatsapp data
                final contactInfo = ContactInfo(
                  phone: phoneNumber,
                  whatsappNumber: whatsappNum,
                  whatsappGroupLink: ContactInfo.getDefault().whatsappGroupLink,
                  email: ContactInfo.getDefault().email,
                  website: ContactInfo.getDefault().website,
                );
                
                // Cache and return
                _cachedContactInfo = contactInfo;
                _cacheTime = DateTime.now();
                debugPrint('✅ Contact info loaded from home API whatsapp: phone=${contactInfo.phone}, whatsapp=${contactInfo.whatsappNumber}');
                return contactInfo;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Home API failed, trying contact endpoint: $e');
      }
      
      // Fallback to contact API endpoint
      debugPrint('🔄 Fetching contact information from contact API...');
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


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'home_service.dart';

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
    final phone = json['phone'] as String?;
    final whatsappNumber = json['whatsapp_number'] as String? ?? json['whatsapp'] as String?;
    
    return ContactInfo(
      email: json['email'] as String?,
      phone: _removeCountryCode(phone),
      whatsappNumber: _removeCountryCode(whatsappNumber),
      whatsappGroupLink: json['whatsapp_group_link'] as String? ?? json['whatsapp_link'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      socialMedia: json['social_media'] != null
          ? Map<String, String>.from(json['social_media'] as Map)
          : null,
    );
  }

  // Helper function to ensure phone numbers have +91 prefix
  static String? _removeCountryCode(String? phoneNumber) {
    if (phoneNumber == null) return null;
    // Remove spaces and clean the number
    final cleaned = phoneNumber.replaceAll(RegExp(r'\s'), '').trim();
    // If it doesn't start with +91, add it
    if (!cleaned.startsWith('+91') && !cleaned.startsWith('91')) {
      return '+91 $cleaned';
    }
    // If it starts with 91 but not +91, add +
    if (cleaned.startsWith('91') && !cleaned.startsWith('+91')) {
      return '+91 ${cleaned.substring(2)}';
    }
    // If it already has +91, just format with space
    if (cleaned.startsWith('+91')) {
      final rest = cleaned.substring(3).trim();
      return '+91 $rest';
    }
    return cleaned;
  }

  // Get default values if API data is missing
  static ContactInfo getDefault() {
    return const ContactInfo(
      email: 'support@natdemy.com',
      phone: '+91 92076 66615',
      whatsappNumber: '+91 92076 66615',
      whatsappGroupLink: 'https://chat.whatsapp.com/LpNUsxNbGPq4eFgVgFGSL2?mode=wwt',
      website: 'www.natdemy.com',
    );
  }
}

class ContactService {
  static ContactInfo? _cachedContactInfo;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24); // Cache for 24 hours
  static const String _cacheKey = 'cached_contact_info';
  static const String _cacheTimeKey = 'contact_cache_time';

  // Load contact info from persistent cache
  static Future<ContactInfo?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactJson = prefs.getString(_cacheKey);
      final cacheTimeStr = prefs.getString(_cacheTimeKey);
      
      if (contactJson != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final cacheAge = DateTime.now().difference(cacheTime);
        
        if (cacheAge < _cacheDuration) {
          final Map<String, dynamic> decoded = json.decode(contactJson);
          final contactInfo = ContactInfo.fromJson(decoded);
          
          _cachedContactInfo = contactInfo;
          _cacheTime = cacheTime;
          
          debugPrint('📦 Loaded contact info from persistent cache (age: ${cacheAge.inMinutes}m)');
          return contactInfo;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading contact info from cache: $e');
    }
    return null;
  }

  // Save contact info to persistent cache
  static Future<void> _saveToCache(ContactInfo contactInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactJson = json.encode({
        'email': contactInfo.email,
        'phone': contactInfo.phone,
        'whatsapp_number': contactInfo.whatsappNumber,
        'whatsapp_group_link': contactInfo.whatsappGroupLink,
        'website': contactInfo.website,
        'address': contactInfo.address,
        'social_media': contactInfo.socialMedia,
      });
      await prefs.setString(_cacheKey, contactJson);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
      debugPrint('💾 Saved contact info to persistent cache');
    } catch (e) {
      debugPrint('⚠️ Error saving contact info to cache: $e');
    }
  }

  // Fetch contact information from API (with persistent caching)
  static Future<ContactInfo> fetchContactInfo({bool forceRefresh = false}) async {
    // Try to load from cache first (if not forcing refresh)
    if (!forceRefresh) {
      // Check in-memory cache first
      if (_cachedContactInfo != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        debugPrint('📞 Using in-memory cached contact info');
        return _cachedContactInfo!;
      }
      
      // Try persistent cache
      final cachedContact = await _loadFromCache();
      if (cachedContact != null) {
        return cachedContact;
      }
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
                await _saveToCache(contactInfo);
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
      debugPrint('🔄 Fetching contact information from HomeService...');
      try {
        final homeData = await HomeService.fetchHomeData(forceRefresh: forceRefresh);
        final dataMap = homeData.containsKey('data') && homeData['data'] is Map
            ? homeData['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        
        if (dataMap.isNotEmpty) {
          // Check for contacts array in HomeService data
          if (dataMap.containsKey('contacts') && dataMap['contacts'] is List) {
            final contacts = dataMap['contacts'] as List<dynamic>;
            if (contacts.isNotEmpty) {
              debugPrint('✅ Found contacts in HomeService response');
              final contactData = contacts[0] as Map<String, dynamic>;
              final contactInfo = ContactInfo.fromJson(contactData);
              
              // Cache and return
              _cachedContactInfo = contactInfo;
              _cacheTime = DateTime.now();
              await _saveToCache(contactInfo);
              debugPrint('✅ Contact info loaded from HomeService (contacts): email=${contactInfo.email}, phone=${contactInfo.phone}');
              return contactInfo;
            }
          }
          
          // Check for whatsapp array in HomeService data (fallback)
          if (dataMap.containsKey('whatsapp') && dataMap['whatsapp'] is List) {
            final whatsappList = dataMap['whatsapp'] as List<dynamic>;
            if (whatsappList.isNotEmpty) {
              debugPrint('✅ Found whatsapp data in HomeService response');
              final whatsappData = whatsappList[0] as Map<String, dynamic>;
              final whatsappNumber = whatsappData['number']?.toString();
              
              String? phoneNumber;
              String? whatsappNum;
              if (whatsappNumber != null) {
                final cleaned = whatsappNumber
                    .replaceAll(RegExp(r'\s'), '')
                    .replaceAll(RegExp(r'[^0-9+]'), '');
                whatsappNum = cleaned.startsWith('+91') ? cleaned.substring(3) : (cleaned.startsWith('91') ? cleaned : '91$cleaned');
                phoneNumber = ContactInfo._removeCountryCode(whatsappNumber);
              }
              
              final contactInfo = ContactInfo(
                phone: phoneNumber,
                whatsappNumber: whatsappNum,
                whatsappGroupLink: ContactInfo.getDefault().whatsappGroupLink,
                email: ContactInfo.getDefault().email,
                website: ContactInfo.getDefault().website,
              );
              
              _cachedContactInfo = contactInfo;
              _cacheTime = DateTime.now();
              await _saveToCache(contactInfo);
              debugPrint('✅ Contact info loaded from HomeService (whatsapp): phone=${contactInfo.phone}, whatsapp=${contactInfo.whatsappNumber}');
              return contactInfo;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ HomeService fetch for contact failed: $e');
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
          // Parse JSON in background thread
          final Map<String, dynamic> data = await JsonParser.parseJson(response.body);
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
          await _saveToCache(contactInfo);

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


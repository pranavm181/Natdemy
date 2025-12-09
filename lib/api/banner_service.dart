import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/banner.dart' show AppBanner;
import 'api_client.dart';
import '../utils/json_parser.dart';

class BannerService {
  // Fetch banners from home API
  static Future<List<AppBanner>> fetchBanners() async {
    try {
      debugPrint('🔄 Fetching banners from API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      debugPrint('📡 Banners API Response Status: ${response.statusCode}');
      
      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ Banners API returned HTML error page (status: ${response.statusCode})');
        return [];
      }
      
      if (response.statusCode == 200) {
        try {
          // Parse JSON in background thread to avoid blocking UI
          final Map<String, dynamic> data = await JsonParser.parseJson(response.body);
          debugPrint('✅ JSON decoded successfully');
          
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            
            if (dataMap.containsKey('banners') && dataMap['banners'] is List) {
              final List<dynamic> bannersJson = dataMap['banners'] as List<dynamic>;
              debugPrint('🖼️ Found ${bannersJson.length} banners in API response');
              
              final banners = <AppBanner>[];
              
              for (var i = 0; i < bannersJson.length; i++) {
                try {
                  final bannerJson = bannersJson[i] as Map<String, dynamic>;
                  // Only include active banners (default to true if not specified)
                  final isActive = bannerJson['is_active'] as bool? ?? 
                                  bannerJson['isActive'] as bool? ?? 
                                  true;
                  
                  if (isActive) {
                    final banner = AppBanner.fromJson(bannerJson, baseUrl: ApiClient.baseUrl);
                    banners.add(banner);
                    debugPrint('✅ Added banner: ${banner.title}');
                  } else {
                    debugPrint('⏭️ Skipped inactive banner: ${bannerJson['title']}');
                  }
                } catch (e, stackTrace) {
                  debugPrint('❌ Error parsing banner at index $i: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Banner data: ${bannersJson[i]}');
                }
              }
              
              // Sort by order if available
              banners.sort((AppBanner a, AppBanner b) {
                final orderA = a.order ?? 999;
                final orderB = b.order ?? 999;
                return orderA.compareTo(orderB);
              });
              
              debugPrint('✅ Successfully fetched ${banners.length} banners from API');
              return banners;
            } else {
              debugPrint('⚠️ "banners" key not found or not a List in data');
              debugPrint('   Available keys: ${dataMap.keys.toList()}');
            }
          } else {
            debugPrint('⚠️ "data" key not found or not a Map');
            debugPrint('   Top-level keys: ${data.keys.toList()}');
          }
          
          debugPrint('⚠️ No banners found in API response');
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for banners: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        debugPrint('❌ Banners API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching banners: $e');
      debugPrint('   Stack trace: $stackTrace');
      return [];
    }
  }
}


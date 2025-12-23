import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/banner.dart' show AppBanner;
import 'api_client.dart';
import '../utils/json_parser.dart';

class BannerService {
  static List<AppBanner> _cachedBanners = [];
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24); // Cache for 24 hours
  static const String _cacheKeyBanners = 'cached_banners';
  static const String _cacheKeyTime = 'banners_cache_time';

  // Load banners from persistent cache
  static Future<List<AppBanner>?> _loadBannersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bannersJson = prefs.getString(_cacheKeyBanners);
      final cacheTimeStr = prefs.getString(_cacheKeyTime);
      
      if (bannersJson != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final cacheAge = DateTime.now().difference(cacheTime);
        
        if (cacheAge < _cacheDuration) {
          final List<dynamic> decoded = json.decode(bannersJson);
          final banners = decoded
              .map((json) => AppBanner.fromJson(json as Map<String, dynamic>, baseUrl: ApiClient.baseUrl))
              .toList();
          
          _cachedBanners = banners;
          _cacheTime = cacheTime;
          
          debugPrint('📦 Loaded ${banners.length} banners from persistent cache (age: ${cacheAge.inMinutes}m)');
          return banners;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading banners from cache: $e');
    }
    return null;
  }

  // Save banners to persistent cache
  static Future<void> _saveBannersToCache(List<AppBanner> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bannersJson = json.encode(banners.map((b) => b.toJson()).toList());
      await prefs.setString(_cacheKeyBanners, bannersJson);
      await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());
      debugPrint('💾 Saved ${banners.length} banners to persistent cache');
    } catch (e) {
      debugPrint('⚠️ Error saving banners to cache: $e');
    }
  }

  // Fetch banners from home API (with persistent caching)
  static Future<List<AppBanner>> fetchBanners({bool forceRefresh = false}) async {
    // Try to load from persistent cache first (if not forcing refresh)
    if (!forceRefresh) {
      // Check in-memory cache first
      if (_cachedBanners.isNotEmpty && _cacheTime != null) {
        final cacheAge = DateTime.now().difference(_cacheTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('📦 Using in-memory cached banners (age: ${cacheAge.inMinutes}m)');
          return _cachedBanners;
        }
      }
      
      // Try persistent cache
      final cachedBanners = await _loadBannersFromCache();
      if (cachedBanners != null) {
        return cachedBanners;
      }
    }
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
              
              // Cache the results (in-memory and persistent)
              _cachedBanners = banners;
              _cacheTime = DateTime.now();
              await _saveBannersToCache(banners);
              
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
          // Return cached banners if available, even if expired
          if (_cachedBanners.isNotEmpty) {
            debugPrint('📦 Returning cached banners (API failed)');
            return _cachedBanners;
          }
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for banners: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          // Return cached banners if available
          if (_cachedBanners.isNotEmpty) {
            debugPrint('📦 Returning cached banners (parse error)');
            return _cachedBanners;
          }
          return [];
        }
      } else {
        debugPrint('❌ Banners API request failed: ${response.statusCode}');
        // Return cached banners if available
        if (_cachedBanners.isNotEmpty) {
          debugPrint('📦 Returning cached banners (API failed)');
          return _cachedBanners;
        }
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching banners: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Return cached banners if available, even on error
      if (_cachedBanners.isNotEmpty) {
        debugPrint('📦 Returning cached banners (error occurred)');
        return _cachedBanners;
      }
      return [];
    }
  }

  // Clear banner cache (useful for force refresh)
  static Future<void> clearCache() async {
    _cachedBanners = [];
    _cacheTime = null;
    
    // Clear persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyBanners);
      await prefs.remove(_cacheKeyTime);
      debugPrint('🗑️ Cleared persistent banner cache');
    } catch (e) {
      debugPrint('⚠️ Error clearing persistent cache: $e');
    }
  }

  // Initialize cache on app start (load from persistent storage)
  static Future<void> initializeCache() async {
    await _loadBannersFromCache();
  }
}


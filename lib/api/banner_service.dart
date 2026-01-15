import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/banner.dart' show AppBanner;
import 'api_client.dart';
import 'home_service.dart';

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
        final List<dynamic> decoded = json.decode(bannersJson);
        final banners = decoded
            .map((json) => AppBanner.fromJson(json as Map<String, dynamic>, baseUrl: ApiClient.baseUrl))
            .toList();
        
        _cachedBanners = banners;
        _cacheTime = cacheTime;
        return banners;
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
    } catch (e) {
      debugPrint('⚠️ Error saving banners to cache: $e');
    }
  }

  /// Fetch banners via HomeService (deduplicated)
  static Future<List<AppBanner>> fetchBanners({bool forceRefresh = false}) async {
    // 1. Memory Cache Check
    if (!forceRefresh && _cachedBanners.isNotEmpty && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedBanners;
      }
    }

    // 2. Persistent Cache Check
    if (!forceRefresh) {
      final cached = await _loadBannersFromCache();
      if (cached != null) return cached;
    }

    // 3. Network Fetch via HomeService
    try {
      final data = await HomeService.fetchHomeData(forceRefresh: forceRefresh);
      
      if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        
        if (dataMap.containsKey('banners') && dataMap['banners'] is List) {
          final List<dynamic> bannersJson = dataMap['banners'] as List<dynamic>;
          
          final banners = <AppBanner>[];
          for (var json in bannersJson) {
            try {
              final banner = AppBanner.fromJson(json as Map<String, dynamic>, baseUrl: ApiClient.baseUrl);
              // Filter active banners
              if (json['is_active'] != false) {
                banners.add(banner);
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing banner: $e');
            }
          }
          
          // Sort
          banners.sort((a, b) => (a.order ?? 999).compareTo(b.order ?? 999));
          
          // Cache
          _cachedBanners = banners;
          _cacheTime = DateTime.now();
          await _saveBannersToCache(banners);
          
          return banners;
        }
      }
      return _cachedBanners;
    } catch (e) {
      debugPrint('❌ Banner fetch failed: $e');
      return _cachedBanners;
    }
  }

  static Future<void> clearCache() async {
    _cachedBanners = [];
    _cacheTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyBanners);
    await prefs.remove(_cacheKeyTime);
  }

  static Future<void> initializeCache() async {
    await _loadBannersFromCache();
  }
}

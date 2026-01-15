import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/testimonial.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'home_service.dart';

class TestimonialService {
  static List<Testimonial>? _cachedTestimonials;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24); // Cache for 24 hours
  static const String _cacheKey = 'cached_testimonials';
  static const String _cacheTimeKey = 'testimonials_cache_time';

  // Load testimonials from persistent cache
  static Future<List<Testimonial>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testimonialsJson = prefs.getString(_cacheKey);
      final cacheTimeStr = prefs.getString(_cacheTimeKey);
      
      if (testimonialsJson != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final cacheAge = DateTime.now().difference(cacheTime);
        
        if (cacheAge < _cacheDuration) {
          final List<dynamic> decoded = json.decode(testimonialsJson);
          final testimonials = decoded
              .map((json) => Testimonial.fromJson(json as Map<String, dynamic>, baseUrl: ApiClient.baseUrl))
              .toList();
          
          _cachedTestimonials = testimonials;
          _cacheTime = cacheTime;
          
          debugPrint('📦 Loaded ${testimonials.length} testimonials from persistent cache (age: ${cacheAge.inMinutes}m)');
          return testimonials;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading testimonials from cache: $e');
    }
    return null;
  }

  // Save testimonials to persistent cache
  static Future<void> _saveToCache(List<Testimonial> testimonials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testimonialsJson = json.encode(testimonials.map((t) => t.toJson()).toList());
      await prefs.setString(_cacheKey, testimonialsJson);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
      debugPrint('💾 Saved ${testimonials.length} testimonials to persistent cache');
    } catch (e) {
      debugPrint('⚠️ Error saving testimonials to cache: $e');
    }
  }

  // Fetch testimonials from home API (with persistent caching)
  static Future<List<Testimonial>> fetchTestimonials({bool forceRefresh = false}) async {
    // Try to load from cache first (if not forcing refresh)
    if (!forceRefresh) {
      // Check in-memory cache first
      if (_cachedTestimonials != null && _cacheTime != null) {
        final cacheAge = DateTime.now().difference(_cacheTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('📦 Using in-memory cached testimonials (age: ${cacheAge.inMinutes}m)');
          return _cachedTestimonials!;
        }
      }
      
      // Try persistent cache
      final cachedTestimonials = await _loadFromCache();
      if (cachedTestimonials != null) {
        return cachedTestimonials;
      }
    }
    try {
      debugPrint('🔄 Fetching testimonials from HomeService...');
      final data = await HomeService.fetchHomeData(forceRefresh: forceRefresh);
      
      if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        
        if (dataMap.containsKey('testimonials') && dataMap['testimonials'] is List) {
          final List<dynamic> testimonialsJson = dataMap['testimonials'] as List<dynamic>;
          debugPrint('💬 Found ${testimonialsJson.length} testimonials in API response');
          
          final testimonials = <Testimonial>[];
          for (var json in testimonialsJson) {
            try {
              final testimonial = Testimonial.fromJson(json as Map<String, dynamic>, baseUrl: ApiClient.baseUrl);
              testimonials.add(testimonial);
            } catch (e) {
              debugPrint('⚠️ Error parsing testimonial: $e');
            }
          }
          
          if (testimonials.isNotEmpty) {
            _cachedTestimonials = testimonials;
            _cacheTime = DateTime.now();
            await _saveToCache(testimonials);
          }
          return testimonials;
        }
      }
      return _cachedTestimonials ?? [];
    } catch (e) {
      debugPrint('❌ Testimonial fetch failed: $e');
      return _cachedTestimonials ?? [];
    }
  }
}

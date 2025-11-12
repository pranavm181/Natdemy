import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/testimonial.dart';
import 'api_client.dart';

class TestimonialService {
  // Fetch testimonials from home API
  static Future<List<Testimonial>> fetchTestimonials() async {
    try {
      debugPrint('🔄 Fetching testimonials from API...');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      debugPrint('📡 Testimonials API Response Status: ${response.statusCode}');
      
      // Check if response is HTML (error page) instead of JSON
      final isHtml = response.body.trim().startsWith('<!DOCTYPE') || 
                     response.body.trim().startsWith('<html') ||
                     response.body.trim().startsWith('<HTML');
      
      if (isHtml) {
        debugPrint('⚠️ Testimonials API returned HTML error page (status: ${response.statusCode})');
        return [];
      }
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          debugPrint('✅ JSON decoded successfully');
          
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            
            if (dataMap.containsKey('testimonials') && dataMap['testimonials'] is List) {
              final List<dynamic> testimonialsJson = dataMap['testimonials'] as List<dynamic>;
              debugPrint('💬 Found ${testimonialsJson.length} testimonials in API response');
              
              final testimonials = <Testimonial>[];
              
              for (var i = 0; i < testimonialsJson.length; i++) {
                try {
                  final testimonialJson = testimonialsJson[i] as Map<String, dynamic>;
                  final testimonial = Testimonial.fromJson(testimonialJson, baseUrl: ApiClient.baseUrl);
                  testimonials.add(testimonial);
                  debugPrint('✅ Added testimonial: ${testimonial.name}');
                } catch (e, stackTrace) {
                  debugPrint('❌ Error parsing testimonial at index $i: $e');
                  debugPrint('   Stack trace: $stackTrace');
                  debugPrint('   Testimonial data: ${testimonialsJson[i]}');
                }
              }
              
              debugPrint('✅ Successfully fetched ${testimonials.length} testimonials from API');
              return testimonials;
            } else {
              debugPrint('⚠️ "testimonials" key not found or not a List in data');
              debugPrint('   Available keys: ${dataMap.keys.toList()}');
            }
          } else {
            debugPrint('⚠️ "data" key not found or not a Map');
            debugPrint('   Top-level keys: ${data.keys.toList()}');
          }
          
          debugPrint('⚠️ No testimonials found in API response');
          return [];
        } catch (e, stackTrace) {
          debugPrint('❌ JSON decode error for testimonials: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        debugPrint('❌ Testimonials API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching testimonials: $e');
      debugPrint('   Stack trace: $stackTrace');
      return [];
    }
  }
}



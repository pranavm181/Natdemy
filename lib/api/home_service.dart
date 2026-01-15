import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';

/// Service to coordinate data fetching from the home endpoint
/// This prevents multiple redundant network requests to /api/home/
class HomeService {
  static Future<Map<String, dynamic>>? _pendingRequest;
  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Fetch home data with deduplication and short-term in-memory caching
  static Future<Map<String, dynamic>> fetchHomeData({bool forceRefresh = false}) async {
    // 1. Return pending request if already in flight
    if (_pendingRequest != null) {
      debugPrint('⏳ Reusing pending request for /api/home/');
      return _pendingRequest!;
    }

    // 2. Return short-term cache if available and not forcing refresh
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        debugPrint('📦 Using short-term memory cache for /api/home/ (age: ${age.inSeconds}s)');
        return _cachedData!;
      }
    }

    // 3. Perform the actual fetch
    _pendingRequest = _performFetch();
    try {
      final data = await _pendingRequest!;
      _cachedData = data;
      _lastFetchTime = DateTime.now();
      return data;
    } finally {
      _pendingRequest = null;
    }
  }

  static Future<Map<String, dynamic>> _performFetch() async {
    try {
      debugPrint('🌐 Initiating network request to /api/home/ (Deduplicated)');
      final response = await ApiClient.get('/api/home/', queryParams: {'format': 'json'}, includeAuth: false);
      
      if (response.statusCode == 200) {
        // Parse JSON in background thread
        final Map<String, dynamic> data = await JsonParser.parseJson(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch home data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in home data fetch: $e');
      rethrow;
    }
  }

  /// Clear the short-term cache
  static void clearCache() {
    _cachedData = null;
    _lastFetchTime = null;
  }
}

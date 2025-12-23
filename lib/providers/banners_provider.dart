import 'package:flutter/foundation.dart';
import '../data/banner.dart';
import '../api/banner_service.dart';

class BannersProvider with ChangeNotifier {
  List<AppBanner> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<AppBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBanners => _banners.isNotEmpty;

  // Fetch banners from API (with cache-first strategy)
  Future<void> fetchBanners({bool forceRefresh = false}) async {
    // If we have banners and not forcing refresh, show them immediately
    if (!forceRefresh && _banners.isNotEmpty) {
      // Refresh in background without blocking
      BannerService.fetchBanners(forceRefresh: true).then((updatedBanners) {
        if (updatedBanners.isNotEmpty && updatedBanners != _banners) {
          _banners = updatedBanners;
          _error = null;
          notifyListeners();
        }
      }).catchError((e) {
        debugPrint('⚠️ Background banner refresh failed: $e');
      });
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load from cache first (fast), then refresh from API in background if needed
      final banners = await BannerService.fetchBanners(forceRefresh: forceRefresh);
      _banners = banners;
      _error = null;
      
      // If we loaded from cache, refresh from API in background
      if (!forceRefresh && banners.isNotEmpty) {
        BannerService.fetchBanners(forceRefresh: true).then((updatedBanners) {
          if (updatedBanners.isNotEmpty && updatedBanners != _banners) {
            _banners = updatedBanners;
            notifyListeners();
          }
        }).catchError((e) {
          debugPrint('⚠️ Background banner refresh failed: $e');
        });
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching banners: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear banners
  void clearBanners() {
    _banners = [];
    _error = null;
    notifyListeners();
  }
}

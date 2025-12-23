import 'package:flutter/foundation.dart';
import '../data/testimonial.dart';
import '../api/testimonial_service.dart';

class TestimonialsProvider with ChangeNotifier {
  List<Testimonial> _testimonials = [];
  bool _isLoading = false;
  String? _error;

  List<Testimonial> get testimonials => _testimonials;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTestimonials => _testimonials.isNotEmpty;

  // Fetch testimonials from API
  Future<void> fetchTestimonials({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final testimonials = await TestimonialService.fetchTestimonials(forceRefresh: forceRefresh);
      _testimonials = testimonials;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching testimonials: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear testimonials
  void clearTestimonials() {
    _testimonials = [];
    _error = null;
    notifyListeners();
  }
}

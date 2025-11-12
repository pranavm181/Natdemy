import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/testimonial.dart';
import 'rating_stars.dart';

class TestimonialCarousel extends StatefulWidget {
  const TestimonialCarousel({
    super.key,
    required this.testimonials,
  });

  final List<Testimonial> testimonials;

  @override
  State<TestimonialCarousel> createState() => _TestimonialCarouselState();
}

class _TestimonialCarouselState extends State<TestimonialCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  int _cardsPerPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int _calculateCardsPerPage(BuildContext context) {
    if (!kIsWeb) return 1;
    
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 3; // Show 3 cards on large screens
    } else if (width > 800) {
      return 2; // Show 2 cards on medium screens
    }
    return 1; // Show 1 card on smaller screens
  }

  double _getViewportFraction(int cardsPerPage) {
    if (!kIsWeb) {
      return 0.85; // Mobile: show one card with peek
    }
    
    // Web: when showing multiple cards, use full width (1.0)
    // because each page contains a full row of cards
    if (cardsPerPage > 1) {
      return 1.0; // Full width for multiple cards
    }
    return 0.85; // Fallback to single card with peek
  }

  int _getTotalPages(int cardsPerPage) {
    if (cardsPerPage == 1) {
      return widget.testimonials.length;
    }
    return (widget.testimonials.length / cardsPerPage).ceil();
  }

  void _startAutoScroll() {
    if (widget.testimonials.length <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        final context = this.context;
        final cardsPerPage = _calculateCardsPerPage(context);
        final totalPages = _getTotalPages(cardsPerPage);
        
        if (totalPages <= 1) return;
        
        int nextPage = _currentPage + 1;
        if (nextPage >= totalPages) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.testimonials.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardsPerPage = _calculateCardsPerPage(context);
        final totalPages = _getTotalPages(cardsPerPage);
        final viewportFraction = _getViewportFraction(cardsPerPage);
        
        // Update controller if viewport fraction changed
        if (_pageController.viewportFraction != viewportFraction) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final oldController = _pageController;
              _pageController = PageController(
                viewportFraction: viewportFraction,
                initialPage: _currentPage < totalPages ? _currentPage : 0,
              );
              oldController.dispose();
            }
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: totalPages,
                  itemBuilder: (context, pageIndex) {
                    // For web: show multiple cards side by side
                    if (kIsWeb && cardsPerPage > 1) {
                      return Row(
                        children: List.generate(
                          cardsPerPage,
                          (cardIndex) {
                            final testimonialIndex = pageIndex * cardsPerPage + cardIndex;
                            if (testimonialIndex >= widget.testimonials.length) {
                              return const Expanded(child: SizedBox.shrink());
                            }
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: _TestimonialCard(
                                  testimonial: widget.testimonials[testimonialIndex],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    // For mobile: show single card
                    final testimonial = widget.testimonials[pageIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _TestimonialCard(testimonial: testimonial),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalPages,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF582DB0)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final Testimonial testimonial;

  String _getTitle() {
    // Try to extract a title from the content
    // Look for common patterns like "Success Stories", "Great quality!", etc.
    final content = testimonial.content;
    
    // Check if content starts with a title-like pattern (short phrase followed by comma or period)
    final titleMatch = RegExp(r'^([^.!?]{1,30})([.!?]|,\s)').firstMatch(content);
    if (titleMatch != null) {
      final potentialTitle = titleMatch.group(1)?.trim() ?? '';
      if (potentialTitle.length > 3 && potentialTitle.length < 30) {
        return potentialTitle;
      }
    }
    
    // Fallback: use first few words
    final words = content.split(' ');
    if (words.length >= 2) {
      return '${words[0]} ${words[1]}';
    }
    return words.isNotEmpty ? words[0] : 'Testimonial';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with quote mark and title
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Large "99" quote mark in top right
                Positioned(
                  top: -15,
                  right: -15,
                  child: Text(
                    '99',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w200,
                      color: Colors.grey[200]?.withOpacity(0.8),
                      height: 0.8,
                      letterSpacing: -5,
                    ),
                  ),
                ),
                // Title in blue
                Padding(
                  padding: const EdgeInsets.only(right: 50, top: 4),
                  child: Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF582DB0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Testimonial content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  testimonial.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reviewer info
            Row(
              children: [
                // Profile image
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF582DB0),
                  backgroundImage: testimonial.imageUrl != null &&
                          testimonial.imageUrl!.isNotEmpty
                      ? NetworkImage(testimonial.imageUrl!)
                      : null,
                  child: testimonial.imageUrl == null ||
                          testimonial.imageUrl!.isEmpty
                      ? Text(
                          testimonial.name.isNotEmpty
                              ? testimonial.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name and role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (testimonial.department != null &&
                          testimonial.department!.isNotEmpty)
                        Text(
                          testimonial.department!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Rating
                RatingStars(
                  rating: testimonial.rating.toDouble(),
                  starSize: 14,
                  showValue: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../data/banner.dart' show AppBanner;
import '../data/student.dart';

const double _bannerWebAspectRatio = 16 / 5.6;
const double _bannerMobileAspectRatio = 16 / 5.6;

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.student,
    this.onPageChanged,
  });

  final List<AppBanner> banners;
  final Student student;
  final ValueChanged<int>? onPageChanged;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  double get _defaultAspectRatio => kIsWeb ? _bannerWebAspectRatio : _bannerMobileAspectRatio;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    final totalBanners = _getTotalBanners();
    if (totalBanners <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && mounted) {
        int nextPage = _currentPage + 1;
        if (nextPage >= totalBanners) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  int _getTotalBanners() {
    return widget.banners.isEmpty ? 1 : widget.banners.length;
  }

  Future<void> _handleBannerTap(AppBanner? banner) async {
    if (banner?.linkUrl != null && banner!.linkUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(banner.linkUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching banner URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBanners = _getTotalBanners();

    final borderRadius = BorderRadius.circular(kIsWeb ? 36 : 24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: AspectRatio(
        aspectRatio: _defaultAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.black.withOpacity(0.9),
              width: kIsWeb ? 3.5 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 42,
                spreadRadius: 4,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    widget.onPageChanged?.call(index);
                  },
                  itemCount: totalBanners,
                  itemBuilder: (context, index) {
                    if (widget.banners.isEmpty) {
                      return _AppBanner(student: widget.student);
                    }
                    final banner = widget.banners[index];
                    return _ApiBanner(
                      banner: banner,
                      student: widget.student,
                      onTap: () => _handleBannerTap(banner),
                    );
                  },
                ),
                Positioned(
                  bottom: 22,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalBanners,
                      (index) {
                        final isActive = _currentPage == index || (widget.banners.isEmpty && index == 0);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// App Banner (default banner)
class _AppBanner extends StatelessWidget {
  const _AppBanner({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF582DB0),
            Color(0xFF7C3AED),
            Color(0xFF8B5CF6),
            Color(0xFF9333EA),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/images/natdemy_logo2.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF582DB0));
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// API Banner (from API)
class _ApiBanner extends StatefulWidget {
  const _ApiBanner({
    required this.banner,
    required this.student,
    this.onTap,
  });

  final AppBanner banner;
  final Student student;
  final VoidCallback? onTap;

  @override
  State<_ApiBanner> createState() => _ApiBannerState();
}

class _ApiBannerState extends State<_ApiBanner> {

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = widget.banner.thumbnail != null && widget.banner.thumbnail!.isNotEmpty;

    if (!hasThumbnail) {
      return GestureDetector(
        onTap: widget.onTap,
        child: _AppBanner(student: widget.student),
      );
    }

    final borderRadius = BorderRadius.circular(kIsWeb ? 32 : 20);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: kIsWeb ? 40 : 24,
              spreadRadius: kIsWeb ? 3 : 1,
              offset: const Offset(0, 16),
            ),
          ],
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image.network(
                  widget.banner.thumbnail!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return _AppBanner(student: widget.student);
                  },
                  color: Colors.black.withOpacity(0.15),
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                  child: Image.network(
                    widget.banner.thumbnail!,
                  fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return _AppBanner(student: widget.student);
                    },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
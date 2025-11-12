import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../data/banner.dart' show AppBanner;
import '../data/student.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.student,
  });

  final List<AppBanner> banners;
  final Student student;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

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
    // Always include app banner (1) + API banners
    return 1 + widget.banners.length;
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

    return Container(
      constraints: BoxConstraints(
        minHeight: kIsWeb ? 340 : 220,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kIsWeb ? 32 : 20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kIsWeb ? 32 : 20),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: totalBanners,
              itemBuilder: (context, index) {
                // First banner is always the app banner
                if (index == 0) {
                  return _AppBanner(student: widget.student);
                }
                // Rest are API banners
                final apiBannerIndex = index - 1;
                if (apiBannerIndex < widget.banners.length) {
                  return _ApiBanner(
                    banner: widget.banners[apiBannerIndex],
                    student: widget.student,
                    onTap: () => _handleBannerTap(widget.banners[apiBannerIndex]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Page indicators
            if (totalBanners > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalBanners,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF582DB0).withOpacity(0.25),
            blurRadius: kIsWeb ? 28 : 12,
            spreadRadius: kIsWeb ? 2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              kIsWeb ? 48 : 28,
              kIsWeb ? 32 : 24,
              kIsWeb ? 200 : 140,
              kIsWeb ? 32 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NATDEMY',
                  style: TextStyle(
                    color: const Color(0xFFA1C95C),
                    fontSize: kIsWeb ? 56 : 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: kIsWeb ? 4 : 1),
                Text(
                  'Any Time Any Where',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: kIsWeb ? 20 : 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: kIsWeb ? 16 : 8),
                Text(
                  'Welcome, ${student.name.isEmpty ? 'Student' : student.name} 👋',
                  style: TextStyle(
                    color: const Color(0xFFA1C95C),
                    fontSize: kIsWeb ? 28 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: kIsWeb ? 8 : 4),
                Text(
                  'Your learning journey starts here',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: kIsWeb ? 20 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            right: kIsWeb ? 32 : 16,
            top: kIsWeb ? 24 : 16,
            bottom: kIsWeb ? 24 : 16,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/natdemy_logo2.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// API Banner (from API)
class _ApiBanner extends StatelessWidget {
  const _ApiBanner({required this.banner, required this.student, this.onTap});

  final AppBanner banner;
  final Student student;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = banner.thumbnail != null && banner.thumbnail!.isNotEmpty;

    if (!hasThumbnail) {
      // No API banner image provided — fall back to the default app banner design.
      return GestureDetector(
        onTap: onTap,
        child: _AppBanner(student: student),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF582DB0).withOpacity(0.25),
              blurRadius: kIsWeb ? 28 : 12,
              spreadRadius: kIsWeb ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image if available
            if (banner.thumbnail != null && banner.thumbnail!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  banner.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _AppBanner(student: student);
                  },
                ),
              )
            else
              Container(
                color: const Color(0xFF582DB0),
              ),
            // Overlay gradient for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF582DB0).withOpacity(0.7),
                    const Color(0xFF8B5CF6).withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Banner title/content
            Padding(
              padding: EdgeInsets.fromLTRB(
                kIsWeb ? 48 : 28,
                kIsWeb ? 32 : 24,
                kIsWeb ? 48 : 28,
                kIsWeb ? 32 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: kIsWeb ? 42 : 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


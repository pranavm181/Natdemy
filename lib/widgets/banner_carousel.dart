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
        minHeight: kIsWeb ? 200 : 160,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      constraints: BoxConstraints(
        minHeight: kIsWeb ? 200 : 160,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF582DB0),
            const Color(0xFF7C3AED),
            const Color(0xFF8B5CF6),
            const Color(0xFF9333EA),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(kIsWeb ? 32 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF582DB0).withOpacity(0.4),
            blurRadius: kIsWeb ? 40 : 20,
            spreadRadius: kIsWeb ? 3 : 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kIsWeb ? 32 : 20),
      child: Stack(
        children: [
            // Natdemy logo in background
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/natdemy_logo2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
            // Animated gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA1C95C).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              top: 40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 48 : (isSmallScreen ? 20 : 28),
                vertical: kIsWeb ? 20 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
              children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1C95C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Premium Learning Platform',
                  style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 10 : (kIsWeb ? 13 : 11),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: kIsWeb ? 8 : (isSmallScreen ? 6 : 8)),
                  // Main title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFA1C95C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'NATDEMY',
                  style: TextStyle(
                        color: Colors.white,
                        fontSize: kIsWeb ? 48 : (isSmallScreen ? 28 : 36),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                ),
                  SizedBox(height: kIsWeb ? 4 : 3),
                  // Tagline
                Text(
                    'Learn Any Time, Any Where',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: kIsWeb ? 18 : (isSmallScreen ? 12 : 14),
                    fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: kIsWeb ? 8 : (isSmallScreen ? 6 : 8)),
                  // Welcome text in row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : (kIsWeb ? 16 : 14),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          student.name.isEmpty ? 'Student' : student.name,
                          style: TextStyle(
                            color: const Color(0xFFA1C95C),
                            fontSize: kIsWeb ? 24 : (isSmallScreen ? 18 : 22),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                      ),
                    ],
                  ),
                  SizedBox(height: kIsWeb ? 8 : (isSmallScreen ? 6 : 8)),
                  // CTA with icon
                  Row(
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: const Color(0xFFA1C95C),
                        size: isSmallScreen ? 12 : (kIsWeb ? 18 : 16),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                  'Your learning journey starts here',
                  style: TextStyle(
                            color: Colors.white,
                            fontSize: kIsWeb ? 16 : (isSmallScreen ? 11 : 13),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
                      ),
                    ],
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


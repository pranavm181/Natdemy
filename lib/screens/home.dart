import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/student.dart';
import '../data/course_catalog.dart';
import '../data/course_stream.dart';
import '../data/joined_courses.dart';
import '../data/auth_helper.dart';
import '../utils/course_utils.dart';
import '../utils/image_utils.dart';
import '../utils/responsive.dart';
import '../widgets/rating_stars.dart';
import '../widgets/main_drawer.dart';
import '../widgets/theme_loading_indicator.dart';
import '../utils/animations.dart';
import '../api/course_service.dart';
import '../api/contact_service.dart';
import '../api/student_service.dart';
import '../api/testimonial_service.dart';
import '../api/banner_service.dart';
import '../data/testimonial.dart';
import '../data/banner.dart';
import '../widgets/banner_carousel.dart';
import 'all_courses_page.dart';
import 'course_detail.dart';
import 'edit_profile_screen.dart';
import 'loginscreen.dart';
import 'my_courses.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.student});

  final Student student;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  bool _isInitialized = false;
  late Student _currentStudent;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    _initializeCourses();
  }

  Future<void> _initializeCourses() async {
    // Remove delay - not needed, platform channels are ready by initState
    // Parallelize API calls for better performance
    await Future.wait([
      // Load courses in background
      JoinedCourses.instance.initialize(_currentStudent.email),
      // Refresh student data in parallel
      _refreshStudentDataInBackground(),
    ]);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  Future<void> _refreshStudentDataInBackground() async {
    try {
      final apiStudent = await StudentService.fetchStudentByEmail(_currentStudent.email);
      if (apiStudent != null && mounted) {
        setState(() {
          _currentStudent = apiStudent;
        });
        // Save updated data (non-blocking)
        AuthHelper.saveLoginData(apiStudent).catchError((e) {
          debugPrint('Error saving login data: $e');
        });
      }
    } catch (e) {
      debugPrint('Error refreshing student data: $e');
    }
  }

  void _updateStudent(Student updatedStudent) {
    setState(() {
      _currentStudent = updatedStudent;
    });
  }
  
  Future<void> _refreshStudentData() async {
    try {
      final apiStudent = await StudentService.fetchStudentByEmail(_currentStudent.email);
      if (apiStudent != null && mounted) {
        setState(() {
          _currentStudent = apiStudent;
        });
        // Save updated data
        await AuthHelper.saveLoginData(apiStudent);
      }
    } catch (e) {
      debugPrint('Error refreshing student data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(student: _currentStudent),
      MyCoursesScreen(student: _currentStudent),
      ProfileTab(
        student: _currentStudent,
        onProfileUpdated: _updateStudent,
      ),
    ];

    return Scaffold(
      drawer: kIsWeb ? null : MainDrawer(
        student: _currentStudent,
        onNavigateToHome: () => setState(() => _currentIndex = 0),
        onNavigateToMyCourses: () => setState(() => _currentIndex = 1),
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
      ),
      body: kIsWeb ? Row(
        children: [
          // Sidebar Navigation for Web
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Card at Top
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF582DB0).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: ImageUtils.getProfileImageProvider(_currentStudent.profileImagePath),
                          child: ImageUtils.hasProfileImage(_currentStudent.profileImagePath)
                              ? null
                              : const Icon(Icons.person, size: 40, color: Color(0xFF582DB0)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      Text(
                        _currentStudent.name.isEmpty ? 'Student' : _currentStudent.name,
                        style: const TextStyle(
                          color: Colors.white,
                                fontSize: 22,
                          fontWeight: FontWeight.w700,
                                height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentStudent.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Navigation Items
                _buildNavItem(Icons.home_outlined, 'Home', 0),
                const SizedBox(height: 12),
                _buildNavItem(Icons.menu_book_outlined, 'Courses', 1),
                const SizedBox(height: 12),
                _buildNavItem(Icons.person_outline, 'Profile', 2),
                const Spacer(),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  await JoinedCourses.instance.clear();
                                  await AuthHelper.clearLoginData();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                },
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // NATDEMY Logo at Bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      // Logo Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF582DB0).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: const Size(64, 64),
                          painter: _NatdemyLogoPainter(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Logo Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'NATD',
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 8,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 6,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MY',
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Any Time Any Where',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: pages[_currentIndex],
          ),
        ],
      ) : pages[_currentIndex],
      bottomNavigationBar: kIsWeb ? null : Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF582DB0),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              backgroundColor: Colors.transparent,
              color: Colors.white,
              activeColor: const Color(0xFFA1C95C),
              tabBackgroundColor: const Color(0xFFA1C95C).withOpacity(0.2),
              gap: 8,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              curve: Curves.easeInOut,
              tabs: const [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.menu_book_outlined,
                  text: 'My Courses',
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                // Just change the tab - let MyCoursesScreen handle its own loading
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ),
      ),
      extendBody: !kIsWeb,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF582DB0).withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF582DB0).withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: InkWell(
          onTap: () {
            if (index == 1) {
              JoinedCourses.instance.initialize(_currentStudent.email);
            }
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF582DB0).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF582DB0) : Colors.grey[600],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF582DB0) : Colors.grey[700],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _NatdemyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF582DB0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create flowing N shape with rounded corners
    final path = Path();
    
    // Left vertical line (rounded)
    path.moveTo(6, 8);
    path.quadraticBezierTo(6, 6, 8, 6);
    path.lineTo(8, 34);
    path.quadraticBezierTo(8, 36, 6, 36);
    
    // Diagonal connection (flowing curve)
    path.moveTo(8, 8);
    path.quadraticBezierTo(18, 18, 28, 28);
    path.quadraticBezierTo(30, 30, 32, 30);
    
    // Right vertical line (rounded)
    path.moveTo(32, 8);
    path.quadraticBezierTo(32, 6, 34, 6);
    path.lineTo(34, 34);
    path.quadraticBezierTo(34, 36, 32, 36);
    
    canvas.drawPath(path, paint);
    
    // Arrow at top right (integrated into N)
    final arrowPaint = Paint()
      ..color = const Color(0xFF582DB0)
      ..style = PaintingStyle.fill;
    
    final arrowPath = Path();
    arrowPath.moveTo(30, 4);
    arrowPath.lineTo(34, 8);
    arrowPath.lineTo(38, 4);
    arrowPath.lineTo(34, 0);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.student});

  final Student student;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;
  ContactInfo _contactInfo = ContactInfo.getDefault();
  bool _isLoadingContact = true;
  List<Testimonial> _testimonials = [];
  bool _isLoadingTestimonials = true;
  List<AppBanner> _banners = [];
  bool _isLoadingBanners = true;
  late final PageController _testimonialPageController;
  int _currentTestimonialIndex = 0;
  static const int _bannerPageChunk = 3;
  static const int _testimonialPageChunk = 3;
  int _visibleBannerCount = 0;
  int _visibleTestimonialCount = 0;

  double _calculateTestimonialTextWidth(double cardWidth) {
    final double padding = kIsWeb ? 16 : 12;
    final double quotePadding = kIsWeb ? 8 : 6;
    final double quoteIconSize = kIsWeb ? 24 : 20;
    final double quoteContainerWidth = (quotePadding * 2) + quoteIconSize;
    final double sideSpacing = (kIsWeb ? 12 : 10) * 2;
    final double contentWidth =
        cardWidth - (padding * 2) - (quoteContainerWidth * 2) - sideSpacing;
    return contentWidth.clamp(48.0, cardWidth);
  }

  double _calculateTestimonialCardHeight(
    double cardWidth,
    Testimonial testimonial,
    BuildContext context,
  ) {
    final double textWidth = _calculateTestimonialTextWidth(cardWidth);
    final textStyle = TextStyle(
      fontSize: kIsWeb ? 14.5 : 12.5,
      color: Colors.grey[800],
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: testimonial.content.trim(), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);

    final double quotePadding = kIsWeb ? 8 : 6;
    final double quoteIconSize = kIsWeb ? 24 : 20;
    final double quoteHeight = (quotePadding * 2) + quoteIconSize;

    final double verticalPadding = (kIsWeb ? 14 : 10) * 2;
    final double headerHeight = math.max(kIsWeb ? 36 : 32, (kIsWeb ? 18 : 16) * 2);
    const double spacingAfterHeader = 16;
    final double textBlockHeight = math.max(textPainter.height, quoteHeight);
    final double spacingBelowText = kIsWeb ? 22 : 18;

    final double totalHeight = verticalPadding +
        headerHeight +
        spacingAfterHeader +
        textBlockHeight +
        spacingBelowText +
        (kIsWeb ? 36 : 28);

    final double minHeight = kIsWeb ? 260.0 : 230.0;
    final double maxHeight = MediaQuery.of(context).size.height * (kIsWeb ? 0.85 : 0.9);

    return totalHeight.clamp(minHeight, maxHeight);
  }

  List<AppBanner> get _displayedBanners {
    if (_banners.isEmpty || _visibleBannerCount <= 0 || _visibleBannerCount >= _banners.length) {
      return _banners;
    }
    return _banners.take(_visibleBannerCount).toList();
  }

  List<Testimonial> get _displayedTestimonials {
    if (_testimonials.isEmpty ||
        _visibleTestimonialCount <= 0 ||
        _visibleTestimonialCount >= _testimonials.length) {
      return _testimonials;
    }
    return _testimonials.take(_visibleTestimonialCount).toList();
  }

  void _resetBannerPagination() {
    _visibleBannerCount = _banners.isEmpty ? 0 : math.min(_bannerPageChunk, _banners.length);
  }

  void _resetTestimonialPagination() {
    _visibleTestimonialCount =
        _testimonials.isEmpty ? 0 : math.min(_testimonialPageChunk, _testimonials.length);
    _currentTestimonialIndex = 0;
    if (_testimonialPageController.hasClients && _visibleTestimonialCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_testimonialPageController.hasClients) {
          _testimonialPageController.jumpToPage(0);
        }
      });
    }
  }

  void _loadMoreBannersChunk() {
    if (_banners.isEmpty) return;
    if (_visibleBannerCount >= _banners.length) return;
    setState(() {
      _visibleBannerCount =
          math.min(_visibleBannerCount + _bannerPageChunk, _banners.length);
    });
  }

  void _loadMoreTestimonialsChunk() {
    if (_testimonials.isEmpty) return;
    if (_visibleTestimonialCount >= _testimonials.length) return;
    setState(() {
      _visibleTestimonialCount = math.min(
        _visibleTestimonialCount + _testimonialPageChunk,
        _testimonials.length,
      );
    });
  }

  void _handleBannerPageChanged(int index) {
    if (_visibleBannerCount < _banners.length) {
      final threshold = math.max(0, _visibleBannerCount - 2);
      if (index >= threshold) {
        _loadMoreBannersChunk();
      }
    }
  }

  void _handleTestimonialPageChanged(int index) {
    setState(() {
      _currentTestimonialIndex = index;
    });
    if (_visibleTestimonialCount < _testimonials.length) {
      final threshold = math.max(0, _visibleTestimonialCount - 2);
      if (index >= threshold) {
        _loadMoreTestimonialsChunk();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _testimonialPageController = PageController();
    // Load all data in parallel for better performance
    _loadCourses();
    _loadContactInfo();
    _loadTestimonials();
    _loadBanners();
  }

  Future<void> _loadContactInfo() async {
    try {
      final contactInfo = await ContactService.getContactInfo();
      if (mounted) {
        setState(() {
          _contactInfo = contactInfo;
          _isLoadingContact = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contact info: $e');
      if (mounted) {
        setState(() {
          _isLoadingContact = false;
        });
      }
    }
  }

  Future<void> _loadTestimonials() async {
    try {
      // Load from cache first (fast), then refresh from API in background
      final testimonials = await TestimonialService.fetchTestimonials(forceRefresh: false);
      
      if (mounted) {
        setState(() {
          _testimonials = testimonials;
          _isLoadingTestimonials = false;
          _resetTestimonialPagination();
        });
      }
      
      // Refresh from API in background (non-blocking)
      TestimonialService.fetchTestimonials(forceRefresh: true).then((updatedTestimonials) {
        if (mounted) {
          setState(() {
            _testimonials = updatedTestimonials;
            _resetTestimonialPagination();
          });
        }
      }).catchError((e) {
        debugPrint('⚠️ Background testimonials refresh failed: $e');
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading testimonials: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingTestimonials = false;
        });
      }
    }
  }

  Future<void> _loadBanners({bool forceNetwork = false}) async {
    try {
      if (!forceNetwork && _banners.isNotEmpty) {
        debugPrint('📦 Using cached banners (count: ${_banners.length})');
      }
      final banners = await BannerService.fetchBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
          _resetBannerPagination();
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading banners: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
        });
      }
    }
  }

  Future<void> _loadCourses({bool forceNetwork = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load courses: hit API directly when explicitly refreshed, else load cached first
      final courses = await CourseService.fetchCourses(forceRefresh: forceNetwork);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _courses = courses;
          if (courses.isEmpty) {
            _errorMessage = 'No courses available.';
          } else {
            _errorMessage = null;
            debugPrint('✅ Displaying ${courses.length} courses');
          }
        });
      }
      
      if (!forceNetwork) {
        // Refresh from API in background (non-blocking)
        CourseService.fetchCourses(forceRefresh: true).then((updatedCourses) {
          if (mounted && updatedCourses.isNotEmpty) {
            setState(() {
              _courses = updatedCourses;
            });
          }
        }).catchError((e) {
          debugPrint('⚠️ Background refresh failed: $e');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading courses in UI: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load courses. Please try again.';
          _isLoading = false;
          _courses = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _testimonialPageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  // Helper function to clean WhatsApp number - keep +91 prefix, remove other non-digit characters
  String _cleanWhatsAppNumber(String number) {
    // Remove spaces and other characters, but keep digits
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    // If number doesn't start with 91, add it
    if (!cleaned.startsWith('91')) {
      return '91$cleaned';
    }
    return cleaned;
  }

  Future<void> _showContactDialog(BuildContext context) async {
    const whatsappNum1 = '919207666615';
    const whatsappNum2 = '919207666614';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF582DB0),
                  width: 2,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F0FF),
                    Color(0xFFFFFFFF),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33582DB0),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFA5ED),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4D23AA),
                                Color(0xFF6435C8),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40582DB0),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Need help?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF582DB0),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Our team is ready on WhatsApp to answer any questions.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF4C3B82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF582DB0)),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                            label: const Text(
                              'WhatsApp 1',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () async {
                              final message = Uri.encodeComponent('i am contacting from the natdemy app for some support');
                              final uri = Uri.parse('https://wa.me/$whatsappNum1?text=$message');
                              Navigator.of(sheetContext).pop();
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                            label: const Text(
                              'WhatsApp 2',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () async {
                              final message = Uri.encodeComponent('i am contacting from the natdemy app for some support');
                              final uri = Uri.parse('https://wa.me/$whatsappNum2?text=$message');
                              Navigator.of(sheetContext).pop();
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE0D2FF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF582DB0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Service Hours',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF452D8A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Mon - Sat · 9:00 AM to 6:00 PM',
                                  style: TextStyle(
                                    color: Color(0xFF5B4A9B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerPlaceholder(BuildContext context) {
    final aspectRatio = kIsWeb ? 16 / 3 : 16 / 4;
    final borderRadius = BorderRadius.circular(kIsWeb ? 36 : 24);

    return Container(
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
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'assets/images/natdemy_logo2.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = _courses;
    final courses = allCourses.length > 4 ? allCourses.take(4).toList() : List<Course>.from(allCourses);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          leading: kIsWeb ? null : Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          elevation: kIsWeb ? 0 : 0,
          shadowColor: Colors.transparent,
          flexibleSpace: kIsWeb ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
          ) : null,
          title: Image.asset(
            'assets/images/natdemy_logo.png',
            height: 45,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading logo image: $error');
              // Fallback if image not found - show text version
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: kIsWeb ? 48 : 40,
                        height: kIsWeb ? 50 : 40,
                        child: CustomPaint(
                          painter: _NatdemyLogoPainter(),
                        ),
                      ),
                      SizedBox(width: kIsWeb ? 16 : 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'NATD',
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: kIsWeb ? 28 : 24,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 6 : 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: kIsWeb ? 12 : 10,
                                  height: kIsWeb ? 4 : 3.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                SizedBox(height: kIsWeb ? 4 : 3),
                                Container(
                                  width: kIsWeb ? 16 : 14,
                                  height: kIsWeb ? 4 : 3.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                SizedBox(height: kIsWeb ? 4 : 3),
                                Container(
                                  width: kIsWeb ? 12 : 10,
                                  height: kIsWeb ? 4 : 3.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1C95C),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MY',
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: kIsWeb ? 28 : 24,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: kIsWeb ? 6 : 3),
                  Text(
                    'Any Time Any Where',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: kIsWeb ? 13 : 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            },
          ),
          centerTitle: true,
        ),

        // Banner Carousel Section
        SliverToBoxAdapter(
          child: AppAnimations.fadeScaleIn(
            delay: 100,
            child: Responsive.constrainWidth(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kIsWeb ? Responsive.getHorizontalPadding(context) : 16,
                  kIsWeb ? 40 : 16,
                  kIsWeb ? Responsive.getHorizontalPadding(context) : 16,
                  kIsWeb ? 32 : 16,
                ),
                child: Builder(
                  builder: (context) {
                    final bannerList = _displayedBanners;
                    if (_isLoadingBanners || bannerList.isEmpty) {
                      return _buildBannerPlaceholder(context);
                    }
                    return BannerCarousel(
                      banners: bannerList,
                      student: widget.student,
                      onPageChanged: _handleBannerPageChanged,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Courses Header
        SliverToBoxAdapter(
          child: AppAnimations.fadeSlideIn(
            child: Responsive.constrainWidth(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.getHorizontalPadding(context),
                  16,
                  Responsive.getHorizontalPadding(context),
                  8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'POPULAR COURSES',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: kIsWeb ? 28 : null,
                      ),
                    ),
                    Row(
                      children: [
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ThemePulsingDotsIndicator(size: 8.0, spacing: 8.0),
                          )
                        else if (_errorMessage == null)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _refreshAllHomeData,
                            tooltip: 'Refresh home data',
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              SlidePageRoute(
                                builder: (_) => const AllCoursesPage(),
                                direction: SlideDirection.right,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF000000),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Error Message
        if (_errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _loadCourses(forceNetwork: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Courses Grid
        if (_isLoading && courses.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: ThemePulsingDotsIndicator(size: 12.0, spacing: 16.0),
              ),
            ),
          )
        else if (courses.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.getHorizontalPadding(context)),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.getGridColumns(context),
                mainAxisSpacing: Responsive.getCardSpacing(context),
                crossAxisSpacing: Responsive.getCardSpacing(context),
                childAspectRatio: kIsWeb ? 0.65 : 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final c = courses[index];
                  return AnimatedListItem(
                    index: index,
                    child: _CourseCard(course: c),
                  );
                },
                childCount: courses.length,
              ),
            ),
          ),

        // Contact Section Header
        SliverToBoxAdapter(
          child: AppAnimations.slideInLeft(
            delay: 200,
            child: Responsive.constrainWidth(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.getHorizontalPadding(context),
                  32,
                  Responsive.getHorizontalPadding(context),
                  8,
                ),
                child: Text(
                  'NEED ASSISTANCE?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontSize: kIsWeb ? 28 : null,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Contact and WhatsApp Cards Section (Side by Side on Web)
        SliverToBoxAdapter(
          child: AppAnimations.fadeSlideIn(
            delay: 250,
            child: Responsive.constrainWidth(
              Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.getHorizontalPadding(context),
                16,
                Responsive.getHorizontalPadding(context),
                16,
              ),
              child: kIsWeb ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Contact Card
                Expanded(
                  child: FutureBuilder(
                    future: ContactService.getContactInfo(),
                    builder: (context, snapshot) {
                      final contactInfo = snapshot.data ?? ContactInfo.getDefault();

                      return Card(
                        elevation: kIsWeb ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20),
                        ),
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(kIsWeb ? 32 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(kIsWeb ? 16 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                        ),
                                        child: Icon(
                                          Icons.support_agent,
                                          color: Colors.white,
                                          size: kIsWeb ? 28 : 24,
                                        ),
                                      ),
                                      SizedBox(width: kIsWeb ? 16 : 12),
                                      Expanded(
                                        child: Text(
                                          'Get in Touch',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: kIsWeb ? 26 : 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: kIsWeb ? 20 : 16),
                                  Text(
                                    'Our support team is here to help you 24/7. Reach out anytime for assistance with your learning journey.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: kIsWeb ? 16 : 14,
                                      height: 1.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: kIsWeb ? 32 : 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        if (!context.mounted) return;
                                        await _showContactDialog(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                          vertical: kIsWeb ? 20 : 16,
                                          horizontal: kIsWeb ? 24 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                          side: const BorderSide(color: Color(0xFF582DB0), width: 1),
                                        ),
                                      ),
                                      icon: AppAnimations.pulse(
                                        child: FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          size: kIsWeb ? 24 : 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: Text(
                                        'WhatsApp Support',
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                    },
                  ),
                ),
                // Spacing between cards
                SizedBox(width: kIsWeb ? 24 : 0),
        // WhatsApp Group Card
                Expanded(
            child: Card(
                    elevation: kIsWeb ? 10 : 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
                      side: BorderSide(
                        color: const Color(0xFF582DB0),
                        width: kIsWeb ? 2.5 : 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                        padding: EdgeInsets.all(kIsWeb ? 32 : 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                                  padding: EdgeInsets.all(kIsWeb ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                            ),
                                  child: AppAnimations.pulse(
                                    child: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.white,
                                      size: kIsWeb ? 32 : 28,
                                    ),
                                  ),
                          ),
                                SizedBox(width: kIsWeb ? 20 : 16),
                                Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Join Our Community',
                                  style: TextStyle(
                                    color: Colors.black,
                                          fontSize: kIsWeb ? 26 : 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                      SizedBox(height: kIsWeb ? 6 : 4),
                                Text(
                                  'Connect with fellow learners',
                                  style: TextStyle(
                                    color: Colors.white70,
                                          fontSize: kIsWeb ? 16 : 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                            SizedBox(height: kIsWeb ? 24 : 20),
                            Text(
                        'Join our WhatsApp group to get updates, share knowledge, and connect with other students on their learning journey.',
                        style: TextStyle(
                          color: Colors.white,
                                fontSize: kIsWeb ? 16 : 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                            SizedBox(height: kIsWeb ? 24 : 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final link = _contactInfo.whatsappGroupLink ?? 'https://chat.whatsapp.com/LpNUsxNbGPq4eFgVgFGSL2?mode=wwt';
                            final uri = Uri.parse(link);
                            await _launchUrl(uri);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF25D366),
                            elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    vertical: kIsWeb ? 20 : 16,
                                    horizontal: kIsWeb ? 24 : 16,
                                  ),
                            shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                  ),
                                ),
                                icon: AppAnimations.pulse(
                                  child: FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    size: kIsWeb ? 24 : 20,
                                  ),
                                ),
                                label: Text(
                            'Join WhatsApp Group',
                            style: TextStyle(
                                    fontSize: kIsWeb ? 18 : 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
              ],
            ) : Column(
              children: [
                // Contact Card
                FutureBuilder(
                  future: ContactService.getContactInfo(),
                  builder: (context, snapshot) {
                    final contactInfo = snapshot.data ?? ContactInfo.getDefault();

                    return Card(
                      elevation: kIsWeb ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                            padding: EdgeInsets.all(kIsWeb ? 32 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(kIsWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                      ),
                                      child: Icon(
                                        Icons.support_agent,
                                        color: Colors.white,
                                        size: kIsWeb ? 28 : 24,
                                      ),
                                    ),
                                    SizedBox(width: kIsWeb ? 16 : 12),
                                    Expanded(
                                      child: Text(
                                        'Get in Touch',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: kIsWeb ? 26 : 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: kIsWeb ? 20 : 16),
                                Text(
                                  'Our support team is here to help you 24/7. Reach out anytime for assistance with your learning journey.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: kIsWeb ? 16 : 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: kIsWeb ? 32 : 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (!context.mounted) return;
                                      await _showContactDialog(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 20 : 16,
                                        horizontal: kIsWeb ? 24 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                        side: const BorderSide(color: Color(0xFF582DB0), width: 1),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      size: kIsWeb ? 24 : 20,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'WhatsApp Support',
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                  },
                ),
                const SizedBox(height: 16),
                // WhatsApp Group Card
                Card(
                  elevation: kIsWeb ? 10 : 8,
                  shadowColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
                    side: BorderSide(
                      color: const Color(0xFF582DB0),
                      width: kIsWeb ? 2.5 : 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(kIsWeb ? 32 : 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(kIsWeb ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.white,
                                  size: kIsWeb ? 32 : 28,
                                ),
                              ),
                              SizedBox(width: kIsWeb ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join Our Community',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: kIsWeb ? 26 : 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: kIsWeb ? 6 : 4),
                                    Text(
                                      'Connect with fellow learners',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: kIsWeb ? 16 : 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: kIsWeb ? 24 : 20),
                          Text(
                            'Join our WhatsApp group to get updates, share knowledge, and connect with other students on their learning journey.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: kIsWeb ? 16 : 14,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: kIsWeb ? 24 : 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final link = _contactInfo.whatsappGroupLink ?? 'https://chat.whatsapp.com/LpNUsxNbGPq4eFgVgFGSL2?mode=wwt';
                                final uri = Uri.parse(link);
                                await _launchUrl(uri);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF25D366),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: kIsWeb ? 20 : 16,
                                  horizontal: kIsWeb ? 24 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                                ),
                              ),
                              icon: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                size: kIsWeb ? 24 : 20,
                              ),
                              label: Text(
                                'Join WhatsApp Group',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
        ),

        // Testimonials Section - At the End
        SliverToBoxAdapter(
          child: AppAnimations.fadeScaleIn(
            delay: 300,
            child: Responsive.constrainWidth(
              Container(
                margin: EdgeInsets.only(
                  top: 48,
                  bottom: 24,
                  left: Responsive.getHorizontalPadding(context),
                  right: Responsive.getHorizontalPadding(context),
                ),
                child: Column(
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF582DB0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Student Testimonials',
                            style: TextStyle(
                              fontSize: kIsWeb ? 26 : 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Testimonials Carousel
                    if (_isLoadingTestimonials)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: ThemePulsingDotsIndicator(size: 12.0, spacing: 16.0),
                        ),
                      )
                    else if (_testimonials.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.format_quote, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No testimonials available yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: kIsWeb ? 620 : 340,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final testimonialsToShow = _displayedTestimonials;
                                if (testimonialsToShow.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final double cardWidth = constraints.maxWidth;
                                final int safeIndex = _currentTestimonialIndex
                                    .clamp(0, testimonialsToShow.length - 1)
                                    .toInt();
                                final Testimonial activeTestimonial = testimonialsToShow[safeIndex];
                                final double cardHeight = _calculateTestimonialCardHeight(
                                  cardWidth,
                                  activeTestimonial,
                                  context,
                                );

                                return Column(
                                  children: [
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: PageView.builder(
                                          controller: _testimonialPageController,
                                          itemCount: testimonialsToShow.length,
                                          onPageChanged: _handleTestimonialPageChanged,
                                          itemBuilder: (context, index) {
                                            final testimonial = testimonialsToShow[index];
                                            return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: AnimatedListItem(
                                          index: index,
                                          child: MouseRegion(
                                            cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                  borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(kIsWeb ? 0.08 : 0.05),
                                                    blurRadius: kIsWeb ? 16 : 10,
                                                    spreadRadius: kIsWeb ? 1 : 0,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: kIsWeb ? 16 : 12,
                                                  vertical: kIsWeb ? 14 : 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: kIsWeb ? 18 : 16,
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
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: kIsWeb ? 16 : 14,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                testimonial.name,
                                                                style: TextStyle(
                                                                  fontSize: kIsWeb ? 15 : 13,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: const Color(0xFF1E293B),
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (testimonial.department != null &&
                                                                  testimonial.department!.isNotEmpty)
                                                                Text(
                                                                  testimonial.department!,
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: kIsWeb ? 12 : 11,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        SizedBox(
                                                                width: kIsWeb ? 80 : 68,
                                                          child: RatingStars(
                                                            rating: testimonial.rating.toDouble(),
                                                            starSize: kIsWeb ? 14 : 12,
                                                            showValue: false,
                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.all(kIsWeb ? 8 : 6),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF582DB0).withOpacity(0.1),
                                                            borderRadius:
                                                                BorderRadius.circular(kIsWeb ? 12 : 10),
                                                          ),
                                                          child: Icon(
                                                            Icons.format_quote,
                                                            color: const Color(0xFF582DB0),
                                                            size: kIsWeb ? 24 : 20,
                                                          ),
                                                        ),
                                                        SizedBox(width: kIsWeb ? 12 : 10),
                                                        Expanded(
                                                          child: Text(
                                                                  testimonial.content.trim(),
                                                            style: TextStyle(
                                                              fontSize: kIsWeb ? 14.5 : 12.5,
                                                              color: Colors.grey[800],
                                                              height: 1.45,
                                                              fontWeight: FontWeight.w400,
                                                              letterSpacing: 0.2,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: kIsWeb ? 12 : 10),
                                                        Container(
                                                          padding: EdgeInsets.all(kIsWeb ? 8 : 6),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF582DB0).withOpacity(0.1),
                                                            borderRadius:
                                                                BorderRadius.circular(kIsWeb ? 12 : 10),
                                                          ),
                                                          child: Transform.rotate(
                                                                  angle: math.pi,
                                                            child: Icon(
                                                              Icons.format_quote,
                                                              color: const Color(0xFF582DB0),
                                                              size: kIsWeb ? 24 : 20,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                          SizedBox(height: kIsWeb ? 22 : 18),
                                                        ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(testimonialsToShow.length, (index) {
                                        final isActive = index == _currentTestimonialIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          height: 8,
                                          width: isActive ? 24 : 8,
                                          decoration: BoxDecoration(
                                            color: isActive ? const Color(0xFF582DB0) : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: kIsWeb ? 40 : MediaQuery.of(context).padding.bottom + 100,
          ),
        ),
      ],
    );
  }
  Future<void> _refreshAllHomeData() async {
    debugPrint('🔄 Refreshing entire home data...');
    setState(() {
      _isLoading = true;
      _isLoadingContact = true;
      _isLoadingTestimonials = true;
      _isLoadingBanners = true;
      _errorMessage = null;
    });

    await Future.wait(<Future>[
      _loadCourses(forceNetwork: true),
      _loadContactInfo(),
      _loadTestimonials(),
      _loadBanners(forceNetwork: true),
    ]);
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kIsWeb ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        side: BorderSide(
          color: const Color(0xFF582DB0),
          width: kIsWeb ? 2.5 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            SlidePageRoute(
              builder: (_) => CourseDetailPage(course: course),
              direction: SlideDirection.right,
            ),
          );
        },
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        child: MouseRegion(
          cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(kIsWeb ? 24 : 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(kIsWeb ? 14 : 10),
                      child: Image.network(
                        CourseService.getFullImageUrl(course.thumbnailUrl),
                        width: kIsWeb ? 96 : 68,
                        height: kIsWeb ? 96 : 68,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            CourseUtils.getCourseIcon(course.title),
                            color: const Color(0xFFA1C95C),
                            size: kIsWeb ? 76 : 54,
                          );
                        },
                      ),
                    )
                  : Icon(
                      CourseUtils.getCourseIcon(course.title),
                      color: const Color(0xFFA1C95C),
                      size: kIsWeb ? 76 : 54,
                    ),
              SizedBox(height: kIsWeb ? 14 : 10),
              Flexible(
                child: Text(
                  course.title,
                  textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: kIsWeb ? 18 : 15,
                    fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
                SizedBox(height: kIsWeb ? 8 : 6),
              RatingStars(
                rating: course.rating,
                  textStyle: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: kIsWeb ? 14 : 12,
                  fontWeight: FontWeight.w600,
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



class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppAnimations.scaleIn(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.student, required this.onProfileUpdated});

  final Student student;
  final Function(Student) onProfileUpdated;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Student _student;
  bool _isLoadingStreams = false;
  List<JoinedCourse> _assignedStreams = [];
  String? _streamError;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadAssignedStreams();
  }

  @override
  void didUpdateWidget(ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_student, widget.student)) {
      _student = widget.student;
      _loadAssignedStreams();
    }
  }

  Future<void> _loadAssignedStreams() async {
    setState(() {
      _isLoadingStreams = true;
      _streamError = null;
    });

    try {
      // Ensure courses are loaded
      await JoinedCourses.instance.initialize(_student.email, forceRefresh: false);
      
      // Get all joined courses (enrollments) for the student
      final joinedCourses = JoinedCourses.instance.all;
      
      // Also check student's registered course/stream from student data
      try {
        final studentData = await StudentService.fetchStudentDataWithCourseStream(_student.email);
        if (studentData != null) {
          final courseId = studentData['course_id'];
          final streamId = studentData['stream_id'];
          
          if (courseId != null && streamId != null) {
            // Find course and stream details
            final allCourses = await CourseService.fetchCourses();
            final streams = CourseService.cachedStreams;
            
            Course? registeredCourse;
            CourseStream? registeredStream;
            
            try {
              final courseIdInt = courseId is int ? courseId : int.tryParse(courseId.toString());
              final streamIdInt = streamId is int ? streamId : int.tryParse(streamId.toString());
              
              if (courseIdInt != null) {
                registeredCourse = allCourses.firstWhere((c) => c.id == courseIdInt);
              }
              if (streamIdInt != null) {
                registeredStream = streams.firstWhere((s) => s.id == streamIdInt);
              }
              
              // Check if this course-stream combination is already in joinedCourses
              final exists = joinedCourses.any((c) => 
                c.courseId == registeredCourse?.id && c.streamId == registeredStream?.id);
              
              if (!exists && registeredCourse != null && registeredStream != null) {
                // Check verified status (API uses 'verification' field)
                final rawVerified = studentData['verification'] ?? studentData['verified'];
                bool? studentVerified;
                if (rawVerified != null) {
                  if (rawVerified is bool) {
                    studentVerified = rawVerified;
                  } else if (rawVerified is String) {
                    studentVerified = rawVerified.toLowerCase() == 'true';
                  } else if (rawVerified is int) {
                    studentVerified = rawVerified == 1;
                  }
                }
                
                // Add registered course/stream (locked or unlocked based on verified)
                final isEnrolled = studentVerified == true;
                final registeredJoinedCourse = JoinedCourse(
                  courseId: registeredCourse.id,
                  title: registeredCourse.title,
                  color: registeredCourse.color,
                  description: registeredCourse.description.isNotEmpty 
                      ? registeredCourse.description 
                      : 'Description not available.',
                  rating: registeredCourse.rating,
                  streamId: registeredStream.id,
                  streamName: registeredStream.name,
                  whatYoullLearn: registeredCourse.whatYoullLearn,
                  thumbnailUrl: registeredCourse.thumbnailUrl,
                  durationHours: registeredCourse.durationHours,
                  duration: registeredCourse.duration,
                  studentCount: registeredCourse.studentCount,
                  price: registeredCourse.price,
                  lessonsCount: registeredCourse.lessonsCount,
                  chaptersCount: registeredCourse.chaptersCount,
                  topics: registeredCourse.topics,
                  isEnrolled: isEnrolled, // Locked if verified != true
                );
                joinedCourses.add(registeredJoinedCourse);
              }
            } catch (e) {
              debugPrint('⚠️ Could not find registered course/stream: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching student course/stream data: $e');
      }
      
      // Filter to get unique course-stream combinations
      final Map<String, JoinedCourse> uniqueStreams = {};
      for (final course in joinedCourses) {
        if (course.streamId != null && course.streamName != null) {
          final key = '${course.courseId}_${course.streamId}';
          if (!uniqueStreams.containsKey(key)) {
            uniqueStreams[key] = course;
          }
        }
      }
      
      debugPrint('📊 Assigned Streams Summary:');
      debugPrint('   Total joined courses: ${joinedCourses.length}');
      debugPrint('   Unique streams found: ${uniqueStreams.length}');
      uniqueStreams.values.forEach((course) {
        debugPrint('   - ${course.title} > ${course.streamName} (${course.isEnrolled ? "Active" : "Locked"})');
      });
      
      setState(() {
        _assignedStreams = uniqueStreams.values.toList();
        _isLoadingStreams = false;
      });
    } catch (e) {
      debugPrint('Error loading assigned streams: $e');
      setState(() {
        _streamError = 'Failed to load streams';
        _isLoadingStreams = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;

    return Scaffold(
      drawer: MainDrawer(
        student: student,
        onNavigateToHome: () {
          // Navigate to HomeShell and switch to Home tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeShell(student: student),
            ),
          );
        },
        onNavigateToMyCourses: () {
          // Navigate to HomeShell and switch to My Courses tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeShell(student: student),
            ),
          );
        },
        onNavigateToProfile: () {
          // Already on Profile page
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF582DB0).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: ImageUtils.getProfileImageProvider(student.profileImagePath),
                      child: ImageUtils.hasProfileImage(student.profileImagePath)
                          ? null
                          : const Icon(Icons.person, size: 40, color: Color(0xFF582DB0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name.isEmpty ? 'Student' : student.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        if (student.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                student.phone,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Assigned Streams Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF582DB0).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF582DB0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.stream,
                          color: Color(0xFF582DB0),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Assigned Streams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingStreams)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: ThemePulsingDotsIndicator(size: 10.0, spacing: 12.0),
                      ),
                    )
                  else if (_streamError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _streamError!,
                              style: TextStyle(color: Colors.red[600]),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadAssignedStreams,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_assignedStreams.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.stream_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No streams assigned',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Streams will appear here once assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._assignedStreams.map((course) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF582DB0).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF582DB0).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF582DB0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: Color(0xFF582DB0),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      course.streamName ?? 'No stream',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (course.isEnrolled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Locked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile Edit Section
            _ProfileSection(
              title: 'Account',
              children: [
                _ProfileMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          student: student,
                          onProfileUpdated: widget.onProfileUpdated,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Settings Section
            _ProfileSection(
              title: 'Settings',
              children: [
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings coming soon!'),
                        backgroundColor: Color(0xFF582DB0),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Support Section
            _ProfileSection(
              title: 'Support',
              children: [
                _ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'About Natdemy',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await JoinedCourses.instance.clear();
                              await AuthHelper.clearLoginData();
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF582DB0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF582DB0), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}


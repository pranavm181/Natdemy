import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/student.dart';
import '../providers/student_provider.dart';
import '../providers/courses_provider.dart';
import '../providers/banners_provider.dart';
import '../providers/testimonials_provider.dart';
import '../data/course_catalog.dart';
import '../data/course_stream.dart';
import '../data/joined_courses.dart';
import '../widgets/shimmer_loading.dart';
import '../data/auth_helper.dart';
import '../utils/course_utils.dart';
import '../utils/image_utils.dart';
import '../utils/responsive.dart';
import '../widgets/rating_stars.dart';
import '../widgets/main_drawer.dart';
import '../widgets/theme_loading_indicator.dart';
import '../utils/animations.dart';
import '../utils/haptic_feedback.dart';
import '../widgets/fade_in_content.dart';
import '../api/course_service.dart';
import '../api/contact_service.dart';
import '../api/student_service.dart';
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
    // Only refresh student data - courses will load when My Courses page is opened
    _refreshStudentDataInBackground();
    
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
                      colors: [AppColors.primary, AppColors.primaryLight],
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
                        color: AppColors.primary.withOpacity(0.2),
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
                              : const Icon(Icons.person, size: 40, color: AppColors.primary),
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
                        side: BorderSide(color: AppColors.error, width: 2),
                        foregroundColor: AppColors.error,
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
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
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
                              color: AppColors.textPrimary,
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
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 8,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 6,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MY',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                          color: AppColors.textSecondary,
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
      bottomNavigationBar: kIsWeb ? null : Builder(
        builder: (context) {
          final width = MediaQuery.of(context).size.width;
          final isSmallScreen = width < 360.w; // Responsive check
          
          // Responsive values - using flutter_screenutil where appropriate
          final horizontalMargin = AppSpacing.lg.w; 
          final bottomMargin = AppSpacing.md.h;
          final borderRadius = 20.r;
          final containerPaddingH = AppSpacing.md.w;
          final containerPaddingV = AppSpacing.sm.h;
          final navPaddingH = AppSpacing.md.w;
          final navPaddingV = AppSpacing.md.h;
          final gap = AppSpacing.sm.w;
          
          // Check if keyboard is open
          if (MediaQuery.of(context).viewInsets.bottom > 0) {
            return const SizedBox.shrink();
          }
          
          return Container(
            margin: EdgeInsets.only(
              left: horizontalMargin,
              right: horizontalMargin,
              bottom: bottomMargin,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: containerPaddingH,
                  vertical: containerPaddingV,
                ),
                child: GNav(
                  backgroundColor: Colors.transparent,
                  color: Colors.white, // White for unselected text and icons
                  activeColor: AppColors.accent, // Green/Accent for selected text and icons
                  tabBackgroundColor: AppColors.accent.withOpacity(0.2),
                  gap: gap,
                  padding: EdgeInsets.symmetric(
                    horizontal: navPaddingH,
                    vertical: navPaddingV,
                  ),
                  curve: Curves.easeInOut,
                  tabs: [
                    GButton(
                      icon: Icons.home_outlined,
                      text: 'Home',
                      iconSize: 24.r,
                      textStyle: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Unselected text color
                      ),
                    ),
                    GButton(
                      icon: Icons.menu_book_outlined,
                      text: 'My Courses',
                      iconSize: 24.r,
                      textStyle: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Unselected text color
                      ),
                    ),
                    GButton(
                      icon: Icons.person_outline,
                      text: 'Profile',
                      iconSize: 24.r,
                      textStyle: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Unselected text color
                      ),
                    ),
                  ],
                  selectedIndex: _currentIndex,
                  onTabChange: (index) {
                    // Just change the tab - let MyCoursesScreen handle its own loading
                    HapticUtils.subtleTap();
                    setState(() => _currentIndex = index);
                  },
                ),
              ),
            ),
          );
        },
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
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
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
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
      ..color = AppColors.primary
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
      ..color = AppColors.primary
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
  const HomeTab({super.key, this.student});

  final Student? student; // Optional - can use Provider instead

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  ContactInfo _contactInfo = ContactInfo.getDefault();
  bool _isLoadingContact = true;
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
    // Updated calculation for new neat design
    final double textWidth = cardWidth - (kIsWeb ? 56 : 40); // Account for padding
    final textStyle = TextStyle(
      fontSize: kIsWeb ? 15.5 : 14,
      color: const Color(0xFF1E293B),
      height: 1.6,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: testimonial.content.trim(), style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 6,
    )..layout(maxWidth: textWidth);

    // New design components
    final double verticalPadding = (kIsWeb ? 28 : 20) * 2; // Top and bottom padding
    final double topSectionHeight = kIsWeb ? 44 : 40; // Quote icon + rating row
    const double spacingAfterTop = 20;
    final double textBlockHeight = textPainter.height;
    const double spacingAfterText = 20;
    const double dividerHeight = 1;
    const double spacingAfterDivider = 16;
    final double authorSectionHeight = kIsWeb ? 56 : 48; // Profile + name section

    final double totalHeight = verticalPadding +
        topSectionHeight +
        spacingAfterTop +
        textBlockHeight +
        spacingAfterText +
        dividerHeight +
        spacingAfterDivider +
        authorSectionHeight;

    final double minHeight = kIsWeb ? 280.0 : 260.0;
    final double maxHeight = MediaQuery.of(context).size.height * (kIsWeb ? 0.75 : 0.7);

    return totalHeight.clamp(minHeight, maxHeight);
  }

  List<AppBanner> _getDisplayedBanners(BannersProvider bannersProvider) {
    final banners = bannersProvider.banners;
    if (banners.isEmpty || _visibleBannerCount <= 0 || _visibleBannerCount >= banners.length) {
      return banners;
    }
    return banners.take(_visibleBannerCount).toList();
  }

  List<Testimonial> _getDisplayedTestimonials(TestimonialsProvider testimonialsProvider) {
    final testimonials = testimonialsProvider.testimonials;
    if (testimonials.isEmpty ||
        _visibleTestimonialCount <= 0 ||
        _visibleTestimonialCount >= testimonials.length) {
      return testimonials;
    }
    return testimonials.take(_visibleTestimonialCount).toList();
  }

  void _resetBannerPagination(BannersProvider bannersProvider) {
    final banners = bannersProvider.banners;
    _visibleBannerCount = banners.isEmpty ? 0 : math.min(_bannerPageChunk, banners.length);
  }

  void _resetTestimonialPagination(TestimonialsProvider testimonialsProvider) {
    final testimonials = testimonialsProvider.testimonials;
    _visibleTestimonialCount =
        testimonials.isEmpty ? 0 : math.min(_testimonialPageChunk, testimonials.length);
    _currentTestimonialIndex = 0;
    if (_testimonialPageController.hasClients && _visibleTestimonialCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_testimonialPageController.hasClients) {
          _testimonialPageController.jumpToPage(0);
        }
      });
    }
  }

  void _loadMoreBannersChunk(BannersProvider bannersProvider) {
    final banners = bannersProvider.banners;
    if (banners.isEmpty) return;
    if (_visibleBannerCount >= banners.length) return;
    setState(() {
      _visibleBannerCount =
          math.min(_visibleBannerCount + _bannerPageChunk, banners.length);
    });
  }

  void _loadMoreTestimonialsChunk(TestimonialsProvider testimonialsProvider) {
    final testimonials = testimonialsProvider.testimonials;
    if (testimonials.isEmpty) return;
    if (_visibleTestimonialCount >= testimonials.length) return;
    setState(() {
      _visibleTestimonialCount = math.min(
        _visibleTestimonialCount + _testimonialPageChunk,
        testimonials.length,
      );
    });
  }

  void _handleBannerPageChanged(int index, BannersProvider bannersProvider) {
    final banners = bannersProvider.banners;
    if (_visibleBannerCount < banners.length) {
      final threshold = math.max(0, _visibleBannerCount - 2);
      if (index >= threshold) {
        _loadMoreBannersChunk(bannersProvider);
      }
    }
  }

  void _handleTestimonialPageChanged(int index, TestimonialsProvider testimonialsProvider) {
    setState(() {
      _currentTestimonialIndex = index;
    });
    final testimonials = testimonialsProvider.testimonials;
    if (_visibleTestimonialCount < testimonials.length) {
      final threshold = math.max(0, _visibleTestimonialCount - 2);
      if (index >= threshold) {
        _loadMoreTestimonialsChunk(testimonialsProvider);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _testimonialPageController = PageController();
    // Initialize providers and load only banners and testimonials (not courses)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bannersProvider = Provider.of<BannersProvider>(context, listen: false);
      final testimonialsProvider = Provider.of<TestimonialsProvider>(context, listen: false);
      
      // Load banners first (from cache - instant), then testimonials
      bannersProvider.fetchBanners().then((_) {
        if (mounted) {
          _resetBannerPagination(bannersProvider);
        }
      });
      
      // Load testimonials and contact info in parallel
      Future.wait([
        testimonialsProvider.fetchTestimonials(),
        _loadContactInfo(),
      ]).then((_) {
        if (mounted) {
          _resetTestimonialPagination(testimonialsProvider);
        }
      });
    });
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
    const whatsappNum = '919207666615'; // +91 92076 66615
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.r,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.surface,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 24.r,
                    offset: Offset(0, 12.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Container(
                          width: 52.r,
                          height: 52.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 20.r,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 26.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help?',
                                style: AppTextStyles.headline2.copyWith(
                                  fontSize: 20.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Our team is ready on WhatsApp to answer any questions.',
                                style: AppTextStyles.body2.copyWith(
                                  fontSize: 14.sp,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.primary, size: 24.r),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsapp,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                        ),
                        icon: FaIcon(FontAwesomeIcons.whatsapp, size: 18.r),
                        label: Text(
                          'WhatsApp Support',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                        onPressed: () async {
                          final message = Uri.encodeComponent('i am contacting from the natdemy app for some support');
                          final uri = Uri.parse('https://wa.me/$whatsappNum?text=$message');
                          Navigator.of(sheetContext).pop();
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                          width: 1.r,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Hours',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Mon - Sat · 9:00 AM to 6:00 PM',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.sp,
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
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          leading: kIsWeb ? null : Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.textPrimary, size: 24.r),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          flexibleSpace: kIsWeb ? Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
            ),
          ) : null,
          title: Image.asset(
            'assets/images/natdemy_logo.png',
            height: 45.h,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading logo image: $error');
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: kIsWeb ? 48 : 40.w,
                        height: kIsWeb ? 50 : 40.h,
                        child: CustomPaint(
                          painter: _NatdemyLogoPainter(),
                        ),
                      ),
                      SizedBox(width: kIsWeb ? 16 : 12.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'NATD',
                            style: AppTextStyles.headline1.copyWith(
                              fontSize: kIsWeb ? 28 : 24.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 6 : 4.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: kIsWeb ? 12 : 10.w,
                                  height: kIsWeb ? 4 : 3.5.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1.5.r),
                                  ),
                                ),
                                SizedBox(height: kIsWeb ? 4 : 3.h),
                                Container(
                                  width: kIsWeb ? 16 : 14.w,
                                  height: kIsWeb ? 4 : 3.5.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1.5.r),
                                  ),
                                ),
                                SizedBox(height: kIsWeb ? 4 : 3.h),
                                Container(
                                  width: kIsWeb ? 12 : 10.w,
                                  height: kIsWeb ? 4 : 3.5.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(1.5.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MY',
                            style: AppTextStyles.headline1.copyWith(
                              fontSize: kIsWeb ? 28 : 24.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: kIsWeb ? 6 : 3.h),
                  Text(
                    'Any Time Any Where',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: kIsWeb ? 13 : 11.sp,
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
                  kIsWeb ? Responsive.getHorizontalPadding(context) : AppSpacing.md.w,
                  kIsWeb ? 40 : AppSpacing.md.h,
                  kIsWeb ? Responsive.getHorizontalPadding(context) : AppSpacing.md.w,
                  kIsWeb ? 32 : AppSpacing.md.h,
                ),
                child: Consumer<BannersProvider>(
                  builder: (context, bannersProvider, child) {
                    final bannerList = _getDisplayedBanners(bannersProvider);
                    if (bannersProvider.isLoading || bannerList.isEmpty) {
                      return _buildBannerPlaceholder(context);
                    }
                    return FadeInContent(
                      delay: const Duration(milliseconds: 100),
                      child: Consumer<StudentProvider>(
                        builder: (context, studentProvider, child) {
                          return BannerCarousel(
                            useProvider: true,
                            onPageChanged: (index) {
                              HapticUtils.subtleTap();
                              _handleBannerPageChanged(index, bannersProvider);
                            },
                          );
                        },
                      ),
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
                  AppSpacing.md.h,
                  Responsive.getHorizontalPadding(context),
                  AppSpacing.xs.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'POPULAR COURSES',
                      style: AppTextStyles.headline2.copyWith(
                        fontSize: kIsWeb ? 28 : 20.sp,
                      ),
                    ),
                    Row(
                      children: [
                        Consumer<CoursesProvider>(
                          builder: (context, coursesProvider, child) {
                            if (coursesProvider.isLoading)
                              return Padding(
                                padding: EdgeInsets.all(AppSpacing.xs.r),
                                child: const ThemePulsingDotsIndicator(size: 8.0, spacing: 8.0),
                              );
                            else
                              return IconButton(
                                icon: Icon(Icons.refresh, size: 20.r, color: AppColors.textPrimary),
                                onPressed: () {
                                  coursesProvider.fetchCourses(forceRefresh: true);
                                  Provider.of<BannersProvider>(context, listen: false).fetchBanners();
                                  Provider.of<TestimonialsProvider>(context, listen: false).fetchTestimonials(forceRefresh: true);
                                },
                                tooltip: 'Refresh home data',
                              );
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            HapticUtils.navigationTap();
                            Navigator.of(context).push(
                              BouncePageRoute(
                                builder: (_) => const AllCoursesPage(),
                                direction: SlideDirection.right,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            textStyle: AppTextStyles.button.copyWith(fontSize: 14.sp),
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

        // Courses Grid (lazy loaded - only when home tab is viewed)
        Consumer<CoursesProvider>(
          builder: (context, coursesProvider, child) {
            // Load courses lazily when this widget is first built
            if (!coursesProvider.hasCourses && !coursesProvider.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                coursesProvider.fetchCourses();
              });
            }
            
            final allCourses = coursesProvider.courses;
            final courses = allCourses.length > 4 ? allCourses.take(4).toList() : List<Course>.from(allCourses);
            
            if (coursesProvider.isLoading && courses.isEmpty)
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.getHorizontalPadding(context)),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.getGridColumns(context),
                    mainAxisSpacing: Responsive.getCardSpacing(context),
                    crossAxisSpacing: Responsive.getCardSpacing(context),
                    childAspectRatio: kIsWeb ? 0.65 : 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const CourseCardShimmer(),
                    childCount: 4,
                  ),
                ),
              );
            else if (coursesProvider.error != null && courses.isEmpty)
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              coursesProvider.error!,
                              style: AppTextStyles.body2.copyWith(color: Colors.orange.shade900, fontSize: 14.sp),
                            ),
                          ),
                          TextButton(
                            onPressed: () => coursesProvider.fetchCourses(forceRefresh: true),
                            child: Text('Retry', style: AppTextStyles.button.copyWith(color: Colors.orange.shade900)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            else if (courses.isEmpty)
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 64.r, color: Colors.grey[400]),
                        SizedBox(height: 16.h),
                        Text(
                          'No courses available',
                          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary, fontSize: 16.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            else
              return SliverPadding(
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
                      return FadeInContent(
                        delay: Duration(milliseconds: 100 + (index * 50)),
                        child: AnimatedListItem(
                          index: index,
                          child: _CourseCard(course: c),
                        ),
                      );
                    },
                    childCount: courses.length,
                  ),
                ),
              );
          },
        ),

        // Contact Section Header
        SliverToBoxAdapter(
          child: AppAnimations.slideInLeft(
            delay: 200,
            child: Responsive.constrainWidth(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.getHorizontalPadding(context),
                  kIsWeb ? 40 : AppSpacing.xl.h,
                  Responsive.getHorizontalPadding(context),
                  AppSpacing.sm.h,
                ),
                child: Text(
                  'NEED ASSISTANCE?',
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: kIsWeb ? 28 : 20.sp,
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
                AppSpacing.md.h,
                Responsive.getHorizontalPadding(context),
                AppSpacing.md.h,
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
                          borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20.r),
                        ),
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20.r),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(kIsWeb ? 32 : 24.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(kIsWeb ? 16 : 12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                        ),
                                        child: Icon(
                                          Icons.support_agent,
                                          color: Colors.white,
                                          size: kIsWeb ? 28 : 24.r,
                                        ),
                                      ),
                                      SizedBox(width: kIsWeb ? 16 : 12.w),
                                      Expanded(
                                        child: Text(
                                          'Get in Touch',
                                          style: AppTextStyles.headline2.copyWith(
                                            color: Colors.white,
                                            fontSize: kIsWeb ? 26 : 22.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: kIsWeb ? 20 : 16.h),
                                  Text(
                                    'Our support team is here to help you 24/7. Reach out anytime for assistance with your learning journey.',
                                    style: AppTextStyles.body1.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: kIsWeb ? 16 : 14.sp,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: kIsWeb ? 32 : 24.h),
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
                                          vertical: kIsWeb ? 20 : 16.h,
                                          horizontal: kIsWeb ? 24 : 16.w,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                          side: const BorderSide(color: Colors.white24, width: 1),
                                        ),
                                      ),
                                      icon: AppAnimations.pulse(
                                        child: FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          size: kIsWeb ? 24 : 20.r,
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: Text(
                                        'WhatsApp Support',
                                        style: AppTextStyles.button.copyWith(
                                          fontSize: kIsWeb ? 18 : 16.sp,
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
                    shadowColor: AppColors.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
                      side: BorderSide(
                        color: AppColors.primary,
                        width: kIsWeb ? 2.5 : 2.r,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
                        gradient: const LinearGradient(
                          colors: [AppColors.whatsapp, Color(0xFF128C7E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                child: Padding(
                  padding: EdgeInsets.all(kIsWeb ? 32 : 24.r),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(kIsWeb ? 16 : 12.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                            ),
                            child: AppAnimations.pulse(
                              child: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                                size: kIsWeb ? 32 : 28.r,
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
                      shadowColor: AppColors.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20.r),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20.r),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                            padding: EdgeInsets.all(kIsWeb ? 32 : 24.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(kIsWeb ? 16 : 12.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                      ),
                                      child: Icon(
                                        Icons.support_agent,
                                        color: Colors.white,
                                        size: kIsWeb ? 28 : 24.r,
                                      ),
                                    ),
                                    SizedBox(width: kIsWeb ? 16 : 12.w),
                                    Expanded(
                                      child: Text(
                                        'Get in Touch',
                                        style: AppTextStyles.headline2.copyWith(
                                          color: Colors.white,
                                          fontSize: kIsWeb ? 26 : 22.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: kIsWeb ? 20 : 16.h),
                                Text(
                                  'Our support team is here to help you 24/7. Reach out anytime for assistance with your learning journey.',
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: kIsWeb ? 16 : 14.sp,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: kIsWeb ? 32 : 24.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      if (!context.mounted) return;
                                      await _showContactDialog(context);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 20 : 16.h,
                                        horizontal: kIsWeb ? 24 : 16.w,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                        side: const BorderSide(color: Colors.white24, width: 1),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      size: kIsWeb ? 24 : 20.r,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'WhatsApp Support',
                                      style: AppTextStyles.button.copyWith(
                                        fontSize: kIsWeb ? 18 : 16.sp,
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
                  shadowColor: AppColors.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: kIsWeb ? 2.5 : 2.r,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
                      gradient: const LinearGradient(
                        colors: [AppColors.whatsapp, Color(0xFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(kIsWeb ? 32 : 24.r),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(kIsWeb ? 16 : 12.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                ),
                                child: AppAnimations.pulse(
                                  child: FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    color: Colors.white,
                                    size: kIsWeb ? 32 : 28.r,
                                  ),
                                ),
                              ),
                              SizedBox(width: kIsWeb ? 20 : 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join Our Community',
                                      style: AppTextStyles.headline2.copyWith(
                                        color: Colors.white,
                                        fontSize: kIsWeb ? 26 : 22.sp,
                                      ),
                                    ),
                                    SizedBox(height: kIsWeb ? 6 : 4.h),
                                    Text(
                                      'Connect with fellow learners',
                                      style: AppTextStyles.body2.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: kIsWeb ? 16 : 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: kIsWeb ? 24 : 20.h),
                          Text(
                            'Join our WhatsApp group to get updates, share knowledge, and connect with other students on their learning journey.',
                            style: AppTextStyles.body1.copyWith(
                              color: Colors.white,
                              fontSize: kIsWeb ? 16 : 14.sp,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: kIsWeb ? 24 : 20.h),
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
                                foregroundColor: AppColors.whatsapp,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: kIsWeb ? 20 : 16.h,
                                  horizontal: kIsWeb ? 24 : 16.w,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
                                ),
                              ),
                              icon: AppAnimations.pulse(
                                child: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  size: kIsWeb ? 24 : 20.r,
                                ),
                              ),
                              label: Text(
                                'Join WhatsApp Group',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: kIsWeb ? 18 : 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whatsapp,
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
                    // Section Header - Redesigned
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: kIsWeb ? 36 : 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(3.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF582DB0).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STUDENT TESTIMONIALS',
                                  style: AppTextStyles.headline2.copyWith(
                                    fontSize: kIsWeb ? 24 : 20.sp,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 60,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: kIsWeb ? 28 : 24),

                    // Testimonials Carousel - Redesigned
                    Consumer<TestimonialsProvider>(
                      builder: (context, testimonialsProvider, child) {
                        if (testimonialsProvider.isLoading)
                          return Padding(
                            padding: EdgeInsets.all(32.r),
                            child: Center(
                              child: ShimmerLoading(
                                width: kIsWeb ? 700 : double.infinity,
                                height: 200.h,
                                borderRadius: 20.r,
                              ),
                            ),
                          );
                        else if (testimonialsProvider.testimonials.isEmpty)
                          return Padding(
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
                          );
                        else
                          return FadeInContent(
                            delay: const Duration(milliseconds: 150),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: kIsWeb ? 700 : double.infinity,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final testimonialsToShow = _getDisplayedTestimonials(testimonialsProvider);
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
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOutCubic,
                                            child: SizedBox(
                                              height: cardHeight,
                                              child: PageView.builder(
                                                controller: _testimonialPageController,
                                                itemCount: testimonialsToShow.length,
                                                onPageChanged: (index) {
                                                  HapticUtils.subtleTap();
                                                  _handleTestimonialPageChanged(index, testimonialsProvider);
                                                },
                                                itemBuilder: (context, index) {
                                                  final testimonial = testimonialsToShow[index];
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: AnimatedListItem(
                                                      index: index,
                                                      child: _NeatTestimonialCard(
                                                        testimonial: testimonial,
                                                        isActive: index == safeIndex,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Page indicators - improved design
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(testimonialsToShow.length, (index) {
                                              final isActive = index == _currentTestimonialIndex;
                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                                height: 6,
                                                width: isActive ? 32 : 6,
                                                decoration: BoxDecoration(
                                                  color: isActive 
                                                      ? const Color(0xFF582DB0) 
                                                      : Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(3),
                                                  boxShadow: isActive
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFF582DB0).withOpacity(0.4),
                                                            blurRadius: 8,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : null,
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
                            ),
                          );
                      },
                    ),
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
    debugPrint('🔄 Refreshing home data (banners and testimonials)...');
    final bannersProvider = Provider.of<BannersProvider>(context, listen: false);
    final testimonialsProvider = Provider.of<TestimonialsProvider>(context, listen: false);
    
    await Future.wait(<Future>[
      bannersProvider.fetchBanners(),
      testimonialsProvider.fetchTestimonials(forceRefresh: true),
      _loadContactInfo(),
    ]);
  }
}

// Neat Testimonial Card Widget
class _NeatTestimonialCard extends StatelessWidget {
  const _NeatTestimonialCard({
    required this.testimonial,
    this.isActive = true,
  });

  final Testimonial testimonial;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20.r),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5.r,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: isWeb ? 20 : 16.r,
              spreadRadius: 0,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 28 : 20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top section with quote icon and rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative quote icon
                  Container(
                    padding: EdgeInsets.all(isWeb ? 10 : 8.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isWeb ? 14 : 12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.format_quote,
                      color: Colors.white,
                      size: 24.r,
                    ),
                  ),
                  const Spacer(),
                  // Rating stars
                  RatingStars(
                    rating: testimonial.rating.toDouble(),
                    starSize: (isWeb ? 16 : 14).r,
                    showValue: false,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // Testimonial content
              Expanded(
                child: Text(
                  testimonial.content.trim(),
                  style: AppTextStyles.body2.copyWith(
                    fontSize: isWeb ? 15.5 : 14.sp,
                    color: AppColors.textPrimary,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 20.h),
              // Divider
              Container(
                height: 1.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Author info
              Row(
                children: [
                  // Profile image with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2.5.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: (isWeb ? 24 : 20).r,
                      backgroundColor: AppColors.primary,
                      backgroundImage: testimonial.imageUrl != null &&
                              testimonial.imageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(testimonial.imageUrl!)
                          : null,
                      child: testimonial.imageUrl == null ||
                              testimonial.imageUrl!.isEmpty
                          ? Text(
                              testimonial.name.isNotEmpty
                                  ? testimonial.name[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.headline1.copyWith(
                                color: Colors.white,
                                fontSize: (isWeb ? 18 : 16).sp,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Name and department
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimonial.name,
                          style: AppTextStyles.body1.copyWith(
                            fontSize: (isWeb ? 16 : 14).sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2.w,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (testimonial.department != null &&
                            testimonial.department!.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            testimonial.department!,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: (isWeb ? 13 : 12).sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return Card(
      elevation: kIsWeb ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
        side: BorderSide(
          color: AppColors.primary,
          width: kIsWeb ? 2.5 : 2.r,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticUtils.navigationTap();
          Navigator.of(context).push(
            BouncePageRoute(
              builder: (_) => CourseDetailPage(course: course),
              direction: SlideDirection.right,
            ),
          );
        },
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
        child: MouseRegion(
          cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(kIsWeb ? 24 : 12.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16.r),
              color: AppColors.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(kIsWeb ? 14 : 10.r),
                        child: CachedNetworkImage(
                          imageUrl: CourseService.getFullImageUrl(course.thumbnailUrl),
                          width: kIsWeb ? 96 : 68.w,
                          height: kIsWeb ? 96 : 68.h,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return Icon(
                              CourseUtils.getCourseIcon(course.title),
                              color: AppColors.accent,
                              size: kIsWeb ? 76 : 54.r,
                            );
                          },
                          memCacheWidth: (kIsWeb ? 192 : 136 * (ScreenUtil().pixelRatio ?? 1.0)).toInt(),
                          memCacheHeight: (kIsWeb ? 192 : 136 * (ScreenUtil().pixelRatio ?? 1.0)).toInt(),
                        ),
                      )
                    : Icon(
                        CourseUtils.getCourseIcon(course.title),
                        color: AppColors.accent,
                        size: kIsWeb ? 76 : 54.r,
                      ),
                SizedBox(height: kIsWeb ? 14 : 10.h),
                Flexible(
                  child: Text(
                    course.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body1.copyWith(
                      fontSize: (isWeb ? 18 : 15).sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: kIsWeb ? 8 : 6.h),
                RatingStars(
                  rating: course.rating,
                  textStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: kIsWeb ? 14 : 12.sp,
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
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 20.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.7),
                size: 20.r,
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
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.textPrimary, size: 24.r),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'PROFILE',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
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
              margin: EdgeInsets.all(16.r),
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.r),
                    ),
                    child: CircleAvatar(
                      radius: 40.r,
                      backgroundColor: Colors.white,
                      backgroundImage: ImageUtils.getProfileImageProvider(student.profileImagePath),
                      child: ImageUtils.hasProfileImage(student.profileImagePath)
                          ? null
                          : Icon(Icons.person, size: 40.r, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name.isEmpty ? 'Student' : student.name,
                          style: AppTextStyles.headline2.copyWith(
                            color: Colors.white,
                            fontSize: 22.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          student.email,
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                        ),
                        if (student.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16.r,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                student.phone,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
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
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.stream,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Assigned Streams',
                        style: AppTextStyles.headline2.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.textPrimary,
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
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            Text(
                              _streamError!,
                              style: AppTextStyles.body2.copyWith(color: AppColors.error),
                            ),
                            SizedBox(height: 8.h),
                            TextButton.icon(
                              onPressed: _loadAssignedStreams,
                              icon: Icon(Icons.refresh, size: 18.r),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_assignedStreams.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            Icon(
                              Icons.stream_outlined,
                              size: 48.r,
                              color: AppColors.divider,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No streams assigned',
                              style: AppTextStyles.body1.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Streams will appear here once assigned',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._assignedStreams.map((course) => Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.menu_book,
                                  color: AppColors.primary,
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: AppTextStyles.body1.copyWith(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      course.streamName ?? 'No stream',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 13.sp,
                                        color: AppColors.textSecondary,
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
                                    'LOCKED',
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
                    HapticUtils.navigationTap();
                    Navigator.of(context).push(
                      BouncePageRoute(
                        builder: (_) => EditProfileScreen(
                          student: student,
                          onProfileUpdated: widget.onProfileUpdated,
                        ),
                        direction: SlideDirection.right,
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
                        backgroundColor: AppColors.primary,
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
                      BouncePageRoute(
                        builder: (_) => const AboutPage(),
                        direction: SlideDirection.right,
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
                      BouncePageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                        direction: SlideDirection.right,
                      ),
                    );
                  },
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: EdgeInsets.all(16.r),
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
                    side: BorderSide(color: AppColors.error, width: 2.r),
                    foregroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.logout, size: 20.r),
                  label: Text(
                    'Sign Out',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.error,
                    ),
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
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: Text(
            title,
            style: AppTextStyles.headline2.copyWith(
              fontSize: 16.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          elevation: 1,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Column(
            children: children,
          ),
        ),
        SizedBox(height: 16.h),
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
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.divider, size: 20.r),
          ],
        ),
      ),
    );
  }
}


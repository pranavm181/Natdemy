import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/student.dart';
import '../data/joined_courses.dart';
import '../data/auth_helper.dart';
import '../api/student_service.dart';
import '../api/banner_service.dart';
import '../api/home_service.dart';
import 'home.dart';
import 'loginscreen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoController.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Start initializations in parallel
    final cacheInit = BannerService.initializeCache();
    final prefsInit = SharedPreferences.getInstance();
    final homeFetch = HomeService.fetchHomeData(forceRefresh: true);
    
    // Wait for animation to complete AND essential initializations
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)), // Animation buffer
      cacheInit,
      prefsInit,
      homeFetch.catchError((e) {
        debugPrint('⚠️ Pre-fetch home data failed: $e');
        return <String, dynamic>{};
      }),
    ]);

    try {
      final prefs = await prefsInit;
      final savedEmail = prefs.getString('user_email');
      final savedName = prefs.getString('user_name');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!mounted) return;

      if (isLoggedIn && savedEmail != null && savedName != null) {
        // Create student from saved data immediately (don't wait for API)
        final student = Student(
          name: savedName,
          email: savedEmail,
          phone: prefs.getString('user_phone') ?? '',
          profileImagePath: prefs.getString('user_profile_image'),
        );
        
        // Navigate immediately, load data in parallel in background
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeShell(student: student),
          ),
        );
        
        // Load student data from API in background (non-blocking)
        // Courses will be loaded only when My Courses page is opened
        StudentService.fetchStudentByEmail(savedEmail).then((apiStudent) {
          if (apiStudent != null) {
            AuthHelper.saveLoginData(apiStudent).catchError((e) {
              debugPrint('Error saving login data: $e');
            });
          }
        }).catchError((e) {
          debugPrint('Error fetching student data from API: $e');
        });
      } else {
        // User not logged in, show onboarding
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      if (!mounted) return;
      // On error, show onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow effect
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.surface.withOpacity(0.3),
                          blurRadius: 40.r,
                          spreadRadius: 10.r,
                        ),
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.2),
                          blurRadius: 60.r,
                          spreadRadius: 20.r,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/LIGHT LOGO-NAT.png',
                      height: 140.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school,
                            size: 80.r,
                            color: AppColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              // Tagline with slide animation
              SlideTransition(
                position: _taglineSlideAnimation,
                child: FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Any Time Any Where',
                        style: AppTextStyles.title2.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.surface.withOpacity(0.95),
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Container(
                        width: 60.w,
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60.h),
              // Loading indicator with fade
              FadeTransition(
                opacity: _loadingFadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 50.w,
                      height: 50.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.surface.withOpacity(0.9),
                        ),
                        backgroundColor: AppColors.surface.withOpacity(0.2),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Text(
                      'Loading...',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.surface.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


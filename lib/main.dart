import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'screens/splash_screen.dart';
import 'providers/student_provider.dart';
import 'providers/courses_provider.dart';
import 'providers/enrolled_courses_provider.dart';
import 'providers/banners_provider.dart';
import 'providers/testimonials_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize standard web view settings if needed
  // No need to await fonts or prefs here - it blocks the cold start.
  // We handle initial setup in the SplashScreen background.
  
  // Non-blocking background setup
  unawaited(_backgroundSetup());
  
  runApp(const MyApp());
}

Future<void> _backgroundSetup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_restarted', true);
    await prefs.setString('app_last_run', DateTime.now().toIso8601String());
  } catch (e) {
    debugPrint('Error in background setup: $e');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => CoursesProvider()),
            ChangeNotifierProvider(create: (_) => EnrolledCoursesProvider()),
            ChangeNotifierProvider(create: (_) => BannersProvider()),
            ChangeNotifierProvider(create: (_) => TestimonialsProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Natdemy',
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

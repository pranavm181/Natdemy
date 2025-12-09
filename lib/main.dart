import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mark app as restarted for cache clearing
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('app_restarted', true);
  await prefs.setString('app_last_run', DateTime.now().toIso8601String());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Natdemy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF582DB0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF1E293B),
          displayColor: const Color(0xFF1E293B),
        ).copyWith(
          // Titles - Inter with italic, color, and uppercase (thicker for importance)
          headlineLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF000000),
          ),
          headlineMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
          ),
          headlineSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF0F172A),
          ),
          titleLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF000000),
          ),
          titleMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
          ),
          titleSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF0F172A),
          ),
          displayLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF000000),
          ),
          displayMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
          ),
          displaySmall: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF0F172A),
          ),
          // Body text - Lato
          bodyLarge: GoogleFonts.lato(fontWeight: FontWeight.w300),
          bodyMedium: GoogleFonts.lato(fontWeight: FontWeight.w300),
          bodySmall: GoogleFonts.lato(fontWeight: FontWeight.w300),
          // Labels - Lato
          labelLarge: GoogleFonts.lato(fontWeight: FontWeight.w300),
          labelMedium: GoogleFonts.lato(fontWeight: FontWeight.w300),
          labelSmall: GoogleFonts.lato(fontWeight: FontWeight.w300),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF582DB0),
              width: 2,
            ),
          ),
          color: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF582DB0),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF582DB0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF582DB0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF582DB0), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
          hintStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        // Additional theme for buttons to use Lato
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.w300),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

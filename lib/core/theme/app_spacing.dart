import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  // We use .w / .h for responsive spacing, or .r for radius/padding
  // Although the rules say "xs=4, sm=8...", it's best to make them responsive or fixed?
  // The rules example uses static double but the 'Responsive Design' section suggests using .w/.h
  // However, for constants in a class, we usually can't use .w/.h directly as they need ScreenUtilInit.
  // We will define them as static methods or getters, or just raw doubles and usage happens with .w/.h
  // BUT the rules example showed static const double xs = 4.0;
  // I will follow the rules example exactly:
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Helper for responsive usage if needed, but standard is to use AppSpacing.md.w or .h in code
}

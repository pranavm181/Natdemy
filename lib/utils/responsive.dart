import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Responsive {
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Max content width for web
  static const double maxContentWidth = 1400;

  // Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (width > desktopBreakpoint) {
        return const EdgeInsets.symmetric(horizontal: 48);
      } else if (width > tabletBreakpoint) {
        return const EdgeInsets.symmetric(horizontal: 32);
      } else {
        return const EdgeInsets.symmetric(horizontal: 24);
      }
    }
    
    // Android: Adapt based on screen width
    if (width < 360) {
      // Small phones (e.g., 320px - 360px)
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (width < 600) {
      // Regular phones (360px - 600px)
      return const EdgeInsets.symmetric(horizontal: 16);
    } else {
      // Tablets and large phones (600px+)
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  // Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (width > desktopBreakpoint) {
        return 48;
      } else if (width > tabletBreakpoint) {
        return 32;
      } else {
        return 24;
      }
    }
    
    // Android: Adapt based on screen width
    if (width < 360) {
      // Small phones
      return 12;
    } else if (width < 600) {
      // Regular phones
      return 16;
    } else {
      // Tablets and large phones
      return 24;
    }
  }

  // Get number of columns for grid
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (width > desktopBreakpoint) {
        return 4;
      } else if (width > tabletBreakpoint) {
        return 3;
      } else {
        return 2;
      }
    }
    
    // Android: Adapt based on screen width
    if (width < 360) {
      // Small phones: 1 column
      return 1;
    } else if (width < 600) {
      // Regular phones: 2 columns
      return 2;
    } else {
      // Tablets and large phones: 3 columns
      return 3;
    }
  }

  // Get responsive card spacing
  static double getCardSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (width > desktopBreakpoint) {
        return 24;
      } else if (width > tabletBreakpoint) {
        return 20;
      } else {
        return 16;
      }
    }
    
    // Android: Adapt based on screen width
    if (width < 360) {
      // Small phones
      return 8;
    } else if (width < 600) {
      // Regular phones
      return 12;
    } else {
      // Tablets and large phones
      return 16;
    }
  }

  // Check if is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  // Check if is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Check if is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Get responsive font size
  static double getFontSize(BuildContext context, {required double mobile, required double tablet, required double desktop}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Constrain content width for web
  static Widget constrainWidth(Widget child, {double? maxWidth}) {
    if (!kIsWeb) {
      return child;
    }
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}



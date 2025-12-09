import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Responsive {
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Max content width for web
  static const double maxContentWidth = 1400;

  // iPhone screen width breakpoints
  // iPhone SE (1st/2nd gen): 320px
  // iPhone 6/7/8, X/11/12/13 mini: 375px
  // iPhone 6/7/8 Plus, XR: 414px
  // iPhone X/11/12/13/14: 390px
  // iPhone 14/15 Pro Max: 430px

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
    
    // Mobile (iOS iPhone & Android): Adapt based on screen width
    if (width < 360) {
      // Small phones (iPhone SE: 320px)
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (width < 600) {
      // Regular phones (iPhone 6/7/8: 375px, iPhone Plus: 414px, iPhone X/11/12/13: 390px, iPhone Pro Max: 430px)
      return const EdgeInsets.symmetric(horizontal: 16);
    } else {
      // Tablets and large phones (iPad, Android tablets)
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
    
    // Mobile (iOS iPhone & Android): Adapt based on screen width
    if (width < 360) {
      // Small phones (iPhone SE: 320px)
      return 12;
    } else if (width < 600) {
      // Regular phones (iPhone 6/7/8: 375px, iPhone Plus: 414px, iPhone X/11/12/13: 390px, iPhone Pro Max: 430px)
      return 16;
    } else {
      // Tablets and large phones (iPad, Android tablets)
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
    
    // Mobile (iOS iPhone & Android): Adapt based on screen width
    if (width < 360) {
      // Small phones (iPhone SE: 320px) - 1 column for better readability
      return 1;
    } else if (width < 600) {
      // Regular phones (iPhone 6/7/8: 375px, iPhone Plus: 414px, iPhone X/11/12/13: 390px, iPhone Pro Max: 430px) - 2 columns
      return 2;
    } else {
      // Tablets and large phones (iPad, Android tablets) - 3 columns
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
    
    // Mobile (iOS iPhone & Android): Adapt based on screen width
    if (width < 360) {
      // Small phones (iPhone SE: 320px)
      return 8;
    } else if (width < 600) {
      // Regular phones (iPhone 6/7/8: 375px, iPhone Plus: 414px, iPhone X/11/12/13: 390px, iPhone Pro Max: 430px)
      return 12;
    } else {
      // Tablets and large phones (iPad, Android tablets)
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

  // Get safe area padding for iOS (handles notch, status bar, etc.)
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Get bottom safe area padding (for iPhone X and newer with home indicator)
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Get top safe area padding (for iPhone X and newer with notch)
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  // Check if device has notch (iPhone X and newer)
  static bool hasNotch(BuildContext context) {
    return MediaQuery.of(context).padding.top > 20;
  }

  // Get responsive font size with iPhone-specific considerations
  static double getFontSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? smallPhone, // For iPhone SE and similar small devices
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      if (isDesktop(context)) {
        return desktop;
      } else if (isTablet(context)) {
        return tablet;
      } else {
        return mobile;
      }
    }
    
    // Mobile devices
    if (width < 360 && smallPhone != null) {
      // Small phones (iPhone SE: 320px)
      return smallPhone;
    } else if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
}



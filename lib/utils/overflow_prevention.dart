import 'package:flutter/material.dart';

/// Utility class to prevent overflow issues on small screens (especially iPhone SE)
class OverflowPrevention {
  /// Wrap text widgets to prevent overflow
  static Widget safeText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines ?? 1,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  /// Get responsive padding that adapts to screen size
  static EdgeInsets responsivePadding(BuildContext context, {
    double? small,
    double? medium,
    double? large,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    double padding;
    if (width < 360) {
      // Small phones (iPhone SE: 320px)
      padding = small ?? 12.0;
    } else if (width < 600) {
      // Regular phones (iPhone 6/7/8: 375px, iPhone Plus: 414px, iPhone X/11/12/13: 390px)
      padding = medium ?? 16.0;
    } else {
      // Tablets
      padding = large ?? 24.0;
    }
    
    return EdgeInsets.all(padding);
  }

  /// Wrap Row widgets to prevent overflow
  static Widget safeRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        // Wrap non-Expanded/Flexible children in Flexible to prevent overflow
        if (child is Expanded || child is Flexible) {
          return child;
        }
        // For Text widgets, wrap in Flexible
        if (child is Text) {
          return Flexible(child: child);
        }
        // For other widgets, wrap in Flexible if they might overflow
        return Flexible(child: child);
      }).toList(),
    );
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, {
    required double small,
    required double medium,
    double? large,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return small;
    } else if (width < 600) {
      return medium;
    } else {
      return large ?? medium;
    }
  }

  /// Constrain widget to prevent overflow
  static Widget constrainToScreen(Widget child, BuildContext context, {
    double? maxWidthFactor,
    double? maxHeightFactor,
  }) {
    final size = MediaQuery.of(context).size;
    final maxWidth = maxWidthFactor != null ? size.width * maxWidthFactor : size.width;
    final maxHeight = maxHeightFactor != null ? size.height * maxHeightFactor : size.height;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: child,
    );
  }
}





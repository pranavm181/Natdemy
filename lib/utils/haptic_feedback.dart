import 'package:flutter/services.dart';

/// Utility class for providing subtle haptic feedback throughout the app
class HapticUtils {
  /// Light haptic feedback - for subtle interactions (button taps, list scrolls)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - for navigation, card selections
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - for important actions (confirmations, errors)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection haptic feedback - for picker selections, switches
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate haptic feedback - for notifications, alerts
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Subtle tap feedback - optimized for most UI interactions
  static Future<void> subtleTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Navigation feedback - for page transitions
  static Future<void> navigationTap() async {
    await HapticFeedback.selectionClick();
  }

  /// Button press feedback - for primary actions
  static Future<void> buttonPress() async {
    await HapticFeedback.mediumImpact();
  }
}

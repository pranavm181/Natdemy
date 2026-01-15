import 'package:flutter/services.dart';

class ScreenRecordingService {
  static const MethodChannel _channel = MethodChannel('com.natdemy.learning/screen_recording');

  /// Enable or disable screen recording blocking
  /// 
  /// [blocked] - true to block screen recording, false to allow it
  /// 
  /// Returns true if successful, false otherwise
  static Future<bool> setScreenRecordingBlocked(bool blocked) async {
    try {
      await _channel.invokeMethod('setScreenRecordingBlocked', {'blocked': blocked});
      return true;
    } catch (e) {
      print('Error setting screen recording blocked: $e');
      return false;
    }
  }

  /// Temporarily allow screen recording for a specified duration
  /// 
  /// [duration] - Duration to allow screen recording
  /// 
  /// After the duration, screen recording will be blocked again
  static Future<void> allowScreenRecordingTemporarily(Duration duration) async {
    // Allow screen recording
    await setScreenRecordingBlocked(false);
    
    // Block it again after the duration
    Future.delayed(duration, () {
      setScreenRecordingBlocked(true);
    });
  }
}


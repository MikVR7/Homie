import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for mobile platform-specific functionality and optimizations
class MobilePlatformService {
  static const String _unsupportedMessage = 
      'This feature is only available on mobile platforms.';

  /// Check if running on mobile platform
  static bool get isMobilePlatform {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Get current mobile platform
  static MobilePlatform get currentPlatform {
    if (!isMobilePlatform) return MobilePlatform.none;
    
    if (Platform.isAndroid) return MobilePlatform.android;
    if (Platform.isIOS) return MobilePlatform.ios;
    
    return MobilePlatform.none;
  }

  /// Check if native file picker is supported
  static bool get isNativeFilePickerSupported {
    return isMobilePlatform;
  }

  /// Check if haptic feedback is supported
  static bool get isHapticFeedbackSupported {
    return isMobilePlatform;
  }

  /// Check if device orientation changes are supported
  static bool get isOrientationChangeSupported {
    return isMobilePlatform;
  }

  /// Get platform-specific features available
  static Map<String, bool> getPlatformFeatures() {
    if (!isMobilePlatform) {
      return {
        'nativeFilePicker': false,
        'hapticFeedback': false,
        'orientationChange': false,
        'touchGestures': false,
        'biometricAuth': false,
        'pushNotifications': false,
        'backgroundProcessing': false,
      };
    }

    return {
      'nativeFilePicker': isNativeFilePickerSupported,
      'hapticFeedback': isHapticFeedbackSupported,
      'orientationChange': isOrientationChangeSupported,
      'touchGestures': true,
      'biometricAuth': Platform.isAndroid || Platform.isIOS,
      'pushNotifications': Platform.isAndroid || Platform.isIOS,
      'backgroundProcessing': Platform.isAndroid || Platform.isIOS,
    };
  }

  /// Get mobile-specific configuration
  static MobileConfiguration getMobileConfiguration() {
    final platform = currentPlatform;
    
    return MobileConfiguration(
      platform: platform,
      minimumTouchTargetSize: 48.0,
      recommendedTouchTargetSize: 56.0,
      swipeThreshold: 50.0,
      longPressThreshold: const Duration(milliseconds: 500),
      doubleTapThreshold: const Duration(milliseconds: 300),
      enableHapticFeedback: isHapticFeedbackSupported,
      enableGestureNavigation: true,
      enablePullToRefresh: true,
      enableSwipeActions: true,
    );
  }

  /// Get touch target size recommendations
  static TouchTargetSizes getTouchTargetSizes() {
    return const TouchTargetSizes(
      minimum: 44.0,      // iOS minimum
      recommended: 48.0,  // Material Design minimum
      comfortable: 56.0,  // Material Design recommended
      large: 64.0,        // Accessibility recommended
    );
  }

  /// Get gesture configuration
  static GestureConfiguration getGestureConfiguration() {
    return const GestureConfiguration(
      swipeVelocityThreshold: 300.0,
      swipeDistanceThreshold: 50.0,
      longPressDelay: Duration(milliseconds: 500),
      doubleTapTimeout: Duration(milliseconds: 300),
      scaleSensitivity: 1.0,
      rotationSensitivity: 1.0,
    );
  }

  /// Trigger haptic feedback
  static Future<void> triggerHapticFeedback(HapticFeedbackType type) async {
    if (!isHapticFeedbackSupported) {
      debugPrint(_unsupportedMessage);
      return;
    }

    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
    } catch (e) {
      debugPrint('Error triggering haptic feedback: $e');
    }
  }

  /// Show native file picker
  static Future<List<String>?> showNativeFilePicker({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    if (!isNativeFilePickerSupported) {
      debugPrint(_unsupportedMessage);
      return null;
    }

    try {
      // This would integrate with file_picker package
      debugPrint('Native file picker would be shown here');
      debugPrint('Allow multiple: $allowMultiple');
      debugPrint('Allowed extensions: $allowedExtensions');
      debugPrint('Dialog title: $dialogTitle');
      
      // In a real implementation, this would use:
      // - file_picker package for cross-platform file selection
      // - Platform-specific file picker APIs
      // - Android: Intent.ACTION_GET_CONTENT or DocumentsContract
      // - iOS: UIDocumentPickerViewController
      
      return null; // Placeholder
    } catch (e) {
      debugPrint('Error showing native file picker: $e');
      return null;
    }
  }

  /// Get device information
  static Future<DeviceInfo> getDeviceInfo() async {
    if (!isMobilePlatform) {
      return const DeviceInfo(
        platform: MobilePlatform.none,
        screenSize: Size.zero,
        pixelRatio: 1.0,
        isTablet: false,
        hasNotch: false,
        safeAreaInsets: EdgeInsets.zero,
      );
    }

    try {
      // This would integrate with device_info_plus package
      debugPrint('Getting device information');
      
      // In a real implementation, this would query:
      // - Screen dimensions and pixel ratio
      // - Device type (phone/tablet)
      // - Safe area insets
      // - Hardware capabilities
      
      return const DeviceInfo(
        platform: MobilePlatform.android, // Placeholder
        screenSize: Size(360, 640),
        pixelRatio: 2.0,
        isTablet: false,
        hasNotch: false,
        safeAreaInsets: EdgeInsets.only(top: 24, bottom: 24),
      );
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return const DeviceInfo(
        platform: MobilePlatform.none,
        screenSize: Size.zero,
        pixelRatio: 1.0,
        isTablet: false,
        hasNotch: false,
        safeAreaInsets: EdgeInsets.zero,
      );
    }
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    
    // Consider devices with shortest side >= 600dp as tablets
    return shortestSide >= 600;
  }

  /// Get responsive breakpoints for mobile
  static MobileBreakpoints getMobileBreakpoints() {
    return const MobileBreakpoints(
      smallPhone: 320,    // Small phones
      phone: 360,         // Standard phones
      largePhone: 414,    // Large phones
      smallTablet: 600,   // Small tablets
      tablet: 768,        // Standard tablets
      largeTablet: 1024,  // Large tablets
    );
  }

  /// Get performance optimization settings
  static PerformanceSettings getPerformanceSettings() {
    final platform = currentPlatform;
    
    return PerformanceSettings(
      enableAnimations: true,
      animationDuration: const Duration(milliseconds: 300),
      enableShadows: platform != MobilePlatform.none,
      enableBlur: platform == MobilePlatform.ios,
      maxCacheSize: 50 * 1024 * 1024, // 50MB
      imageQuality: platform == MobilePlatform.ios ? 0.9 : 0.8,
      enableLazyLoading: true,
      enableVirtualScrolling: true,
    );
  }

  /// Get feature availability message
  static String getFeatureAvailabilityMessage(String feature) {
    if (!isMobilePlatform) {
      return 'This feature is only available on mobile platforms (Android, iOS).';
    }

    final features = getPlatformFeatures();
    final isAvailable = features[feature] ?? false;

    if (isAvailable) {
      return 'Feature is available and ready to use.';
    }

    switch (feature) {
      case 'nativeFilePicker':
        return 'Native file picker is not supported on this platform.';
      case 'hapticFeedback':
        return 'Haptic feedback is not supported on this device.';
      case 'orientationChange':
        return 'Orientation changes are not supported on this platform.';
      case 'touchGestures':
        return 'Touch gestures are not supported on this platform.';
      case 'biometricAuth':
        return 'Biometric authentication is not available on this device.';
      case 'pushNotifications':
        return 'Push notifications are not supported on this platform.';
      case 'backgroundProcessing':
        return 'Background processing is not available on this platform.';
      default:
        return 'Feature availability unknown.';
    }
  }

  /// Optimize for mobile performance
  static void optimizeForMobile() {
    if (!isMobilePlatform) return;

    // Set preferred orientations for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    debugPrint('Mobile platform optimizations applied');
  }
}

/// Mobile platform enumeration
enum MobilePlatform {
  none,
  android,
  ios,
}

/// Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

/// Mobile configuration class
class MobileConfiguration {
  final MobilePlatform platform;
  final double minimumTouchTargetSize;
  final double recommendedTouchTargetSize;
  final double swipeThreshold;
  final Duration longPressThreshold;
  final Duration doubleTapThreshold;
  final bool enableHapticFeedback;
  final bool enableGestureNavigation;
  final bool enablePullToRefresh;
  final bool enableSwipeActions;

  const MobileConfiguration({
    required this.platform,
    required this.minimumTouchTargetSize,
    required this.recommendedTouchTargetSize,
    required this.swipeThreshold,
    required this.longPressThreshold,
    required this.doubleTapThreshold,
    required this.enableHapticFeedback,
    required this.enableGestureNavigation,
    required this.enablePullToRefresh,
    required this.enableSwipeActions,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform.name,
      'minimumTouchTargetSize': minimumTouchTargetSize,
      'recommendedTouchTargetSize': recommendedTouchTargetSize,
      'swipeThreshold': swipeThreshold,
      'longPressThreshold': longPressThreshold.inMilliseconds,
      'doubleTapThreshold': doubleTapThreshold.inMilliseconds,
      'enableHapticFeedback': enableHapticFeedback,
      'enableGestureNavigation': enableGestureNavigation,
      'enablePullToRefresh': enablePullToRefresh,
      'enableSwipeActions': enableSwipeActions,
    };
  }

  @override
  String toString() {
    return 'MobileConfiguration(${toMap()})';
  }
}

/// Touch target sizes
class TouchTargetSizes {
  final double minimum;
  final double recommended;
  final double comfortable;
  final double large;

  const TouchTargetSizes({
    required this.minimum,
    required this.recommended,
    required this.comfortable,
    required this.large,
  });
}

/// Gesture configuration
class GestureConfiguration {
  final double swipeVelocityThreshold;
  final double swipeDistanceThreshold;
  final Duration longPressDelay;
  final Duration doubleTapTimeout;
  final double scaleSensitivity;
  final double rotationSensitivity;

  const GestureConfiguration({
    required this.swipeVelocityThreshold,
    required this.swipeDistanceThreshold,
    required this.longPressDelay,
    required this.doubleTapTimeout,
    required this.scaleSensitivity,
    required this.rotationSensitivity,
  });
}

/// Device information
class DeviceInfo {
  final MobilePlatform platform;
  final Size screenSize;
  final double pixelRatio;
  final bool isTablet;
  final bool hasNotch;
  final EdgeInsets safeAreaInsets;

  const DeviceInfo({
    required this.platform,
    required this.screenSize,
    required this.pixelRatio,
    required this.isTablet,
    required this.hasNotch,
    required this.safeAreaInsets,
  });

  @override
  String toString() {
    return 'DeviceInfo(platform: $platform, screenSize: $screenSize, pixelRatio: $pixelRatio, isTablet: $isTablet, hasNotch: $hasNotch)';
  }
}

/// Mobile breakpoints
class MobileBreakpoints {
  final double smallPhone;
  final double phone;
  final double largePhone;
  final double smallTablet;
  final double tablet;
  final double largeTablet;

  const MobileBreakpoints({
    required this.smallPhone,
    required this.phone,
    required this.largePhone,
    required this.smallTablet,
    required this.tablet,
    required this.largeTablet,
  });
}

/// Performance settings
class PerformanceSettings {
  final bool enableAnimations;
  final Duration animationDuration;
  final bool enableShadows;
  final bool enableBlur;
  final int maxCacheSize;
  final double imageQuality;
  final bool enableLazyLoading;
  final bool enableVirtualScrolling;

  const PerformanceSettings({
    required this.enableAnimations,
    required this.animationDuration,
    required this.enableShadows,
    required this.enableBlur,
    required this.maxCacheSize,
    required this.imageQuality,
    required this.enableLazyLoading,
    required this.enableVirtualScrolling,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableAnimations': enableAnimations,
      'animationDuration': animationDuration.inMilliseconds,
      'enableShadows': enableShadows,
      'enableBlur': enableBlur,
      'maxCacheSize': maxCacheSize,
      'imageQuality': imageQuality,
      'enableLazyLoading': enableLazyLoading,
      'enableVirtualScrolling': enableVirtualScrolling,
    };
  }

  @override
  String toString() {
    return 'PerformanceSettings(${toMap()})';
  }
}
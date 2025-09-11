import 'package:flutter/foundation.dart';

/// Service for web platform-specific functionality
class WebPlatformService {
  static const String _unsupportedMessage = 
      'This feature is only available on web platforms.';

  /// Check if running on web platform
  static bool get isWebPlatform => kIsWeb;

  /// Check if File System Access API is supported
  static bool get isFileSystemAccessSupported {
    if (!kIsWeb) return false;
    // In a real web environment, this would check for the actual API
    // For testing purposes, we'll return false
    return false;
  }

  /// Check if drag and drop is supported
  static bool get isDragDropSupported {
    if (!kIsWeb) return false;
    // In a real web environment, this would check for drag/drop support
    return true; // Most modern browsers support this
  }

  /// Get platform-specific features available
  static Map<String, bool> getPlatformFeatures() {
    if (!kIsWeb) {
      return {
        'fileSystemAccess': false,
        'dragDrop': false,
        'pwa': false,
        'webWorkers': false,
      };
    }

    return {
      'fileSystemAccess': isFileSystemAccessSupported,
      'dragDrop': isDragDropSupported,
      'pwa': true, // PWA features are generally available
      'webWorkers': true, // Web Workers are widely supported
    };
  }

  /// Get recommended file types for web file picker
  static List<Map<String, dynamic>> getWebFileTypes() {
    return [
      {
        'description': 'Image files',
        'accept': {
          'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg']
        }
      },
      {
        'description': 'Document files',
        'accept': {
          'application/pdf': ['.pdf'],
          'application/msword': ['.doc'],
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
          'text/plain': ['.txt'],
        }
      },
      {
        'description': 'Archive files',
        'accept': {
          'application/zip': ['.zip'],
          'application/x-rar-compressed': ['.rar'],
          'application/x-7z-compressed': ['.7z'],
        }
      },
    ];
  }

  /// Get web-specific configuration
  static Map<String, dynamic> getWebConfig() {
    return {
      'maxFileSize': 100 * 1024 * 1024, // 100MB
      'supportedFormats': ['image/*', 'application/pdf', 'text/*'],
      'enableOfflineMode': true,
      'enablePushNotifications': false, // Requires user permission
    };
  }

  /// Check if feature is available and show appropriate message
  static String getFeatureAvailabilityMessage(String feature) {
    if (!kIsWeb) {
      return 'This feature is only available on web platforms.';
    }

    final features = getPlatformFeatures();
    final isAvailable = features[feature] ?? false;

    if (isAvailable) {
      return 'Feature is available and ready to use.';
    }

    switch (feature) {
      case 'fileSystemAccess':
        return 'File System Access API requires Chrome 86+ or Edge 86+. '
               'Falling back to standard file picker.';
      case 'dragDrop':
        return 'Drag and drop is not supported in this browser.';
      case 'pwa':
        return 'Progressive Web App features are not available.';
      case 'webWorkers':
        return 'Web Workers are not supported in this browser.';
      default:
        return 'Feature availability unknown.';
    }
  }
}
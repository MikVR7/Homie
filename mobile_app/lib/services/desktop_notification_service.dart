import 'package:flutter/foundation.dart';
import 'desktop_platform_service.dart';

/// Service for managing desktop notifications
class DesktopNotificationService {
  static const String _unsupportedMessage = 
      'Desktop notifications are not supported on this platform.';

  /// Check if desktop notifications are supported
  static bool get isSupported {
    return DesktopPlatformService.isSystemNotificationSupported;
  }

  /// Show a simple notification
  static Future<bool> showNotification({
    required String title,
    required String message,
    Duration? timeout,
  }) async {
    if (!isSupported) {
      debugPrint(_unsupportedMessage);
      return false;
    }

    return await DesktopPlatformService.showSystemNotification(
      title: title,
      message: message,
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }

  /// Show operation completion notification
  static Future<bool> showOperationCompleted({
    required String operationType,
    required int fileCount,
    required Duration duration,
    bool success = true,
  }) async {
    final title = success 
        ? 'Operation Completed'
        : 'Operation Failed';
    
    final message = success
        ? '$operationType completed successfully.\n$fileCount files processed in ${_formatDuration(duration)}.'
        : '$operationType failed.\nPlease check the error log for details.';

    return await showNotification(
      title: title,
      message: message,
      timeout: const Duration(seconds: 8),
    );
  }

  /// Show operation started notification
  static Future<bool> showOperationStarted({
    required String operationType,
    required int fileCount,
  }) async {
    return await showNotification(
      title: 'Operation Started',
      message: '$operationType started with $fileCount files.',
      timeout: const Duration(seconds: 3),
    );
  }

  /// Show operation paused notification
  static Future<bool> showOperationPaused({
    required String operationType,
    required int completedFiles,
    required int totalFiles,
  }) async {
    return await showNotification(
      title: 'Operation Paused',
      message: '$operationType paused.\nProgress: $completedFiles/$totalFiles files.',
      timeout: const Duration(seconds: 4),
    );
  }

  /// Show operation resumed notification
  static Future<bool> showOperationResumed({
    required String operationType,
    required int remainingFiles,
  }) async {
    return await showNotification(
      title: 'Operation Resumed',
      message: '$operationType resumed.\n$remainingFiles files remaining.',
      timeout: const Duration(seconds: 3),
    );
  }

  /// Show operation cancelled notification
  static Future<bool> showOperationCancelled({
    required String operationType,
    required int completedFiles,
    required int totalFiles,
  }) async {
    return await showNotification(
      title: 'Operation Cancelled',
      message: '$operationType cancelled.\nCompleted: $completedFiles/$totalFiles files.',
      timeout: const Duration(seconds: 4),
    );
  }

  /// Show error notification
  static Future<bool> showError({
    required String title,
    required String error,
    String? suggestion,
  }) async {
    final message = suggestion != null
        ? '$error\n\nSuggestion: $suggestion'
        : error;

    return await showNotification(
      title: 'Error: $title',
      message: message,
      timeout: const Duration(seconds: 10),
    );
  }

  /// Show warning notification
  static Future<bool> showWarning({
    required String title,
    required String warning,
    String? action,
  }) async {
    final message = action != null
        ? '$warning\n\nAction: $action'
        : warning;

    return await showNotification(
      title: 'Warning: $title',
      message: message,
      timeout: const Duration(seconds: 6),
    );
  }

  /// Show info notification
  static Future<bool> showInfo({
    required String title,
    required String info,
  }) async {
    return await showNotification(
      title: 'Info: $title',
      message: info,
      timeout: const Duration(seconds: 4),
    );
  }

  /// Show drive connected notification
  static Future<bool> showDriveConnected({
    required String driveName,
    required String driveSize,
  }) async {
    return await showNotification(
      title: 'Drive Connected',
      message: '$driveName ($driveSize) has been connected and is ready for use.',
      timeout: const Duration(seconds: 4),
    );
  }

  /// Show drive disconnected notification
  static Future<bool> showDriveDisconnected({
    required String driveName,
  }) async {
    return await showNotification(
      title: 'Drive Disconnected',
      message: '$driveName has been safely disconnected.',
      timeout: const Duration(seconds: 3),
    );
  }

  /// Show low disk space notification
  static Future<bool> showLowDiskSpace({
    required String driveName,
    required String availableSpace,
    required double percentageUsed,
  }) async {
    return await showNotification(
      title: 'Low Disk Space',
      message: '$driveName is ${percentageUsed.toStringAsFixed(1)}% full.\nOnly $availableSpace remaining.',
      timeout: const Duration(seconds: 8),
    );
  }

  /// Show backup completed notification
  static Future<bool> showBackupCompleted({
    required int fileCount,
    required String backupSize,
    required Duration duration,
  }) async {
    return await showNotification(
      title: 'Backup Completed',
      message: 'Successfully backed up $fileCount files ($backupSize) in ${_formatDuration(duration)}.',
      timeout: const Duration(seconds: 6),
    );
  }

  /// Show update available notification
  static Future<bool> showUpdateAvailable({
    required String version,
    required String releaseNotes,
  }) async {
    return await showNotification(
      title: 'Update Available',
      message: 'Version $version is available.\n$releaseNotes',
      timeout: const Duration(seconds: 10),
    );
  }

  /// Format duration for display
  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get notification preferences
  static NotificationPreferences getPreferences() {
    return const NotificationPreferences(
      enableOperationNotifications: true,
      enableErrorNotifications: true,
      enableWarningNotifications: true,
      enableInfoNotifications: false,
      enableDriveNotifications: true,
      enableBackupNotifications: true,
      enableUpdateNotifications: true,
      defaultTimeout: Duration(seconds: 5),
      maxNotificationsPerMinute: 10,
    );
  }

  /// Update notification preferences
  static void updatePreferences(NotificationPreferences preferences) {
    // In a real implementation, this would save preferences to local storage
    debugPrint('Notification preferences updated: $preferences');
  }

  /// Test notification system
  static Future<bool> testNotifications() async {
    if (!isSupported) {
      debugPrint(_unsupportedMessage);
      return false;
    }

    final success = await showNotification(
      title: 'Test Notification',
      message: 'Desktop notifications are working correctly!',
      timeout: const Duration(seconds: 3),
    );

    debugPrint('Notification test result: $success');
    return success;
  }
}

/// Notification preferences configuration
class NotificationPreferences {
  final bool enableOperationNotifications;
  final bool enableErrorNotifications;
  final bool enableWarningNotifications;
  final bool enableInfoNotifications;
  final bool enableDriveNotifications;
  final bool enableBackupNotifications;
  final bool enableUpdateNotifications;
  final Duration defaultTimeout;
  final int maxNotificationsPerMinute;

  const NotificationPreferences({
    required this.enableOperationNotifications,
    required this.enableErrorNotifications,
    required this.enableWarningNotifications,
    required this.enableInfoNotifications,
    required this.enableDriveNotifications,
    required this.enableBackupNotifications,
    required this.enableUpdateNotifications,
    required this.defaultTimeout,
    required this.maxNotificationsPerMinute,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableOperationNotifications': enableOperationNotifications,
      'enableErrorNotifications': enableErrorNotifications,
      'enableWarningNotifications': enableWarningNotifications,
      'enableInfoNotifications': enableInfoNotifications,
      'enableDriveNotifications': enableDriveNotifications,
      'enableBackupNotifications': enableBackupNotifications,
      'enableUpdateNotifications': enableUpdateNotifications,
      'defaultTimeout': defaultTimeout.inMilliseconds,
      'maxNotificationsPerMinute': maxNotificationsPerMinute,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      enableOperationNotifications: map['enableOperationNotifications'] ?? true,
      enableErrorNotifications: map['enableErrorNotifications'] ?? true,
      enableWarningNotifications: map['enableWarningNotifications'] ?? true,
      enableInfoNotifications: map['enableInfoNotifications'] ?? false,
      enableDriveNotifications: map['enableDriveNotifications'] ?? true,
      enableBackupNotifications: map['enableBackupNotifications'] ?? true,
      enableUpdateNotifications: map['enableUpdateNotifications'] ?? true,
      defaultTimeout: Duration(milliseconds: map['defaultTimeout'] ?? 5000),
      maxNotificationsPerMinute: map['maxNotificationsPerMinute'] ?? 10,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(${toMap()})';
  }
}
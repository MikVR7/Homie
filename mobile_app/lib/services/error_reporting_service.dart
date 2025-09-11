import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Error reporting and analytics service for production monitoring
class ErrorReportingService {
  static const String _defaultEndpoint = 'https://api.homie.example.com/analytics';
  
  final String _endpoint;
  final String? _apiKey;
  final String? _sentryDsn;
  final http.Client _httpClient;
  final bool _enabledInDebug;
  
  static ErrorReportingService? _instance;
  
  ErrorReportingService._({
    required String endpoint,
    String? apiKey,
    String? sentryDsn,
    http.Client? httpClient,
    bool enabledInDebug = false,
  }) : _endpoint = endpoint,
       _apiKey = apiKey,
       _sentryDsn = sentryDsn,
       _httpClient = httpClient ?? http.Client(),
       _enabledInDebug = enabledInDebug;
  
  /// Initialize the error reporting service
  static void initialize({
    String? endpoint,
    String? apiKey,
    String? sentryDsn,
    http.Client? httpClient,
    bool enabledInDebug = false,
  }) {
    _instance = ErrorReportingService._(
      endpoint: endpoint ?? _defaultEndpoint,
      apiKey: apiKey,
      sentryDsn: sentryDsn,
      httpClient: httpClient,
      enabledInDebug: enabledInDebug,
    );
    
    // Set up global error handling
    _instance!._setupGlobalErrorHandling();
  }
  
  /// Get the singleton instance
  static ErrorReportingService get instance {
    if (_instance == null) {
      throw StateError('ErrorReportingService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Check if error reporting is enabled
  bool get isEnabled {
    return kReleaseMode || _enabledInDebug;
  }
  
  /// Set up global error handling
  void _setupGlobalErrorHandling() {
    if (!isEnabled) return;
    
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      reportFlutterError(details);
    };
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(error, stack, fatal: true);
      return true;
    };
  }
  
  /// Report a Flutter framework error
  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    if (!isEnabled) return;
    
    try {
      await _sendErrorReport({
        'type': 'flutter_error',
        'error': details.exception.toString(),
        'stackTrace': details.stack.toString(),
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
        'silent': details.silent,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getPlatformInfo(),
        'app_info': await _getAppInfo(),
      });
    } catch (e) {
      debugPrint('Failed to report Flutter error: $e');
    }
  }
  
  /// Report a general error
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extra,
    String? userId,
    bool fatal = false,
  }) async {
    if (!isEnabled) return;
    
    try {
      await _sendErrorReport({
        'type': 'error',
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'extra': extra,
        'userId': userId,
        'fatal': fatal,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getPlatformInfo(),
        'app_info': await _getAppInfo(),
      });
    } catch (e) {
      debugPrint('Failed to report error: $e');
    }
  }
  
  /// Report a custom event for analytics
  Future<void> reportEvent(
    String eventName,
    Map<String, dynamic>? parameters,
  ) async {
    if (!isEnabled) return;
    
    try {
      await _sendAnalyticsEvent({
        'type': 'event',
        'event_name': eventName,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _getSessionId(),
        'platform': _getPlatformInfo(),
        'app_info': await _getAppInfo(),
      });
    } catch (e) {
      debugPrint('Failed to report event: $e');
    }
  }
  
  /// Report user action for analytics
  Future<void> reportUserAction(
    String action,
    String category, {
    String? label,
    int? value,
    Map<String, dynamic>? extra,
  }) async {
    if (!isEnabled) return;
    
    await reportEvent('user_action', {
      'action': action,
      'category': category,
      'label': label,
      'value': value,
      'extra': extra,
    });
  }
  
  /// Report performance metrics
  Future<void> reportPerformance(
    String metric,
    double value, {
    String? unit,
    Map<String, dynamic>? extra,
  }) async {
    if (!isEnabled) return;
    
    await reportEvent('performance_metric', {
      'metric': metric,
      'value': value,
      'unit': unit ?? 'ms',
      'extra': extra,
    });
  }
  
  /// Report feature usage
  Future<void> reportFeatureUsage(
    String feature,
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!isEnabled) return;
    
    await reportEvent('feature_usage', {
      'feature': feature,
      'action': action,
      'metadata': metadata,
    });
  }
  
  /// Set user context for error reporting
  Future<void> setUserContext({
    String? userId,
    String? email,
    Map<String, dynamic>? extra,
  }) async {
    if (!isEnabled) return;
    
    await reportEvent('user_context_update', {
      'user_id': userId,
      'email': email,
      'extra': extra,
    });
  }
  
  /// Add breadcrumb for debugging
  Future<void> addBreadcrumb(
    String message,
    String category, {
    Map<String, dynamic>? data,
    String level = 'info',
  }) async {
    if (!isEnabled) return;
    
    await reportEvent('breadcrumb', {
      'message': message,
      'category': category,
      'data': data,
      'level': level,
    });
  }
  
  /// Send error report to backend
  Future<void> _sendErrorReport(Map<String, dynamic> errorData) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_endpoint/errors'),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(errorData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('Error reporting failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error reporting request failed: $e');
    }
  }
  
  /// Send analytics event to backend
  Future<void> _sendAnalyticsEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_endpoint/events'),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(eventData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('Analytics reporting failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Analytics reporting request failed: $e');
    }
  }
  
  /// Get platform information
  Map<String, dynamic> _getPlatformInfo() {
    return {
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'is_web': kIsWeb,
      'is_mobile': !kIsWeb && (Platform.isAndroid || Platform.isIOS),
      'is_desktop': !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux),
      'operating_system': kIsWeb ? 'web' : Platform.operatingSystem,
      'operating_system_version': kIsWeb ? 'unknown' : Platform.operatingSystemVersion,
      'locale': PlatformDispatcher.instance.locale.toString(),
      'user_agent': kIsWeb ? 'web_browser' : 'native_app',
    };
  }
  
  /// Get app information
  Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      // In a real app, you'd get this from package_info_plus
      return {
        'app_name': 'Homie File Organizer',
        'app_version': '1.0.0',
        'build_number': '1',
        'package_name': 'com.homie.file_organizer',
      };
    } catch (e) {
      return {
        'app_name': 'Homie File Organizer',
        'app_version': 'unknown',
        'build_number': 'unknown',
        'package_name': 'unknown',
      };
    }
  }
  
  /// Get or generate session ID
  String _getSessionId() {
    // In a real app, you'd store this in shared preferences
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}

/// Analytics helper for common tracking scenarios
class Analytics {
  static final ErrorReportingService _service = ErrorReportingService.instance;
  
  /// Track screen view
  static Future<void> trackScreenView(String screenName) async {
    await _service.reportEvent('screen_view', {
      'screen_name': screenName,
    });
  }
  
  /// Track button click
  static Future<void> trackButtonClick(String buttonName, {String? screen}) async {
    await _service.reportUserAction('click', 'button', 
      label: buttonName,
      extra: {'screen': screen},
    );
  }
  
  /// Track file operation
  static Future<void> trackFileOperation(
    String operation,
    int fileCount, {
    String? organizationStyle,
    bool? success,
  }) async {
    await _service.reportFeatureUsage('file_organizer', operation,
      metadata: {
        'file_count': fileCount,
        'organization_style': organizationStyle,
        'success': success,
      },
    );
  }
  
  /// Track search
  static Future<void> trackSearch(String query, int resultCount) async {
    await _service.reportUserAction('search', 'file_search',
      extra: {
        'query_length': query.length,
        'result_count': resultCount,
      },
    );
  }
  
  /// Track export
  static Future<void> trackExport(String format, int itemCount) async {
    await _service.reportFeatureUsage('export', 'data_export',
      metadata: {
        'format': format,
        'item_count': itemCount,
      },
    );
  }
  
  /// Track app startup
  static Future<void> trackAppStartup(Duration startupTime) async {
    await _service.reportPerformance('app_startup_time', startupTime.inMilliseconds.toDouble());
  }
  
  /// Track API call
  static Future<void> trackApiCall(
    String endpoint,
    int statusCode,
    Duration responseTime,
  ) async {
    await _service.reportEvent('api_call', {
      'endpoint': endpoint,
      'status_code': statusCode,
      'response_time_ms': responseTime.inMilliseconds,
      'success': statusCode >= 200 && statusCode < 300,
    });
  }
  
  /// Track error with context
  static Future<void> trackError(
    String errorType,
    String message, {
    String? feature,
    Map<String, dynamic>? context,
  }) async {
    await _service.reportError(
      '$errorType: $message',
      StackTrace.current,
      extra: {
        'error_type': errorType,
        'feature': feature,
        'context': context,
      },
    );
  }
}

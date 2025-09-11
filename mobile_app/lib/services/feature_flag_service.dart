import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag service for gradual rollout and A/B testing
class FeatureFlagService {
  static const String _cacheKey = 'feature_flags_cache';
  static const String _lastUpdateKey = 'feature_flags_last_update';
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  final String? _endpoint;
  final String? _apiKey;
  final http.Client _httpClient;
  final Map<String, dynamic> _localFlags = {};
  final Map<String, dynamic> _remoteFlags = {};
  final StreamController<Map<String, dynamic>> _flagUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static FeatureFlagService? _instance;
  
  FeatureFlagService._({
    String? endpoint,
    String? apiKey,
    http.Client? httpClient,
  }) : _endpoint = endpoint,
       _apiKey = apiKey,
       _httpClient = httpClient ?? http.Client();
  
  /// Initialize the feature flag service
  static Future<FeatureFlagService> initialize({
    String? endpoint,
    String? apiKey,
    http.Client? httpClient,
    Map<String, dynamic>? defaultFlags,
  }) async {
    _instance = FeatureFlagService._(
      endpoint: endpoint,
      apiKey: apiKey,
      httpClient: httpClient,
    );
    
    await _instance!._loadLocalFlags(defaultFlags ?? _getDefaultFlags());
    await _instance!._loadCachedFlags();
    
    // Start background refresh
    _instance!._startBackgroundRefresh();
    
    return _instance!;
  }
  
  /// Get the singleton instance
  static FeatureFlagService get instance {
    if (_instance == null) {
      throw StateError('FeatureFlagService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Stream of flag updates
  Stream<Map<String, dynamic>> get flagUpdates => _flagUpdatesController.stream;
  
  /// Get default feature flags
  static Map<String, dynamic> _getDefaultFlags() {
    return {
      // Core features
      'file_organizer_enabled': true,
      'batch_operations_enabled': true,
      'ai_suggestions_enabled': true,
      'websocket_enabled': true,
      
      // Advanced features
      'advanced_search_enabled': true,
      'export_functionality_enabled': true,
      'bulk_selection_enabled': true,
      'advanced_filters_enabled': true,
      
      // UI features
      'material_design_3_enabled': true,
      'dark_theme_enabled': true,
      'animations_enabled': true,
      'skeleton_loading_enabled': true,
      'micro_interactions_enabled': true,
      
      // Platform features
      'desktop_integration_enabled': true,
      'pwa_features_enabled': true,
      'keyboard_shortcuts_enabled': true,
      'system_notifications_enabled': true,
      
      // Experimental features
      'experimental_ai_features': false,
      'beta_organization_modes': false,
      'advanced_analytics': false,
      'real_time_collaboration': false,
      
      // Performance features
      'lazy_loading_enabled': true,
      'virtual_scrolling_enabled': true,
      'image_optimization_enabled': true,
      'background_sync_enabled': true,
      
      // Analytics and monitoring
      'analytics_enabled': kReleaseMode,
      'error_reporting_enabled': kReleaseMode,
      'performance_monitoring_enabled': kReleaseMode,
      'user_behavior_tracking_enabled': false,
      
      // A/B testing flags
      'ab_test_new_ui_layout': 'control', // 'control' | 'variant_a' | 'variant_b'
      'ab_test_onboarding_flow': 'control',
      'ab_test_organization_suggestions': 'control',
      
      // Rollout flags (percentage-based)
      'new_search_algorithm_rollout': 0, // 0-100
      'enhanced_ai_rollout': 0,
      'new_export_features_rollout': 100,
      'beta_desktop_features_rollout': 50,
    };
  }
  
  /// Load local feature flags
  Future<void> _loadLocalFlags(Map<String, dynamic> defaultFlags) async {
    _localFlags.clear();
    _localFlags.addAll(defaultFlags);
  }
  
  /// Load cached feature flags from storage
  Future<void> _loadCachedFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedFlags = prefs.getString(_cacheKey);
      final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
      
      if (cachedFlags != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
        if (cacheAge < _cacheExpiry.inMilliseconds) {
          final flags = json.decode(cachedFlags) as Map<String, dynamic>;
          _remoteFlags.clear();
          _remoteFlags.addAll(flags);
          debugPrint('Loaded ${flags.length} feature flags from cache');
        } else {
          debugPrint('Feature flag cache expired, will refresh from remote');
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached feature flags: $e');
    }
  }
  
  /// Save feature flags to cache
  Future<void> _saveFlagsToCache(Map<String, dynamic> flags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(flags));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save feature flags to cache: $e');
    }
  }
  
  /// Start background refresh of feature flags
  void _startBackgroundRefresh() {
    Timer.periodic(const Duration(minutes: 30), (_) {
      refreshFlags();
    });
  }
  
  /// Refresh feature flags from remote server
  Future<void> refreshFlags() async {
    if (_endpoint == null) {
      debugPrint('Feature flag endpoint not configured, using local flags only');
      return;
    }
    
    try {
      final response = await _httpClient.get(
        Uri.parse('$_endpoint/feature-flags'),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final flags = data['flags'] as Map<String, dynamic>? ?? {};
        
        _remoteFlags.clear();
        _remoteFlags.addAll(flags);
        
        await _saveFlagsToCache(flags);
        _flagUpdatesController.add(_getAllFlags());
        
        debugPrint('Refreshed ${flags.length} feature flags from remote');
      } else {
        debugPrint('Failed to refresh feature flags: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error refreshing feature flags: $e');
    }
  }
  
  /// Get all effective flags (remote overrides local)
  Map<String, dynamic> _getAllFlags() {
    final allFlags = Map<String, dynamic>.from(_localFlags);
    allFlags.addAll(_remoteFlags);
    return allFlags;
  }
  
  /// Check if a feature is enabled
  bool isEnabled(String flagName) {
    final flags = _getAllFlags();
    final value = flags[flagName];
    
    if (value is bool) {
      return value;
    } else if (value is String) {
      // Handle A/B test flags
      return value != 'control' && value != 'disabled';
    } else if (value is int) {
      // Handle rollout percentages
      return _checkRolloutPercentage(flagName, value);
    }
    
    debugPrint('Unknown feature flag type for $flagName: ${value.runtimeType}');
    return false;
  }
  
  /// Get feature flag value
  T? getValue<T>(String flagName, [T? defaultValue]) {
    final flags = _getAllFlags();
    final value = flags[flagName];
    
    if (value is T) {
      return value;
    }
    
    return defaultValue;
  }
  
  /// Get A/B test variant
  String getVariant(String flagName, [String defaultVariant = 'control']) {
    final value = getValue<String>(flagName, defaultVariant);
    return value ?? defaultVariant;
  }
  
  /// Get rollout percentage
  int getRolloutPercentage(String flagName) {
    return getValue<int>(flagName, 0) ?? 0;
  }
  
  /// Check if user is in rollout percentage
  bool _checkRolloutPercentage(String flagName, int percentage) {
    if (percentage <= 0) return false;
    if (percentage >= 100) return true;
    
    // Use a deterministic hash of the flag name to determine if user is in rollout
    // In a real app, you'd use user ID for consistent experience
    final hash = flagName.hashCode.abs();
    return (hash % 100) < percentage;
  }
  
  /// Override a feature flag locally (for testing)
  void overrideFlag(String flagName, dynamic value) {
    _localFlags[flagName] = value;
    _flagUpdatesController.add(_getAllFlags());
    debugPrint('Overrode feature flag $flagName = $value');
  }
  
  /// Remove local override
  void removeOverride(String flagName) {
    _localFlags.remove(flagName);
    _flagUpdatesController.add(_getAllFlags());
    debugPrint('Removed override for feature flag $flagName');
  }
  
  /// Get all active flags for debugging
  Map<String, dynamic> getAllFlags() {
    return Map<String, dynamic>.from(_getAllFlags());
  }
  
  /// Get flag source information
  Map<String, String> getFlagSources() {
    final sources = <String, String>{};
    final allFlags = _getAllFlags();
    
    for (final flagName in allFlags.keys) {
      if (_remoteFlags.containsKey(flagName)) {
        sources[flagName] = 'remote';
      } else if (_localFlags.containsKey(flagName)) {
        sources[flagName] = 'local';
      } else {
        sources[flagName] = 'unknown';
      }
    }
    
    return sources;
  }
  
  /// Track feature flag usage for analytics
  void trackFlagUsage(String flagName, dynamic value) {
    // In a real app, you'd send this to your analytics service
    debugPrint('Feature flag used: $flagName = $value');
  }
  
  /// Dispose of resources
  void dispose() {
    _flagUpdatesController.close();
    _httpClient.close();
  }
}

/// Feature flag helper for common use cases
class FeatureFlags {
  static final FeatureFlagService _service = FeatureFlagService.instance;
  
  // Core features
  static bool get fileOrganizerEnabled => _service.isEnabled('file_organizer_enabled');
  static bool get batchOperationsEnabled => _service.isEnabled('batch_operations_enabled');
  static bool get aiSuggestionsEnabled => _service.isEnabled('ai_suggestions_enabled');
  static bool get websocketEnabled => _service.isEnabled('websocket_enabled');
  
  // Advanced features
  static bool get advancedSearchEnabled => _service.isEnabled('advanced_search_enabled');
  static bool get exportFunctionalityEnabled => _service.isEnabled('export_functionality_enabled');
  static bool get bulkSelectionEnabled => _service.isEnabled('bulk_selection_enabled');
  static bool get advancedFiltersEnabled => _service.isEnabled('advanced_filters_enabled');
  
  // UI features
  static bool get materialDesign3Enabled => _service.isEnabled('material_design_3_enabled');
  static bool get darkThemeEnabled => _service.isEnabled('dark_theme_enabled');
  static bool get animationsEnabled => _service.isEnabled('animations_enabled');
  static bool get skeletonLoadingEnabled => _service.isEnabled('skeleton_loading_enabled');
  static bool get microInteractionsEnabled => _service.isEnabled('micro_interactions_enabled');
  
  // Platform features
  static bool get desktopIntegrationEnabled => _service.isEnabled('desktop_integration_enabled');
  static bool get pwaFeaturesEnabled => _service.isEnabled('pwa_features_enabled');
  static bool get keyboardShortcutsEnabled => _service.isEnabled('keyboard_shortcuts_enabled');
  static bool get systemNotificationsEnabled => _service.isEnabled('system_notifications_enabled');
  
  // Experimental features
  static bool get experimentalAiFeatures => _service.isEnabled('experimental_ai_features');
  static bool get betaOrganizationModes => _service.isEnabled('beta_organization_modes');
  static bool get advancedAnalytics => _service.isEnabled('advanced_analytics');
  static bool get realTimeCollaboration => _service.isEnabled('real_time_collaboration');
  
  // Performance features
  static bool get lazyLoadingEnabled => _service.isEnabled('lazy_loading_enabled');
  static bool get virtualScrollingEnabled => _service.isEnabled('virtual_scrolling_enabled');
  static bool get imageOptimizationEnabled => _service.isEnabled('image_optimization_enabled');
  static bool get backgroundSyncEnabled => _service.isEnabled('background_sync_enabled');
  
  // Analytics and monitoring
  static bool get analyticsEnabled => _service.isEnabled('analytics_enabled');
  static bool get errorReportingEnabled => _service.isEnabled('error_reporting_enabled');
  static bool get performanceMonitoringEnabled => _service.isEnabled('performance_monitoring_enabled');
  static bool get userBehaviorTrackingEnabled => _service.isEnabled('user_behavior_tracking_enabled');
  
  // A/B testing
  static String get uiLayoutVariant => _service.getVariant('ab_test_new_ui_layout');
  static String get onboardingFlowVariant => _service.getVariant('ab_test_onboarding_flow');
  static String get organizationSuggestionsVariant => _service.getVariant('ab_test_organization_suggestions');
  
  // Rollout features
  static bool get newSearchAlgorithm => _service.isEnabled('new_search_algorithm_rollout');
  static bool get enhancedAi => _service.isEnabled('enhanced_ai_rollout');
  static bool get newExportFeatures => _service.isEnabled('new_export_features_rollout');
  static bool get betaDesktopFeatures => _service.isEnabled('beta_desktop_features_rollout');
  
  /// Check if feature should be shown based on flags
  static bool shouldShowFeature(String feature) {
    switch (feature) {
      case 'batch_selection':
        return bulkSelectionEnabled;
      case 'advanced_search':
        return advancedSearchEnabled;
      case 'export_options':
        return exportFunctionalityEnabled;
      case 'ai_suggestions':
        return aiSuggestionsEnabled;
      case 'desktop_shortcuts':
        return keyboardShortcutsEnabled && desktopIntegrationEnabled;
      case 'animations':
        return animationsEnabled;
      case 'skeleton_loading':
        return skeletonLoadingEnabled;
      default:
        return true; // Default to showing feature
    }
  }
  
  /// Get feature configuration
  static Map<String, dynamic> getFeatureConfig(String feature) {
    switch (feature) {
      case 'search':
        return {
          'advanced_enabled': advancedSearchEnabled,
          'algorithm': newSearchAlgorithm ? 'enhanced' : 'standard',
        };
      case 'ui':
        return {
          'variant': uiLayoutVariant,
          'animations': animationsEnabled,
          'material_design_3': materialDesign3Enabled,
        };
      case 'ai':
        return {
          'suggestions_enabled': aiSuggestionsEnabled,
          'experimental_features': experimentalAiFeatures,
          'enhanced_mode': enhancedAi,
        };
      default:
        return {};
    }
  }
}

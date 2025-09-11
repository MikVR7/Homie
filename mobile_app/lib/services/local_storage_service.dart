import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for user preferences and application data
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final StreamController<StorageEvent> _eventController = 
      StreamController<StorageEvent>.broadcast();

  // Storage keys
  static const String _userPreferencesKey = 'user_preferences';
  static const String _recentFoldersKey = 'recent_folders';
  static const String _bookmarkedFoldersKey = 'bookmarked_folders';
  static const String _organizationPresetsKey = 'organization_presets';
  static const String _appSettingsKey = 'app_settings';
  static const String _cacheMetadataKey = 'cache_metadata';

  /// Initialize the local storage service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadInitialData();
      debugPrint('LocalStorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
    }
  }

  /// Get storage event stream
  Stream<StorageEvent> get eventStream => _eventController.stream;

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      final json = jsonEncode(preferences.toMap());
      await _prefs?.setString(_userPreferencesKey, json);
      _memoryCache[_userPreferencesKey] = preferences;
      
      _eventController.add(StorageEvent(
        type: StorageEventType.updated,
        key: _userPreferencesKey,
        data: preferences,
      ));
      
      debugPrint('User preferences saved');
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  /// Get user preferences
  Future<UserPreferences> getUserPreferences() async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(_userPreferencesKey)) {
        return _memoryCache[_userPreferencesKey] as UserPreferences;
      }

      // Load from persistent storage
      final json = _prefs?.getString(_userPreferencesKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final preferences = UserPreferences.fromMap(map);
        _memoryCache[_userPreferencesKey] = preferences;
        return preferences;
      }

      // Return default preferences
      final defaultPrefs = UserPreferences.defaultPreferences();
      await saveUserPreferences(defaultPrefs);
      return defaultPrefs;
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return UserPreferences.defaultPreferences();
    }
  }  
/// Add recent folder
  Future<void> addRecentFolder(String folderPath) async {
    try {
      final recentFolders = await getRecentFolders();
      
      // Remove if already exists to avoid duplicates
      recentFolders.removeWhere((folder) => folder.path == folderPath);
      
      // Add to beginning of list
      recentFolders.insert(0, RecentFolder(
        path: folderPath,
        lastAccessed: DateTime.now(),
        accessCount: 1,
      ));
      
      // Keep only last 20 folders
      if (recentFolders.length > 20) {
        recentFolders.removeRange(20, recentFolders.length);
      }
      
      await _saveRecentFolders(recentFolders);
      debugPrint('Added recent folder: $folderPath');
    } catch (e) {
      debugPrint('Error adding recent folder: $e');
    }
  }

  /// Get recent folders
  Future<List<RecentFolder>> getRecentFolders() async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(_recentFoldersKey)) {
        return List<RecentFolder>.from(_memoryCache[_recentFoldersKey]);
      }

      // Load from persistent storage
      final json = _prefs?.getString(_recentFoldersKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        final folders = list.map((item) => RecentFolder.fromMap(item)).toList();
        _memoryCache[_recentFoldersKey] = folders;
        return folders;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting recent folders: $e');
      return [];
    }
  }

  /// Clear recent folders
  Future<void> clearRecentFolders() async {
    try {
      await _prefs?.remove(_recentFoldersKey);
      _memoryCache.remove(_recentFoldersKey);
      
      _eventController.add(StorageEvent(
        type: StorageEventType.cleared,
        key: _recentFoldersKey,
        data: null,
      ));
      
      debugPrint('Recent folders cleared');
    } catch (e) {
      debugPrint('Error clearing recent folders: $e');
    }
  }

  /// Add bookmarked folder
  Future<void> addBookmarkedFolder(String folderPath, String name) async {
    try {
      final bookmarks = await getBookmarkedFolders();
      
      // Check if already bookmarked
      if (bookmarks.any((bookmark) => bookmark.path == folderPath)) {
        return;
      }
      
      bookmarks.add(BookmarkedFolder(
        path: folderPath,
        name: name,
        createdAt: DateTime.now(),
      ));
      
      await _saveBookmarkedFolders(bookmarks);
      debugPrint('Added bookmarked folder: $folderPath');
    } catch (e) {
      debugPrint('Error adding bookmarked folder: $e');
    }
  }

  /// Get bookmarked folders
  Future<List<BookmarkedFolder>> getBookmarkedFolders() async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(_bookmarkedFoldersKey)) {
        return List<BookmarkedFolder>.from(_memoryCache[_bookmarkedFoldersKey]);
      }

      // Load from persistent storage
      final json = _prefs?.getString(_bookmarkedFoldersKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        final folders = list.map((item) => BookmarkedFolder.fromMap(item)).toList();
        _memoryCache[_bookmarkedFoldersKey] = folders;
        return folders;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting bookmarked folders: $e');
      return [];
    }
  }

  /// Remove bookmarked folder
  Future<void> removeBookmarkedFolder(String folderPath) async {
    try {
      final bookmarks = await getBookmarkedFolders();
      bookmarks.removeWhere((bookmark) => bookmark.path == folderPath);
      await _saveBookmarkedFolders(bookmarks);
      debugPrint('Removed bookmarked folder: $folderPath');
    } catch (e) {
      debugPrint('Error removing bookmarked folder: $e');
    }
  }

  /// Save organization preset
  Future<void> saveOrganizationPreset(OrganizationPreset preset) async {
    try {
      final presets = await getOrganizationPresets();
      
      // Remove existing preset with same name
      presets.removeWhere((p) => p.name == preset.name);
      
      presets.add(preset);
      await _saveOrganizationPresets(presets);
      debugPrint('Saved organization preset: ${preset.name}');
    } catch (e) {
      debugPrint('Error saving organization preset: $e');
    }
  }

  /// Get organization presets
  Future<List<OrganizationPreset>> getOrganizationPresets() async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(_organizationPresetsKey)) {
        return List<OrganizationPreset>.from(_memoryCache[_organizationPresetsKey]);
      }

      // Load from persistent storage
      final json = _prefs?.getString(_organizationPresetsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        final presets = list.map((item) => OrganizationPreset.fromMap(item)).toList();
        _memoryCache[_organizationPresetsKey] = presets;
        return presets;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting organization presets: $e');
      return [];
    }
  }

  /// Remove organization preset
  Future<void> removeOrganizationPreset(String presetName) async {
    try {
      final presets = await getOrganizationPresets();
      presets.removeWhere((preset) => preset.name == presetName);
      await _saveOrganizationPresets(presets);
      debugPrint('Removed organization preset: $presetName');
    } catch (e) {
      debugPrint('Error removing organization preset: $e');
    }
  }

  /// Save app settings
  Future<void> saveAppSettings(AppSettings settings) async {
    try {
      final json = jsonEncode(settings.toMap());
      await _prefs?.setString(_appSettingsKey, json);
      _memoryCache[_appSettingsKey] = settings;
      
      _eventController.add(StorageEvent(
        type: StorageEventType.updated,
        key: _appSettingsKey,
        data: settings,
      ));
      
      debugPrint('App settings saved');
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  /// Get app settings
  Future<AppSettings> getAppSettings() async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(_appSettingsKey)) {
        return _memoryCache[_appSettingsKey] as AppSettings;
      }

      // Load from persistent storage
      final json = _prefs?.getString(_appSettingsKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final settings = AppSettings.fromMap(map);
        _memoryCache[_appSettingsKey] = settings;
        return settings;
      }

      // Return default settings
      final defaultSettings = AppSettings.defaultSettings();
      await saveAppSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      debugPrint('Error getting app settings: $e');
      return AppSettings.defaultSettings();
    }
  }

  /// Get storage usage statistics
  Future<StorageStatistics> getStorageStatistics() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      int totalSize = 0;
      final categorySizes = <String, int>{};

      for (final key in keys) {
        final value = _prefs?.get(key);
        if (value is String) {
          final size = value.length * 2; // UTF-16 encoding
          totalSize += size;
          
          // Categorize by key prefix
          final category = key.split('_').first;
          categorySizes[category] = (categorySizes[category] ?? 0) + size;
        }
      }

      return StorageStatistics(
        totalSize: totalSize,
        totalKeys: keys.length,
        categorySizes: categorySizes,
        memoryCache: _memoryCache.length,
      );
    } catch (e) {
      debugPrint('Error getting storage statistics: $e');
      return StorageStatistics(
        totalSize: 0,
        totalKeys: 0,
        categorySizes: {},
        memoryCache: 0,
      );
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await _prefs?.clear();
      _memoryCache.clear();
      
      _eventController.add(StorageEvent(
        type: StorageEventType.cleared,
        key: 'all',
        data: null,
      ));
      
      debugPrint('All local storage data cleared');
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  /// Export data for backup
  Future<Map<String, dynamic>> exportData() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final data = <String, dynamic>{};
      
      for (final key in keys) {
        final value = _prefs?.get(key);
        if (value != null) {
          data[key] = value;
        }
      }
      
      return {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {};
    }
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> backupData) async {
    try {
      final data = backupData['data'] as Map<String, dynamic>?;
      if (data == null) return;

      for (final entry in data.entries) {
        if (entry.value is String) {
          await _prefs?.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await _prefs?.setInt(entry.key, entry.value);
        } else if (entry.value is double) {
          await _prefs?.setDouble(entry.key, entry.value);
        } else if (entry.value is bool) {
          await _prefs?.setBool(entry.key, entry.value);
        } else if (entry.value is List<String>) {
          await _prefs?.setStringList(entry.key, entry.value);
        }
      }
      
      // Clear memory cache to force reload
      _memoryCache.clear();
      await _loadInitialData();
      
      _eventController.add(StorageEvent(
        type: StorageEventType.imported,
        key: 'all',
        data: backupData,
      ));
      
      debugPrint('Data imported successfully');
    } catch (e) {
      debugPrint('Error importing data: $e');
    }
  }

  // Private methods

  Future<void> _loadInitialData() async {
    // Preload frequently accessed data into memory cache
    await getUserPreferences();
    await getAppSettings();
    await getRecentFolders();
    await getBookmarkedFolders();
  }

  Future<void> _saveRecentFolders(List<RecentFolder> folders) async {
    final json = jsonEncode(folders.map((f) => f.toMap()).toList());
    await _prefs?.setString(_recentFoldersKey, json);
    _memoryCache[_recentFoldersKey] = folders;
    
    _eventController.add(StorageEvent(
      type: StorageEventType.updated,
      key: _recentFoldersKey,
      data: folders,
    ));
  }

  Future<void> _saveBookmarkedFolders(List<BookmarkedFolder> folders) async {
    final json = jsonEncode(folders.map((f) => f.toMap()).toList());
    await _prefs?.setString(_bookmarkedFoldersKey, json);
    _memoryCache[_bookmarkedFoldersKey] = folders;
    
    _eventController.add(StorageEvent(
      type: StorageEventType.updated,
      key: _bookmarkedFoldersKey,
      data: folders,
    ));
  }

  Future<void> _saveOrganizationPresets(List<OrganizationPreset> presets) async {
    final json = jsonEncode(presets.map((p) => p.toMap()).toList());
    await _prefs?.setString(_organizationPresetsKey, json);
    _memoryCache[_organizationPresetsKey] = presets;
    
    _eventController.add(StorageEvent(
      type: StorageEventType.updated,
      key: _organizationPresetsKey,
      data: presets,
    ));
  }

  /// Dispose of the service
  void dispose() {
    _eventController.close();
  }
}

/// User preferences data class
class UserPreferences {
  final String theme;
  final String language;
  final bool enableNotifications;
  final bool enableHapticFeedback;
  final bool enableAnimations;
  final double thumbnailSize;
  final String defaultOrganizationStyle;
  final bool autoExecuteOperations;
  final int maxRecentFolders;
  final bool enableAdvancedFeatures;

  const UserPreferences({
    required this.theme,
    required this.language,
    required this.enableNotifications,
    required this.enableHapticFeedback,
    required this.enableAnimations,
    required this.thumbnailSize,
    required this.defaultOrganizationStyle,
    required this.autoExecuteOperations,
    required this.maxRecentFolders,
    required this.enableAdvancedFeatures,
  });

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      theme: 'system',
      language: 'en',
      enableNotifications: true,
      enableHapticFeedback: true,
      enableAnimations: true,
      thumbnailSize: 64.0,
      defaultOrganizationStyle: 'smart',
      autoExecuteOperations: false,
      maxRecentFolders: 20,
      enableAdvancedFeatures: false,
    );
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'en',
      enableNotifications: map['enableNotifications'] ?? true,
      enableHapticFeedback: map['enableHapticFeedback'] ?? true,
      enableAnimations: map['enableAnimations'] ?? true,
      thumbnailSize: (map['thumbnailSize'] ?? 64.0).toDouble(),
      defaultOrganizationStyle: map['defaultOrganizationStyle'] ?? 'smart',
      autoExecuteOperations: map['autoExecuteOperations'] ?? false,
      maxRecentFolders: map['maxRecentFolders'] ?? 20,
      enableAdvancedFeatures: map['enableAdvancedFeatures'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'enableNotifications': enableNotifications,
      'enableHapticFeedback': enableHapticFeedback,
      'enableAnimations': enableAnimations,
      'thumbnailSize': thumbnailSize,
      'defaultOrganizationStyle': defaultOrganizationStyle,
      'autoExecuteOperations': autoExecuteOperations,
      'maxRecentFolders': maxRecentFolders,
      'enableAdvancedFeatures': enableAdvancedFeatures,
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? enableNotifications,
    bool? enableHapticFeedback,
    bool? enableAnimations,
    double? thumbnailSize,
    String? defaultOrganizationStyle,
    bool? autoExecuteOperations,
    int? maxRecentFolders,
    bool? enableAdvancedFeatures,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
      defaultOrganizationStyle: defaultOrganizationStyle ?? this.defaultOrganizationStyle,
      autoExecuteOperations: autoExecuteOperations ?? this.autoExecuteOperations,
      maxRecentFolders: maxRecentFolders ?? this.maxRecentFolders,
      enableAdvancedFeatures: enableAdvancedFeatures ?? this.enableAdvancedFeatures,
    );
  }
}

/// Recent folder data class
class RecentFolder {
  final String path;
  final DateTime lastAccessed;
  final int accessCount;

  const RecentFolder({
    required this.path,
    required this.lastAccessed,
    required this.accessCount,
  });

  factory RecentFolder.fromMap(Map<String, dynamic> map) {
    return RecentFolder(
      path: map['path'],
      lastAccessed: DateTime.parse(map['lastAccessed']),
      accessCount: map['accessCount'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'lastAccessed': lastAccessed.toIso8601String(),
      'accessCount': accessCount,
    };
  }
}

/// Bookmarked folder data class
class BookmarkedFolder {
  final String path;
  final String name;
  final DateTime createdAt;

  const BookmarkedFolder({
    required this.path,
    required this.name,
    required this.createdAt,
  });

  factory BookmarkedFolder.fromMap(Map<String, dynamic> map) {
    return BookmarkedFolder(
      path: map['path'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Organization preset data class
class OrganizationPreset {
  final String name;
  final String description;
  final String organizationStyle;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final int usageCount;

  const OrganizationPreset({
    required this.name,
    required this.description,
    required this.organizationStyle,
    required this.settings,
    required this.createdAt,
    required this.usageCount,
  });

  factory OrganizationPreset.fromMap(Map<String, dynamic> map) {
    return OrganizationPreset(
      name: map['name'],
      description: map['description'],
      organizationStyle: map['organizationStyle'],
      settings: Map<String, dynamic>.from(map['settings']),
      createdAt: DateTime.parse(map['createdAt']),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'organizationStyle': organizationStyle,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'usageCount': usageCount,
    };
  }
}

/// App settings data class
class AppSettings {
  final bool enableDebugMode;
  final bool enablePerformanceMonitoring;
  final int maxCacheSize;
  final Duration cacheExpiration;
  final bool enableBackgroundSync;
  final String logLevel;

  const AppSettings({
    required this.enableDebugMode,
    required this.enablePerformanceMonitoring,
    required this.maxCacheSize,
    required this.cacheExpiration,
    required this.enableBackgroundSync,
    required this.logLevel,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      enableDebugMode: false,
      enablePerformanceMonitoring: false,
      maxCacheSize: 100 * 1024 * 1024, // 100MB
      cacheExpiration: Duration(hours: 24),
      enableBackgroundSync: true,
      logLevel: 'info',
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      enableDebugMode: map['enableDebugMode'] ?? false,
      enablePerformanceMonitoring: map['enablePerformanceMonitoring'] ?? false,
      maxCacheSize: map['maxCacheSize'] ?? 100 * 1024 * 1024,
      cacheExpiration: Duration(milliseconds: map['cacheExpiration'] ?? 24 * 60 * 60 * 1000),
      enableBackgroundSync: map['enableBackgroundSync'] ?? true,
      logLevel: map['logLevel'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableDebugMode': enableDebugMode,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'maxCacheSize': maxCacheSize,
      'cacheExpiration': cacheExpiration.inMilliseconds,
      'enableBackgroundSync': enableBackgroundSync,
      'logLevel': logLevel,
    };
  }
}

/// Storage event data class
class StorageEvent {
  final StorageEventType type;
  final String key;
  final dynamic data;
  final DateTime timestamp;

  StorageEvent({
    required this.type,
    required this.key,
    required this.data,
  }) : timestamp = DateTime.now();
}

/// Storage event types
enum StorageEventType {
  updated,
  cleared,
  imported,
}

/// Storage statistics
class StorageStatistics {
  final int totalSize;
  final int totalKeys;
  final Map<String, int> categorySizes;
  final int memoryCache;

  const StorageStatistics({
    required this.totalSize,
    required this.totalKeys,
    required this.categorySizes,
    required this.memoryCache,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalSize': totalSize,
      'totalKeys': totalKeys,
      'categorySizes': categorySizes,
      'memoryCache': memoryCache,
    };
  }
}
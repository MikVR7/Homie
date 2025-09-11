import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import 'local_storage_service.dart';
import '../providers/file_organizer_provider.dart';

/// Background synchronization service for data refresh and cache management
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  // Services
  final CacheService _cacheService = CacheService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  // Sync configuration
  Timer? _syncTimer;
  Timer? _cacheCleanupTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  // Sync intervals
  static const Duration _defaultSyncInterval = Duration(minutes: 15);
  static const Duration _cacheCleanupInterval = Duration(hours: 1);
  static const Duration _retryDelay = Duration(minutes: 5);
  
  // Sync statistics
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  DateTime? _lastSyncTime;
  DateTime? _lastSuccessfulSync;
  
  // Event streams
  final StreamController<SyncEvent> _syncEventController = 
      StreamController<SyncEvent>.broadcast();
  final StreamController<SyncStatus> _statusController = 
      StreamController<SyncStatus>.broadcast();

  /// Initialize the background sync service
  Future<void> initialize({
    Duration? syncInterval,
    Duration? cacheCleanupInterval,
    bool enableAutoSync = true,
  }) async {
    if (_isInitialized) return;

    try {
      await _cacheService.initialize();
      await _localStorage.initialize();
      
      if (enableAutoSync) {
        await _startBackgroundSync(syncInterval ?? _defaultSyncInterval);
      }
      
      await _startCacheCleanup(cacheCleanupInterval ?? _cacheCleanupInterval);
      
      _isInitialized = true;
      debugPrint('BackgroundSyncService initialized');
    } catch (e) {
      debugPrint('Error initializing BackgroundSyncService: $e');
    }
  }

  /// Get sync event stream
  Stream<SyncEvent> get syncEventStream => _syncEventController.stream;
  
  /// Get sync status stream
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Perform manual sync
  Future<SyncResult> performSync({bool force = false}) async {
    if (_isSyncing && !force) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedItems: 0,
      );
    }

    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    
    _statusController.add(SyncStatus.syncing);
    _syncEventController.add(SyncEvent(
      type: SyncEventType.started,
      timestamp: DateTime.now(),
    ));

    try {
      final result = await _performSyncOperations();
      
      if (result.success) {
        _successfulSyncs++;
        _lastSuccessfulSync = DateTime.now();
        _statusController.add(SyncStatus.completed);
      } else {
        _failedSyncs++;
        _statusController.add(SyncStatus.failed);
      }
      
      _syncEventController.add(SyncEvent(
        type: result.success ? SyncEventType.completed : SyncEventType.failed,
        timestamp: DateTime.now(),
        data: result,
      ));
      
      return result;
    } catch (e) {
      _failedSyncs++;
      _statusController.add(SyncStatus.failed);
      
      final errorResult = SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedItems: 0,
      );
      
      _syncEventController.add(SyncEvent(
        type: SyncEventType.failed,
        timestamp: DateTime.now(),
        data: errorResult,
      ));
      
      return errorResult;
    } finally {
      _isSyncing = false;
    }
  }

  /// Get sync statistics
  SyncStatistics getStatistics() {
    return SyncStatistics(
      successfulSyncs: _successfulSyncs,
      failedSyncs: _failedSyncs,
      lastSyncTime: _lastSyncTime,
      lastSuccessfulSync: _lastSuccessfulSync,
      isCurrentlySyncing: _isSyncing,
    );
  }

  /// Enable/disable automatic sync
  Future<void> setAutoSyncEnabled(bool enabled, {Duration? interval}) async {
    if (enabled) {
      await _startBackgroundSync(interval ?? _defaultSyncInterval);
    } else {
      _stopBackgroundSync();
    }
  }

  /// Sync specific data category
  Future<SyncResult> syncCategory(String category) async {
    try {
      _syncEventController.add(SyncEvent(
        type: SyncEventType.categoryStarted,
        timestamp: DateTime.now(),
        data: category,
      ));

      int syncedItems = 0;
      
      switch (category) {
        case 'user_preferences':
          await _syncUserPreferences();
          syncedItems = 1;
          break;
        case 'recent_folders':
          syncedItems = await _syncRecentFolders();
          break;
        case 'bookmarks':
          syncedItems = await _syncBookmarks();
          break;
        case 'organization_presets':
          syncedItems = await _syncOrganizationPresets();
          break;
        case 'cache_metadata':
          syncedItems = await _syncCacheMetadata();
          break;
        default:
          throw ArgumentError('Unknown category: $category');
      }

      _syncEventController.add(SyncEvent(
        type: SyncEventType.categoryCompleted,
        timestamp: DateTime.now(),
        data: {'category': category, 'items': syncedItems},
      ));

      return SyncResult(
        success: true,
        message: 'Category $category synced successfully',
        syncedItems: syncedItems,
      );
    } catch (e) {
      _syncEventController.add(SyncEvent(
        type: SyncEventType.categoryFailed,
        timestamp: DateTime.now(),
        data: {'category': category, 'error': e.toString()},
      ));

      return SyncResult(
        success: false,
        message: 'Failed to sync category $category: $e',
        syncedItems: 0,
      );
    }
  }

  /// Optimize cache and storage
  Future<void> optimizeStorage() async {
    try {
      _syncEventController.add(SyncEvent(
        type: SyncEventType.optimizationStarted,
        timestamp: DateTime.now(),
      ));

      // Optimize cache
      await _cacheService.optimizeCache();
      
      // Clean up expired data
      await _cleanupExpiredData();
      
      // Compact storage
      await _compactStorage();

      _syncEventController.add(SyncEvent(
        type: SyncEventType.optimizationCompleted,
        timestamp: DateTime.now(),
      ));

      debugPrint('Storage optimization completed');
    } catch (e) {
      debugPrint('Error optimizing storage: $e');
      
      _syncEventController.add(SyncEvent(
        type: SyncEventType.optimizationFailed,
        timestamp: DateTime.now(),
        data: e.toString(),
      ));
    }
  }

  /// Dispose of the service
  void dispose() {
    _syncTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _syncEventController.close();
    _statusController.close();
  }

  // Private methods

  Future<void> _startBackgroundSync(Duration interval) async {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(interval, (timer) async {
      // Check if we should sync based on connectivity and app state
      if (await _shouldPerformSync()) {
        await performSync();
      }
    });
    
    debugPrint('Background sync started with interval: ${interval.inMinutes} minutes');
  }

  void _stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Background sync stopped');
  }

  Future<void> _startCacheCleanup(Duration interval) async {
    _cacheCleanupTimer?.cancel();
    
    _cacheCleanupTimer = Timer.periodic(interval, (timer) async {
      await _performCacheCleanup();
    });
    
    debugPrint('Cache cleanup started with interval: ${interval.inHours} hours');
  }

  Future<bool> _shouldPerformSync() async {
    try {
      // Check connectivity
      final connectivity = Connectivity();
      final connectivityResults = await connectivity.checkConnectivity();
      if (!connectivityResults.contains(ConnectivityResult.mobile) &&
          !connectivityResults.contains(ConnectivityResult.wifi) &&
          !connectivityResults.contains(ConnectivityResult.ethernet)) {
        return false;
      }

      // Check if enough time has passed since last sync
      if (_lastSyncTime != null) {
        final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
        if (timeSinceLastSync < const Duration(minutes: 5)) {
          return false;
        }
      }

      // Check app settings
      final appSettings = await _localStorage.getAppSettings();
      if (!appSettings.enableBackgroundSync) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking sync conditions: $e');
      return false;
    }
  }

  Future<SyncResult> _performSyncOperations() async {
    int totalSyncedItems = 0;
    final errors = <String>[];

    try {
      // Sync user preferences
      await _syncUserPreferences();
      totalSyncedItems++;

      // Sync recent folders
      final recentFoldersSynced = await _syncRecentFolders();
      totalSyncedItems += recentFoldersSynced;

      // Sync bookmarks
      final bookmarksSynced = await _syncBookmarks();
      totalSyncedItems += bookmarksSynced;

      // Sync organization presets
      final presetsSynced = await _syncOrganizationPresets();
      totalSyncedItems += presetsSynced;

      // Sync cache metadata
      final cacheSynced = await _syncCacheMetadata();
      totalSyncedItems += cacheSynced;

      // Refresh critical data
      await _refreshCriticalData();

      return SyncResult(
        success: errors.isEmpty,
        message: errors.isEmpty 
            ? 'Sync completed successfully'
            : 'Sync completed with errors: ${errors.join(', ')}',
        syncedItems: totalSyncedItems,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedItems: totalSyncedItems,
      );
    }
  }

  Future<void> _syncUserPreferences() async {
    try {
      final preferences = await _localStorage.getUserPreferences();
      await _cacheService.cacheData(
        'user_preferences',
        preferences.toMap(),
        ttl: const Duration(days: 30),
        category: 'preferences',
      );
    } catch (e) {
      debugPrint('Error syncing user preferences: $e');
      rethrow;
    }
  }

  Future<int> _syncRecentFolders() async {
    try {
      final recentFolders = await _localStorage.getRecentFolders();
      await _cacheService.cacheData(
        'recent_folders',
        recentFolders.map((f) => f.toMap()).toList(),
        ttl: const Duration(days: 7),
        category: 'folders',
      );
      return recentFolders.length;
    } catch (e) {
      debugPrint('Error syncing recent folders: $e');
      return 0;
    }
  }

  Future<int> _syncBookmarks() async {
    try {
      final bookmarks = await _localStorage.getBookmarkedFolders();
      await _cacheService.cacheData(
        'bookmarked_folders',
        bookmarks.map((f) => f.toMap()).toList(),
        ttl: const Duration(days: 30),
        category: 'folders',
      );
      return bookmarks.length;
    } catch (e) {
      debugPrint('Error syncing bookmarks: $e');
      return 0;
    }
  }

  Future<int> _syncOrganizationPresets() async {
    try {
      final presets = await _localStorage.getOrganizationPresets();
      await _cacheService.cacheData(
        'organization_presets',
        presets.map((p) => p.toMap()).toList(),
        ttl: const Duration(days: 30),
        category: 'presets',
      );
      return presets.length;
    } catch (e) {
      debugPrint('Error syncing organization presets: $e');
      return 0;
    }
  }

  Future<int> _syncCacheMetadata() async {
    try {
      final cacheStats = _cacheService.getStatistics();
      await _cacheService.cacheData(
        'cache_statistics',
        cacheStats.toMap(),
        ttl: const Duration(hours: 1),
        category: 'metadata',
      );
      return 1;
    } catch (e) {
      debugPrint('Error syncing cache metadata: $e');
      return 0;
    }
  }

  Future<void> _refreshCriticalData() async {
    try {
      // This would refresh data that needs to be current
      // For now, just update the last refresh timestamp
      await _cacheService.cacheData(
        'last_refresh',
        DateTime.now().toIso8601String(),
        ttl: const Duration(hours: 1),
        category: 'metadata',
      );
    } catch (e) {
      debugPrint('Error refreshing critical data: $e');
    }
  }

  Future<void> _performCacheCleanup() async {
    try {
      await _cacheService.optimizeCache();
      
      _syncEventController.add(SyncEvent(
        type: SyncEventType.cacheCleanup,
        timestamp: DateTime.now(),
      ));
      
      debugPrint('Cache cleanup completed');
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    }
  }

  Future<void> _cleanupExpiredData() async {
    try {
      // Remove expired cache entries
      await _cacheService.optimizeCache();
      
      // Clean up old recent folders (older than 30 days)
      final recentFolders = await _localStorage.getRecentFolders();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final filteredFolders = recentFolders
          .where((folder) => folder.lastAccessed.isAfter(cutoffDate))
          .toList();
      
      if (filteredFolders.length != recentFolders.length) {
        // Save the filtered list
        await _localStorage.clearRecentFolders();
        for (final folder in filteredFolders) {
          await _localStorage.addRecentFolder(folder.path);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired data: $e');
    }
  }

  Future<void> _compactStorage() async {
    try {
      // Get storage statistics
      final stats = await _localStorage.getStorageStatistics();
      
      // If storage is getting large, consider compacting
      if (stats.totalSize > 10 * 1024 * 1024) { // 10MB
        debugPrint('Storage size is ${stats.totalSize} bytes, considering compaction');
        
        // Export and re-import data to compact it
        final exportedData = await _localStorage.exportData();
        await _localStorage.clearAllData();
        await _localStorage.importData(exportedData);
        
        debugPrint('Storage compaction completed');
      }
    } catch (e) {
      debugPrint('Error compacting storage: $e');
    }
  }
}

/// Sync result data class
class SyncResult {
  final bool success;
  final String message;
  final int syncedItems;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedItems,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'syncedItems': syncedItems,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Sync statistics
class SyncStatistics {
  final int successfulSyncs;
  final int failedSyncs;
  final DateTime? lastSyncTime;
  final DateTime? lastSuccessfulSync;
  final bool isCurrentlySyncing;

  const SyncStatistics({
    required this.successfulSyncs,
    required this.failedSyncs,
    this.lastSyncTime,
    this.lastSuccessfulSync,
    required this.isCurrentlySyncing,
  });

  double get successRate {
    final total = successfulSyncs + failedSyncs;
    return total > 0 ? successfulSyncs / total : 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'lastSuccessfulSync': lastSuccessfulSync?.toIso8601String(),
      'isCurrentlySyncing': isCurrentlySyncing,
      'successRate': successRate,
    };
  }
}

/// Sync event data class
class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final dynamic data;

  const SyncEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

/// Sync event types
enum SyncEventType {
  started,
  completed,
  failed,
  categoryStarted,
  categoryCompleted,
  categoryFailed,
  optimizationStarted,
  optimizationCompleted,
  optimizationFailed,
  cacheCleanup,
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}
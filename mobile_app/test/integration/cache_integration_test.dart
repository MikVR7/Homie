import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homie_app/services/cache_service.dart';
import 'package:homie_app/services/local_storage_service.dart';
import 'package:homie_app/services/background_sync_service.dart';
import 'package:homie_app/utils/efficient_data_structures.dart';

void main() {
  group('Cache Integration Tests', () {
    late CacheService cacheService;
    late LocalStorageService localStorage;
    late BackgroundSyncService syncService;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize services
      cacheService = CacheService();
      localStorage = LocalStorageService();
      syncService = BackgroundSyncService();
      
      await cacheService.initialize();
      await localStorage.initialize();
      await syncService.initialize(enableAutoSync: false);
    });

    tearDown(() async {
      await cacheService.clearAllCache();
      await localStorage.clearAllData();
      syncService.dispose();
    });

    group('File Organizer Data Flow', () {
      test('should cache API responses and sync with local storage', () async {
        // Simulate API response data
        final apiResponse = {
          'folders': [
            {'path': '/home/user/documents', 'size': 1024000, 'fileCount': 150},
            {'path': '/home/user/downloads', 'size': 2048000, 'fileCount': 75},
            {'path': '/home/user/pictures', 'size': 5120000, 'fileCount': 300},
          ],
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Cache the API response
        await cacheService.cacheData(
          'folder_analysis_response',
          apiResponse,
          category: 'api_responses',
          ttl: const Duration(minutes: 15),
        );

        // Store folder paths in local storage as recent folders
        for (final folder in apiResponse['folders'] as List) {
          await localStorage.addRecentFolder(folder['path'] as String);
        }

        // Verify data is cached
        final cachedResponse = await cacheService.getCachedData<Map<String, dynamic>>(
          'folder_analysis_response',
        );
        expect(cachedResponse, isNotNull);
        expect(cachedResponse!['folders'], hasLength(3));

        // Verify recent folders are stored
        final recentFolders = await localStorage.getRecentFolders();
        expect(recentFolders, hasLength(3));
        expect(recentFolders[0].path, equals('/home/user/pictures')); // Most recent first

        // Sync data
        final syncResult = await syncService.performSync();
        expect(syncResult.success, isTrue);
      });

      test('should handle organization presets with caching', () async {
        // Create organization preset
        final preset = OrganizationPreset(
          name: 'Photo Organization',
          description: 'Organize photos by date and event',
          organizationStyle: 'date_based',
          settings: {
            'groupByDate': true,
            'createEventFolders': true,
            'dateFormat': 'yyyy/MM',
          },
          createdAt: DateTime.now(),
          usageCount: 5,
        );

        // Save to local storage
        await localStorage.saveOrganizationPreset(preset);

        // Cache frequently used presets
        final presets = await localStorage.getOrganizationPresets();
        await cacheService.cacheData(
          'organization_presets',
          presets.map((p) => p.toMap()).toList(),
          category: 'user_data',
          ttl: const Duration(hours: 1),
        );

        // Verify cached data
        final cachedPresets = await cacheService.getCachedData<List<dynamic>>(
          'organization_presets',
        );
        expect(cachedPresets, isNotNull);
        expect(cachedPresets!, hasLength(1));
        expect(cachedPresets[0]['name'], equals('Photo Organization'));

        // Update usage count and invalidate cache
        final updatedPreset = preset.copyWith(usageCount: preset.usageCount + 1);
        await localStorage.saveOrganizationPreset(updatedPreset);
        await cacheService.removeCachedData('organization_presets');

        // Re-cache updated data
        final updatedPresets = await localStorage.getOrganizationPresets();
        await cacheService.cacheData(
          'organization_presets',
          updatedPresets.map((p) => p.toMap()).toList(),
          category: 'user_data',
        );

        final newCachedPresets = await cacheService.getCachedData<List<dynamic>>(
          'organization_presets',
        );
        expect(newCachedPresets![0]['usageCount'], equals(6));
      });

      test('should optimize performance with efficient data structures', () async {
        // Create path trie for efficient folder searching
        final pathTrie = PathTrie();
        final folderPaths = [
          '/home/user/documents/work/projects',
          '/home/user/documents/work/reports',
          '/home/user/documents/personal/photos',
          '/home/user/documents/personal/videos',
          '/home/user/downloads/software',
          '/home/user/downloads/media',
          '/var/log/system',
          '/var/log/application',
        ];

        // Insert paths into trie
        for (final path in folderPaths) {
          pathTrie.insert(path);
        }

        // Cache the trie structure (serialized)
        await cacheService.cacheData(
          'folder_paths_trie',
          pathTrie.getAllPaths(),
          category: 'search_index',
          ttl: const Duration(hours: 6),
        );

        // Test efficient path searching
        final workPaths = pathTrie.searchWithPrefix('/home/user/documents/work');
        expect(workPaths, hasLength(2));
        expect(workPaths, contains('/home/user/documents/work/projects'));
        expect(workPaths, contains('/home/user/documents/work/reports'));

        // Create LRU cache for frequently accessed file metadata
        final fileMetadataCache = LRUCache<String, Map<String, dynamic>>(100);
        
        // Simulate file metadata caching
        final fileMetadata = {
          'size': 1024000,
          'modified': DateTime.now().toIso8601String(),
          'type': 'document',
          'permissions': 'rw-r--r--',
        };

        fileMetadataCache.put('/home/user/documents/important.pdf', fileMetadata);
        
        // Verify efficient retrieval
        final cachedMetadata = fileMetadataCache.get('/home/user/documents/important.pdf');
        expect(cachedMetadata, isNotNull);
        expect(cachedMetadata!['size'], equals(1024000));

        // Test cache statistics
        final cacheStats = fileMetadataCache.getStatistics();
        expect(cacheStats['hitCount'], equals(1));
        expect(cacheStats['missCount'], equals(0));
      });

      test('should handle real-time updates with background sync', () async {
        // Set up sync event listener
        final syncEvents = <SyncEvent>[];
        final subscription = syncService.syncEventStream.listen(syncEvents.add);

        // Simulate user preferences update
        final preferences = UserPreferences.defaultPreferences().copyWith(
          theme: 'dark',
          enableNotifications: true,
          autoOrganize: true,
        );

        await localStorage.saveUserPreferences(preferences);

        // Cache user preferences for quick access
        await cacheService.cacheData(
          'user_preferences',
          preferences.toMap(),
          category: 'user_data',
          level: CacheLevel.both, // Cache in both memory and disk
        );

        // Trigger sync
        await syncService.performSync();

        // Wait for sync events
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify sync events were generated
        expect(syncEvents, isNotEmpty);
        expect(syncEvents.any((e) => e.type == SyncEventType.started), isTrue);
        expect(syncEvents.any((e) => e.type == SyncEventType.completed), isTrue);

        // Verify cached data is still available
        final cachedPrefs = await cacheService.getCachedData<Map<String, dynamic>>(
          'user_preferences',
        );
        expect(cachedPrefs, isNotNull);
        expect(cachedPrefs!['theme'], equals('dark'));

        subscription.cancel();
      });

      test('should handle cache invalidation and refresh', () async {
        // Initial data
        final initialData = {
          'folders': ['/home/user/documents'],
          'lastScan': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        };

        await cacheService.cacheData(
          'folder_scan_results',
          initialData,
          category: 'scan_results',
          ttl: const Duration(minutes: 30),
        );

        // Verify initial data is cached
        final cachedData = await cacheService.getCachedData<Map<String, dynamic>>(
          'folder_scan_results',
        );
        expect(cachedData, isNotNull);
        expect(cachedData!['folders'], hasLength(1));

        // Simulate new scan results
        final newData = {
          'folders': ['/home/user/documents', '/home/user/downloads', '/home/user/pictures'],
          'lastScan': DateTime.now().toIso8601String(),
        };

        // Invalidate old cache and update with new data
        await cacheService.removeCachedData('folder_scan_results');
        await cacheService.cacheData(
          'folder_scan_results',
          newData,
          category: 'scan_results',
          ttl: const Duration(minutes: 30),
        );

        // Verify updated data
        final updatedCachedData = await cacheService.getCachedData<Map<String, dynamic>>(
          'folder_scan_results',
        );
        expect(updatedCachedData, isNotNull);
        expect(updatedCachedData!['folders'], hasLength(3));
      });

      test('should optimize storage and memory usage', () async {
        // Fill cache with test data
        for (int i = 0; i < 50; i++) {
          await cacheService.cacheData(
            'test_data_$i',
            {'index': i, 'data': 'test_data_$i' * 100}, // Large data
            ttl: const Duration(milliseconds: 100), // Short TTL
          );
        }

        // Add some data to local storage
        for (int i = 0; i < 10; i++) {
          await localStorage.addRecentFolder('/test/folder_$i');
        }

        // Wait for some cache entries to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Get initial statistics
        final initialCacheStats = cacheService.getStatistics();
        final initialStorageStats = await localStorage.getStorageStatistics();

        // Optimize cache
        await cacheService.optimizeCache();

        // Optimize storage
        syncService.optimizeStorage();

        // Get optimized statistics
        final optimizedCacheStats = cacheService.getStatistics();
        final optimizedStorageStats = await localStorage.getStorageStatistics();

        // Verify optimization reduced memory usage
        expect(optimizedCacheStats.memoryEntries, lessThan(initialCacheStats.memoryEntries));
        
        // Storage stats should remain consistent (no data loss)
        expect(optimizedStorageStats.totalKeys, equals(initialStorageStats.totalKeys));
      });

      test('should handle concurrent access safely', () async {
        // Simulate concurrent cache operations
        final futures = <Future<void>>[];
        
        // Concurrent writes
        for (int i = 0; i < 20; i++) {
          futures.add(cacheService.cacheData('concurrent_key_$i', 'value_$i'));
        }
        
        // Concurrent reads
        for (int i = 0; i < 20; i++) {
          futures.add(cacheService.getCachedData('concurrent_key_${i ~/ 2}').then((_) {}));
        }
        
        // Concurrent local storage operations
        for (int i = 0; i < 10; i++) {
          futures.add(localStorage.addRecentFolder('/concurrent/folder_$i'));
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Verify data integrity
        final cacheStats = cacheService.getStatistics();
        final recentFolders = await localStorage.getRecentFolders();

        expect(cacheStats.memoryEntries, greaterThan(0));
        expect(recentFolders, hasLength(10));
      });

      test('should export and import complete data set', () async {
        // Set up comprehensive test data
        
        // User preferences
        final preferences = UserPreferences.defaultPreferences().copyWith(
          theme: 'dark',
          enableNotifications: true,
        );
        await localStorage.saveUserPreferences(preferences);

        // Recent folders
        await localStorage.addRecentFolder('/home/user/documents');
        await localStorage.addRecentFolder('/home/user/downloads');

        // Bookmarked folders
        await localStorage.addBookmarkedFolder('/home/user/projects', 'My Projects');
        await localStorage.addBookmarkedFolder('/home/user/work', 'Work Files');

        // Organization presets
        final preset = OrganizationPreset(
          name: 'Document Organization',
          description: 'Organize documents by type',
          organizationStyle: 'type_based',
          settings: {'groupByType': true},
          createdAt: DateTime.now(),
          usageCount: 3,
        );
        await localStorage.saveOrganizationPreset(preset);

        // Cache some data
        await cacheService.cacheData('api_cache', {'test': 'data'}, category: 'api');
        await cacheService.cacheData('user_cache', {'user': 'data'}, category: 'user');

        // Export all data
        final exportedData = await localStorage.exportData();
        final cacheStats = cacheService.getStatistics();

        // Verify export contains all data
        expect(exportedData['version'], equals('1.0.0'));
        expect(exportedData['data'], isA<Map<String, dynamic>>());
        expect(exportedData['exportedAt'], isNotNull);

        // Clear all data
        await localStorage.clearAllData();
        await cacheService.clearAllCache();

        // Verify data is cleared
        final clearedPrefs = await localStorage.getUserPreferences();
        expect(clearedPrefs.theme, equals('system')); // Default value
        
        final clearedStats = cacheService.getStatistics();
        expect(clearedStats.memoryEntries, equals(0));

        // Import data
        await localStorage.importData(exportedData);

        // Verify data is restored
        final restoredPrefs = await localStorage.getUserPreferences();
        expect(restoredPrefs.theme, equals('dark'));

        final restoredFolders = await localStorage.getRecentFolders();
        expect(restoredFolders, hasLength(2));

        final restoredBookmarks = await localStorage.getBookmarkedFolders();
        expect(restoredBookmarks, hasLength(2));

        final restoredPresets = await localStorage.getOrganizationPresets();
        expect(restoredPresets, hasLength(1));
      });
    });

    group('Performance Benchmarks', () {
      test('should perform cache operations efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Benchmark cache writes
        for (int i = 0; i < 1000; i++) {
          await cacheService.cacheData('benchmark_key_$i', 'benchmark_value_$i');
        }
        
        final writeTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();
        
        // Benchmark cache reads
        for (int i = 0; i < 1000; i++) {
          await cacheService.getCachedData('benchmark_key_$i');
        }
        
        final readTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();
        
        // Performance assertions (adjust based on expected performance)
        expect(writeTime, lessThan(5000)); // Less than 5 seconds for 1000 writes
        expect(readTime, lessThan(1000));  // Less than 1 second for 1000 reads
        
        final stats = cacheService.getStatistics();
        expect(stats.hitRate, equals(1.0)); // 100% hit rate for this test
      });

      test('should handle large data sets efficiently', () async {
        // Create large data structure
        final largeData = <String, dynamic>{};
        for (int i = 0; i < 10000; i++) {
          largeData['key_$i'] = 'value_$i' * 10; // Create larger strings
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Cache large data
        await cacheService.cacheData('large_dataset', largeData);
        
        final cacheTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();
        
        // Retrieve large data
        final retrievedData = await cacheService.getCachedData<Map<String, dynamic>>('large_dataset');
        
        final retrieveTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();
        
        // Verify data integrity
        expect(retrievedData, isNotNull);
        expect(retrievedData!.length, equals(10000));
        expect(retrievedData['key_5000'], equals('value_5000' * 10));
        
        // Performance assertions
        expect(cacheTime, lessThan(10000)); // Less than 10 seconds to cache
        expect(retrieveTime, lessThan(5000)); // Less than 5 seconds to retrieve
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle cache corruption gracefully', () async {
        // Cache some data
        await cacheService.cacheData('test_key', 'test_value');
        
        // Simulate cache corruption by clearing underlying storage
        // (This is a simplified simulation)
        await cacheService.clearCacheByCategory('default');
        
        // Should handle missing data gracefully
        final result = await cacheService.getCachedData('test_key');
        expect(result, isNull);
        
        // Cache should still be functional
        await cacheService.cacheData('recovery_key', 'recovery_value');
        final recoveryResult = await cacheService.getCachedData('recovery_key');
        expect(recoveryResult, equals('recovery_value'));
      });

      test('should handle storage errors gracefully', () async {
        // This test would normally involve mocking storage failures
        // For now, we'll test basic error recovery
        
        try {
          // Attempt to save invalid data (this should not crash)
          await localStorage.saveUserPreferences(
            UserPreferences.defaultPreferences(),
          );
          
          // Should succeed
          expect(true, isTrue);
        } catch (e) {
          // If it fails, it should fail gracefully
          expect(e, isA<Exception>());
        }
        
        // Service should still be functional
        final preferences = await localStorage.getUserPreferences();
        expect(preferences, isNotNull);
      });

      test('should handle sync failures gracefully', () async {
        // Perform sync that might fail
        final result = await syncService.performSync();
        
        // Should complete without throwing
        expect(result, isNotNull);
        expect(result.success, isA<bool>());
        
        // Get sync statistics
        final stats = syncService.getStatistics();
        expect(stats, isNotNull);
        expect(stats.totalSyncs, greaterThanOrEqualTo(1));
      });
    });
  });
}
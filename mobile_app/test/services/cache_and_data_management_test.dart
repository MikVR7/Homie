import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homie_app/services/cache_service.dart';
import 'package:homie_app/services/local_storage_service.dart';
import 'package:homie_app/services/background_sync_service.dart';
import 'package:homie_app/utils/efficient_data_structures.dart';

void main() {
  group('Cache and Data Management Tests', () {
    late CacheService cacheService;
    late LocalStorageService localStorageService;
    late BackgroundSyncService backgroundSyncService;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      cacheService = CacheService();
      localStorageService = LocalStorageService();
      backgroundSyncService = BackgroundSyncService();
      
      await cacheService.initialize();
      await localStorageService.initialize();
    });

    tearDown(() async {
      await cacheService.clearAllCache();
      await localStorageService.clearAllData();
      backgroundSyncService.dispose();
    });

    group('CacheService Tests', () {
      test('should cache and retrieve data with different levels', () async {
        const key = 'test_key';
        const data = 'test_data';
        
        // Test memory cache
        await cacheService.cacheData(key, data, level: CacheLevel.memory);
        final memoryData = await cacheService.getCachedData<String>(key);
        expect(memoryData, equals(data));
        
        // Test disk cache
        await cacheService.cacheData('${key}_disk', data, level: CacheLevel.disk);
        final diskData = await cacheService.getCachedData<String>('${key}_disk');
        expect(diskData, equals(data));
        
        // Test both cache
        await cacheService.cacheData('${key}_both', data, level: CacheLevel.both);
        final bothData = await cacheService.getCachedData<String>('${key}_both');
        expect(bothData, equals(data));
      });

      test('should respect TTL expiration', () async {
        const key = 'ttl_test';
        const data = 'ttl_data';
        
        await cacheService.cacheData(
          key, 
          data, 
          ttl: const Duration(milliseconds: 100),
        );
        
        // Should be available immediately
        final immediateData = await cacheService.getCachedData<String>(key);
        expect(immediateData, equals(data));
        
        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Should be expired now
        final expiredData = await cacheService.getCachedData<String>(key);
        expect(expiredData, isNull);
      });

      test('should clear cache by category', () async {
        await cacheService.cacheData('key1', 'data1', category: 'category_a');
        await cacheService.cacheData('key2', 'data2', category: 'category_a');
        await cacheService.cacheData('key3', 'data3', category: 'category_b');
        
        await cacheService.clearCacheByCategory('category_a');
        
        final data1 = await cacheService.getCachedData<String>('key1');
        final data2 = await cacheService.getCachedData<String>('key2');
        final data3 = await cacheService.getCachedData<String>('key3');
        
        expect(data1, isNull);
        expect(data2, isNull);
        expect(data3, equals('data3'));
      });

      test('should track cache statistics', () async {
        // Cache some data
        await cacheService.cacheData('hit_key', 'hit_data');
        
        // Hit
        await cacheService.getCachedData<String>('hit_key');
        
        // Miss
        await cacheService.getCachedData<String>('miss_key');
        
        final stats = cacheService.getStatistics();
        
        expect(stats.hitCount, greaterThan(0));
        expect(stats.missCount, greaterThan(0));
        expect(stats.hitRate, greaterThan(0));
        expect(stats.hitRate, lessThan(1));
      });

      test('should preload data efficiently', () async {
        final dataLoaders = {
          'preload_key1': () async => 'preload_data1',
          'preload_key2': () async => 'preload_data2',
        };
        
        await cacheService.preloadData(dataLoaders);
        
        final data1 = await cacheService.getCachedData<String>('preload_key1');
        final data2 = await cacheService.getCachedData<String>('preload_key2');
        
        expect(data1, equals('preload_data1'));
        expect(data2, equals('preload_data2'));
      });

      test('should optimize cache performance', () async {
        // Add some data with short TTL
        for (int i = 0; i < 10; i++) {
          await cacheService.cacheData(
            'key_$i', 
            'data_$i',
            ttl: const Duration(milliseconds: 50),
          );
        }
        
        // Wait for some to expire
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Optimize cache
        await cacheService.optimizeCache();
        
        final stats = cacheService.getStatistics();
        expect(stats.memoryEntries, lessThan(10));
      });
    });

    group('LocalStorageService Tests', () {
      test('should save and retrieve user preferences', () async {
        final preferences = UserPreferences.defaultPreferences().copyWith(
          theme: 'dark',
          language: 'es',
        );
        
        await localStorageService.saveUserPreferences(preferences);
        final retrievedPrefs = await localStorageService.getUserPreferences();
        
        expect(retrievedPrefs.theme, equals('dark'));
        expect(retrievedPrefs.language, equals('es'));
      });

      test('should manage recent folders', () async {
        const folderPath1 = '/path/to/folder1';
        const folderPath2 = '/path/to/folder2';
        
        await localStorageService.addRecentFolder(folderPath1);
        await localStorageService.addRecentFolder(folderPath2);
        
        final recentFolders = await localStorageService.getRecentFolders();
        
        expect(recentFolders.length, equals(2));
        expect(recentFolders.first.path, equals(folderPath2)); // Most recent first
        expect(recentFolders.last.path, equals(folderPath1));
      });

      test('should manage bookmarked folders', () async {
        const folderPath = '/path/to/bookmark';
        const folderName = 'My Bookmark';
        
        await localStorageService.addBookmarkedFolder(folderPath, folderName);
        
        final bookmarks = await localStorageService.getBookmarkedFolders();
        
        expect(bookmarks.length, equals(1));
        expect(bookmarks.first.path, equals(folderPath));
        expect(bookmarks.first.name, equals(folderName));
        
        await localStorageService.removeBookmarkedFolder(folderPath);
        
        final emptyBookmarks = await localStorageService.getBookmarkedFolders();
        expect(emptyBookmarks.length, equals(0));
      });

      test('should manage organization presets', () async {
        final preset = OrganizationPreset(
          name: 'Test Preset',
          description: 'A test preset',
          organizationStyle: 'by_type',
          settings: {'sortBy': 'name'},
          createdAt: DateTime.now(),
          usageCount: 0,
        );
        
        await localStorageService.saveOrganizationPreset(preset);
        
        final presets = await localStorageService.getOrganizationPresets();
        
        expect(presets.length, equals(1));
        expect(presets.first.name, equals('Test Preset'));
        expect(presets.first.organizationStyle, equals('by_type'));
        
        await localStorageService.removeOrganizationPreset('Test Preset');
        
        final emptyPresets = await localStorageService.getOrganizationPresets();
        expect(emptyPresets.length, equals(0));
      });

      test('should export and import data', () async {
        // Add some test data
        await localStorageService.addRecentFolder('/test/path');
        await localStorageService.addBookmarkedFolder('/bookmark/path', 'Test Bookmark');
        
        // Export data
        final exportedData = await localStorageService.exportData();
        
        expect(exportedData, isNotEmpty);
        expect(exportedData['version'], equals('1.0.0'));
        expect(exportedData['data'], isA<Map<String, dynamic>>());
        
        // Clear all data
        await localStorageService.clearAllData();
        
        // Verify data is cleared
        final emptyFolders = await localStorageService.getRecentFolders();
        expect(emptyFolders.length, equals(0));
        
        // Import data back
        await localStorageService.importData(exportedData);
        
        // Verify data is restored
        final restoredFolders = await localStorageService.getRecentFolders();
        final restoredBookmarks = await localStorageService.getBookmarkedFolders();
        
        expect(restoredFolders.length, equals(1));
        expect(restoredBookmarks.length, equals(1));
      });

      test('should provide storage statistics', () async {
        // Add some data
        await localStorageService.addRecentFolder('/test/path');
        await localStorageService.saveUserPreferences(UserPreferences.defaultPreferences());
        
        final stats = await localStorageService.getStorageStatistics();
        
        expect(stats.totalSize, greaterThan(0));
        expect(stats.totalKeys, greaterThan(0));
        expect(stats.categorySizes, isNotEmpty);
      });
    });

    group('BackgroundSyncService Tests', () {
      test('should initialize successfully', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        final stats = backgroundSyncService.getStatistics();
        expect(stats.successfulSyncs, equals(0));
        expect(stats.failedSyncs, equals(0));
        expect(stats.isCurrentlySyncing, isFalse);
      });

      test('should perform manual sync', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        // Add some data to sync
        await localStorageService.addRecentFolder('/test/sync');
        
        final result = await backgroundSyncService.performSync();
        
        expect(result.success, isTrue);
        expect(result.syncedItems, greaterThan(0));
        
        final stats = backgroundSyncService.getStatistics();
        expect(stats.successfulSyncs, equals(1));
      });

      test('should sync specific categories', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        // Add test data
        await localStorageService.addRecentFolder('/test/category');
        
        final result = await backgroundSyncService.syncCategory('recent_folders');
        
        expect(result.success, isTrue);
        expect(result.syncedItems, greaterThan(0));
      });

      test('should handle sync events', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        final events = <SyncEvent>[];
        backgroundSyncService.syncEventStream.listen((event) {
          events.add(event);
        });
        
        await backgroundSyncService.performSync();
        
        // Wait for events to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events.length, greaterThan(0));
        expect(events.any((e) => e.type == SyncEventType.started), isTrue);
        expect(events.any((e) => e.type == SyncEventType.completed), isTrue);
      });

      test('should optimize storage', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        // Add some cached data
        await cacheService.cacheData('optimize_test', 'test_data');
        
        // This should complete without errors
        await backgroundSyncService.optimizeStorage();
        
        // Verify cache is still functional
        final data = await cacheService.getCachedData<String>('optimize_test');
        expect(data, equals('test_data'));
      });
    });

    group('EfficientDataStructures Tests', () {
      test('should create and use Trie for path autocomplete', () {
        final trie = EfficientDataStructures.createPathTrie();
        
        // Insert some paths
        trie.insert('/home/user/documents', 'Documents');
        trie.insert('/home/user/downloads', 'Downloads');
        trie.insert('/home/user/desktop', 'Desktop');
        
        // Test search
        expect(trie.search('/home/user/documents'), equals('Documents'));
        expect(trie.search('/nonexistent'), isNull);
        
        // Test autocomplete
        final suggestions = trie.getAutocompleteSuggestions('/home/user/d');
        expect(suggestions.length, equals(2));
        expect(suggestions.contains('/home/user/documents'), isTrue);
        expect(suggestions.contains('/home/user/downloads'), isTrue);
      });

      test('should create and use LRU Cache', () {
        final cache = EfficientDataStructures.createLRUCache<String, String>(2);
        
        // Add items
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');
        
        expect(cache.get('key1'), equals('value1'));
        expect(cache.get('key2'), equals('value2'));
        
        // Add third item (should evict key1)
        cache.put('key3', 'value3');
        
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), equals('value2'));
        expect(cache.get('key3'), equals('value3'));
        
        // Check statistics
        final stats = cache.getStatistics();
        expect(stats['size'], equals(2));
        expect(stats['capacity'], equals(2));
      });

      test('should create and use Bloom Filter', () {
        final bloomFilter = EfficientDataStructures.createBloomFilter(100);
        
        // Add items
        bloomFilter.add('item1');
        bloomFilter.add('item2');
        bloomFilter.add('item3');
        
        // Test membership
        expect(bloomFilter.mightContain('item1'), isTrue);
        expect(bloomFilter.mightContain('item2'), isTrue);
        expect(bloomFilter.mightContain('item3'), isTrue);
        expect(bloomFilter.mightContain('nonexistent'), isFalse);
        
        // Check statistics
        final stats = bloomFilter.getStatistics();
        expect(stats['itemCount'], equals(3));
        expect(stats['size'], greaterThan(0));
      });

      test('should create and use Priority Queue', () {
        final priorityQueue = EfficientDataStructures.createPriorityQueue<int>((a, b) => a.compareTo(b));
        
        // Add items
        priorityQueue.add(5);
        priorityQueue.add(1);
        priorityQueue.add(3);
        priorityQueue.add(2);
        
        // Remove items (should be in priority order)
        expect(priorityQueue.removeFirst(), equals(1));
        expect(priorityQueue.removeFirst(), equals(2));
        expect(priorityQueue.removeFirst(), equals(3));
        expect(priorityQueue.removeFirst(), equals(5));
        
        expect(priorityQueue.isEmpty, isTrue);
      });

      test('should perform string matching operations', () {
        // Test fuzzy matching
        expect(StringMatcher.fuzzyMatch('abc', 'aabbcc'), isTrue);
        expect(StringMatcher.fuzzyMatch('xyz', 'abc'), isFalse);
        
        // Test similarity
        final similarity = StringMatcher.similarity('hello', 'hallo');
        expect(similarity, greaterThan(0.5));
        expect(similarity, lessThan(1.0));
        
        // Test regex matching
        expect(StringMatcher.regexMatch(r'\d+', 'test123'), isTrue);
        expect(StringMatcher.regexMatch(r'\d+', 'testABC'), isFalse);
        
        // Test case-insensitive contains
        expect(StringMatcher.containsIgnoreCase('Hello World', 'WORLD'), isTrue);
        expect(StringMatcher.containsIgnoreCase('Hello World', 'xyz'), isFalse);
      });
    });

    group('Integration Tests', () {
      test('should integrate cache and local storage', () async {
        // Save data to local storage
        await localStorageService.addRecentFolder('/integration/test');
        
        // Cache the data
        final recentFolders = await localStorageService.getRecentFolders();
        await cacheService.cacheData(
          'cached_recent_folders',
          recentFolders.map((f) => f.toMap()).toList(),
        );
        
        // Retrieve from cache
        final cachedData = await cacheService.getCachedData<List<dynamic>>('cached_recent_folders');
        
        expect(cachedData, isNotNull);
        expect(cachedData!.length, equals(1));
        expect(cachedData.first['path'], equals('/integration/test'));
      });

      test('should integrate background sync with cache and storage', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        // Add data to local storage
        await localStorageService.addRecentFolder('/sync/integration');
        await localStorageService.addBookmarkedFolder('/bookmark/sync', 'Sync Test');
        
        // Perform sync (should cache the data)
        final result = await backgroundSyncService.performSync();
        
        expect(result.success, isTrue);
        
        // Verify data is cached
        final cachedFolders = await cacheService.getCachedData<List<dynamic>>('recent_folders');
        final cachedBookmarks = await cacheService.getCachedData<List<dynamic>>('bookmarked_folders');
        
        expect(cachedFolders, isNotNull);
        expect(cachedBookmarks, isNotNull);
        expect(cachedFolders!.length, equals(1));
        expect(cachedBookmarks!.length, equals(1));
      });

      test('should handle data consistency across services', () async {
        await backgroundSyncService.initialize(enableAutoSync: false);
        
        // Add data through local storage
        const testPath = '/consistency/test';
        await localStorageService.addRecentFolder(testPath);
        
        // Sync to cache
        await backgroundSyncService.syncCategory('recent_folders');
        
        // Modify local storage
        await localStorageService.addRecentFolder('/another/path');
        
        // Sync again
        await backgroundSyncService.syncCategory('recent_folders');
        
        // Verify cache is updated
        final cachedData = await cacheService.getCachedData<List<dynamic>>('recent_folders');
        expect(cachedData, isNotNull);
        expect(cachedData!.length, equals(2));
      });

      test('should handle error scenarios gracefully', () async {
        // Test cache service with invalid data
        await cacheService.cacheData('test_key', 'test_data');
        await cacheService.removeCachedData('test_key');
        
        final retrievedData = await cacheService.getCachedData<String>('test_key');
        expect(retrievedData, isNull);
        
        // Test local storage with invalid operations
        await localStorageService.removeBookmarkedFolder('/nonexistent/path');
        await localStorageService.removeOrganizationPreset('nonexistent_preset');
        
        // Should not throw errors
        final bookmarks = await localStorageService.getBookmarkedFolders();
        final presets = await localStorageService.getOrganizationPresets();
        
        expect(bookmarks, isEmpty);
        expect(presets, isEmpty);
      });

      test('should maintain performance under load', () async {
        final stopwatch = Stopwatch()..start();
        
        // Add many items to test performance
        for (int i = 0; i < 100; i++) {
          await cacheService.cacheData('perf_key_$i', 'data_$i');
          await localStorageService.addRecentFolder('/perf/path/$i');
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds
        
        // Verify data integrity
        final stats = cacheService.getStatistics();
        final recentFolders = await localStorageService.getRecentFolders();
        
        expect(stats.memoryEntries, greaterThan(0));
        expect(recentFolders.length, equals(20)); // Limited by maxRecentFolders
      });
    });
  });
}
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homie_app/services/cache_service.dart';
import 'package:homie_app/services/local_storage_service.dart';
import 'package:homie_app/services/background_sync_service.dart';
import 'package:homie_app/utils/efficient_data_structures.dart';

void main() {
  group('Cache and Data Management Tests', () {
    group('CacheService Tests', () {
      late CacheService cacheService;

      setUp(() async {
        cacheService = CacheService();
        await cacheService.initialize();
      });

      tearDown(() async {
        await cacheService.clearAllCache();
      });

      test('should cache and retrieve data correctly', () async {
        const testKey = 'test_key';
        const testData = {'message': 'Hello, World!'};

        await cacheService.cacheData(testKey, testData);
        final retrievedData = await cacheService.getCachedData<Map<String, dynamic>>(testKey);

        expect(retrievedData, equals(testData));
      });

      test('should respect TTL and expire data', () async {
        const testKey = 'expiring_key';
        const testData = 'This will expire';

        await cacheService.cacheData(
          testKey, 
          testData, 
          ttl: const Duration(milliseconds: 100),
        );

        // Should be available immediately
        final immediateData = await cacheService.getCachedData<String>(testKey);
        expect(immediateData, equals(testData));

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));

        // Should be null after expiration
        final expiredData = await cacheService.getCachedData<String>(testKey);
        expect(expiredData, isNull);
      });

      test('should handle different cache levels', () async {
        const memoryKey = 'memory_key';
        const diskKey = 'disk_key';
        const testData = 'Test data';

        // Cache in memory
        await cacheService.cacheData(
          memoryKey, 
          testData, 
          level: CacheLevel.memory,
        );

        // Cache on disk
        await cacheService.cacheData(
          diskKey, 
          testData, 
          level: CacheLevel.disk,
        );

        // Both should be retrievable
        final memoryData = await cacheService.getCachedData<String>(memoryKey);
        final diskData = await cacheService.getCachedData<String>(diskKey);

        expect(memoryData, equals(testData));
        expect(diskData, equals(testData));
      });

      test('should provide accurate cache statistics', () async {
        // Cache some data
        for (int i = 0; i < 5; i++) {
          await cacheService.cacheData('key_$i', 'data_$i');
        }

        // Access some data to generate hits
        for (int i = 0; i < 3; i++) {
          await cacheService.getCachedData('key_$i');
        }

        // Try to access non-existent data to generate misses
        await cacheService.getCachedData('non_existent_key');

        final stats = cacheService.getStatistics();
        expect(stats.hitCount, equals(3));
        expect(stats.missCount, equals(1));
        expect(stats.hitRate, equals(0.75)); // 3/4
      });

      test('should clear cache by category', () async {
        await cacheService.cacheData('api_data', 'API response', category: 'api');
        await cacheService.cacheData('user_pref', 'User preference', category: 'preferences');
        await cacheService.cacheData('file_list', 'File listing', category: 'files');

        // Clear only API category
        await cacheService.clearCacheByCategory('api');

        // API data should be gone
        final apiData = await cacheService.getCachedData('api_data');
        expect(apiData, isNull);

        // Other data should remain
        final userPref = await cacheService.getCachedData('user_pref');
        final fileList = await cacheService.getCachedData('file_list');
        expect(userPref, equals('User preference'));
        expect(fileList, equals('File listing'));
      });

      test('should optimize cache performance', () async {
        // Fill cache with data
        for (int i = 0; i < 100; i++) {
          await cacheService.cacheData(
            'key_$i', 
            'data_$i',
            ttl: const Duration(milliseconds: 50), // Short TTL
          );
        }

        // Wait for some to expire
        await Future.delayed(const Duration(milliseconds: 100));

        // Optimize cache
        await cacheService.optimizeCache();

        final stats = cacheService.getStatistics();
        // Should have fewer entries after optimization
        expect(stats.memoryEntries, lessThan(100));
      });
    });

    group('LocalStorageService Tests', () {
      late LocalStorageService localStorage;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        localStorage = LocalStorageService();
        await localStorage.initialize();
      });

      test('should save and retrieve user preferences', () async {
        final preferences = UserPreferences.defaultPreferences().copyWith(
          theme: 'dark',
          enableNotifications: false,
        );

        await localStorage.saveUserPreferences(preferences);
        final retrievedPrefs = await localStorage.getUserPreferences();

        expect(retrievedPrefs.theme, equals('dark'));
        expect(retrievedPrefs.enableNotifications, equals(false));
      });

      test('should manage recent folders correctly', () async {
        const folder1 = '/home/user/documents';
        const folder2 = '/home/user/downloads';
        const folder3 = '/home/user/pictures';

        // Add folders
        await localStorage.addRecentFolder(folder1);
        await localStorage.addRecentFolder(folder2);
        await localStorage.addRecentFolder(folder3);

        final recentFolders = await localStorage.getRecentFolders();
        
        expect(recentFolders.length, equals(3));
        expect(recentFolders[0].path, equals(folder3)); // Most recent first
        expect(recentFolders[1].path, equals(folder2));
        expect(recentFolders[2].path, equals(folder1));
      });

      test('should prevent duplicate recent folders', () async {
        const folder = '/home/user/documents';

        // Add same folder multiple times
        await localStorage.addRecentFolder(folder);
        await localStorage.addRecentFolder(folder);
        await localStorage.addRecentFolder(folder);

        final recentFolders = await localStorage.getRecentFolders();
        
        expect(recentFolders.length, equals(1));
        expect(recentFolders[0].path, equals(folder));
      });

      test('should manage bookmarked folders', () async {
        const folder1 = '/home/user/projects';
        const folder2 = '/home/user/work';

        await localStorage.addBookmarkedFolder(folder1, 'Projects');
        await localStorage.addBookmarkedFolder(folder2, 'Work Files');

        final bookmarks = await localStorage.getBookmarkedFolders();
        
        expect(bookmarks.length, equals(2));
        expect(bookmarks.any((b) => b.path == folder1 && b.name == 'Projects'), isTrue);
        expect(bookmarks.any((b) => b.path == folder2 && b.name == 'Work Files'), isTrue);

        // Remove bookmark
        await localStorage.removeBookmarkedFolder(folder1);
        final updatedBookmarks = await localStorage.getBookmarkedFolders();
        
        expect(updatedBookmarks.length, equals(1));
        expect(updatedBookmarks[0].path, equals(folder2));
      });

      test('should save and retrieve organization presets', () async {
        final preset = OrganizationPreset(
          name: 'Photo Organization',
          description: 'Organize photos by date and event',
          organizationStyle: 'date_based',
          settings: {'groupByDate': true, 'createEventFolders': true},
          createdAt: DateTime.now(),
          usageCount: 0,
        );

        await localStorage.saveOrganizationPreset(preset);
        final presets = await localStorage.getOrganizationPresets();
        
        expect(presets.length, equals(1));
        expect(presets[0].name, equals('Photo Organization'));
        expect(presets[0].organizationStyle, equals('date_based'));
      });

      test('should export and import data', () async {
        // Set up some data
        final preferences = UserPreferences.defaultPreferences().copyWith(theme: 'dark');
        await localStorage.saveUserPreferences(preferences);
        await localStorage.addRecentFolder('/test/folder');
        await localStorage.addBookmarkedFolder('/test/bookmark', 'Test Bookmark');

        // Export data
        final exportedData = await localStorage.exportData();
        expect(exportedData, isNotEmpty);
        expect(exportedData['version'], equals('1.0.0'));
        expect(exportedData['data'], isA<Map<String, dynamic>>());

        // Clear all data
        await localStorage.clearAllData();

        // Verify data is cleared
        final clearedPrefs = await localStorage.getUserPreferences();
        expect(clearedPrefs.theme, equals('system')); // Default value

        // Import data
        await localStorage.importData(exportedData);

        // Verify data is restored
        final restoredPrefs = await localStorage.getUserPreferences();
        expect(restoredPrefs.theme, equals('dark'));
      });

      test('should provide storage statistics', () async {
        // Add some data
        await localStorage.saveUserPreferences(UserPreferences.defaultPreferences());
        await localStorage.addRecentFolder('/test/folder');

        final stats = await localStorage.getStorageStatistics();
        
        expect(stats.totalKeys, greaterThan(0));
        expect(stats.totalSize, greaterThan(0));
        expect(stats.categorySizes, isNotEmpty);
      });
    });

    group('BackgroundSyncService Tests', () {
      late BackgroundSyncService syncService;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        syncService = BackgroundSyncService();
        await syncService.initialize(enableAutoSync: false);
      });

      tearDown(() {
        syncService.dispose();
      });

      test('should perform manual sync', () async {
        final result = await syncService.performSync();
        
        expect(result.success, isTrue);
        expect(result.syncedItems, greaterThanOrEqualTo(0));
        expect(result.message, contains('successfully'));
      });

      test('should sync specific categories', () async {
        final result = await syncService.syncCategory('user_preferences');
        
        expect(result.success, isTrue);
        expect(result.syncedItems, equals(1));
      });

      test('should provide sync statistics', () async {
        // Perform a sync to generate statistics
        await syncService.performSync();

        final stats = syncService.getStatistics();
        
        expect(stats.successfulSyncs, greaterThan(0));
        expect(stats.successRate, greaterThan(0.0));
        expect(stats.lastSyncTime, isNotNull);
      });

      test('should handle sync events', () async {
        final events = <SyncEvent>[];
        final subscription = syncService.syncEventStream.listen(events.add);

        await syncService.performSync();

        await Future.delayed(const Duration(milliseconds: 100));
        subscription.cancel();

        expect(events, isNotEmpty);
        expect(events.any((e) => e.type == SyncEventType.started), isTrue);
        expect(events.any((e) => e.type == SyncEventType.completed), isTrue);
      });

      test('should optimize storage', () async {
        // This test verifies that storage optimization doesn't throw errors
        expect(() => syncService.optimizeStorage(), returnsNormally);
      });
    });

    group('EfficientDataStructures Tests', () {
      group('Trie Tests', () {
        late Trie<String> trie;

        setUp(() {
          trie = Trie<String>();
        });

        test('should insert and search correctly', () {
          trie.insert('hello', 'world');
          trie.insert('help', 'assistance');
          trie.insert('hero', 'champion');

          expect(trie.search('hello'), equals('world'));
          expect(trie.search('help'), equals('assistance'));
          expect(trie.search('hero'), equals('champion'));
          expect(trie.search('nonexistent'), isNull);
        });

        test('should provide autocomplete suggestions', () {
          trie.insert('/home/user/documents', 'Documents');
          trie.insert('/home/user/downloads', 'Downloads');
          trie.insert('/home/user/desktop', 'Desktop');
          trie.insert('/var/log', 'Logs');

          final suggestions = trie.getAutocompleteSuggestions('/home/user/d');
          
          expect(suggestions.length, equals(2));
          expect(suggestions, contains('/home/user/documents'));
          expect(suggestions, contains('/home/user/downloads'));
        });

        test('should handle removal correctly', () {
          trie.insert('test', 'value');
          expect(trie.contains('test'), isTrue);
          
          final removed = trie.remove('test');
          expect(removed, isTrue);
          expect(trie.contains('test'), isFalse);
          
          final removedAgain = trie.remove('test');
          expect(removedAgain, isFalse);
        });
      });

      group('LRUCache Tests', () {
        late LRUCache<String, String> cache;

        setUp(() {
          cache = LRUCache<String, String>(3);
        });

        test('should evict least recently used items', () {
          cache.put('a', 'value_a');
          cache.put('b', 'value_b');
          cache.put('c', 'value_c');
          
          // All should be present
          expect(cache.get('a'), equals('value_a'));
          expect(cache.get('b'), equals('value_b'));
          expect(cache.get('c'), equals('value_c'));
          
          // Add one more, should evict 'a' (least recently used)
          cache.put('d', 'value_d');
          
          expect(cache.get('a'), isNull);
          expect(cache.get('b'), equals('value_b'));
          expect(cache.get('c'), equals('value_c'));
          expect(cache.get('d'), equals('value_d'));
        });

        test('should update access order on get', () {
          cache.put('a', 'value_a');
          cache.put('b', 'value_b');
          cache.put('c', 'value_c');
          
          // Access 'a' to make it most recent
          cache.get('a');
          
          // Add new item, should evict 'b' (now least recent)
          cache.put('d', 'value_d');
          
          expect(cache.get('a'), equals('value_a'));
          expect(cache.get('b'), isNull);
          expect(cache.get('c'), equals('value_c'));
          expect(cache.get('d'), equals('value_d'));
        });

        test('should provide accurate statistics', () {
          cache.put('a', 'value_a');
          cache.put('b', 'value_b');
          
          // Generate hits and misses
          cache.get('a'); // hit
          cache.get('b'); // hit
          cache.get('c'); // miss
          
          final stats = cache.getStatistics();
          expect(stats['hitCount'], equals(2));
          expect(stats['missCount'], equals(1));
          expect(stats['hitRate'], equals(2/3));
        });
      });

      group('BloomFilter Tests', () {
        late BloomFilter filter;

        setUp(() {
          filter = BloomFilter(1000);
        });

        test('should not have false negatives', () {
          const items = ['apple', 'banana', 'cherry', 'date'];
          
          // Add items to filter
          for (final item in items) {
            filter.add(item);
          }
          
          // All added items should be detected
          for (final item in items) {
            expect(filter.mightContain(item), isTrue);
          }
        });

        test('should have low false positive rate', () {
          const addedItems = ['item1', 'item2', 'item3', 'item4', 'item5'];
          const testItems = ['test1', 'test2', 'test3', 'test4', 'test5'];
          
          // Add known items
          for (final item in addedItems) {
            filter.add(item);
          }
          
          // Test items that weren't added
          int falsePositives = 0;
          for (final item in testItems) {
            if (filter.mightContain(item)) {
              falsePositives++;
            }
          }
          
          // Should have low false positive rate
          final falsePositiveRate = falsePositives / testItems.length;
          expect(falsePositiveRate, lessThan(0.1)); // Less than 10%
        });

        test('should provide filter statistics', () {
          filter.add('test1');
          filter.add('test2');
          
          final stats = filter.getStatistics();
          expect(stats['itemCount'], equals(2));
          expect(stats['size'], greaterThan(0));
          expect(stats['hashFunctions'], greaterThan(0));
        });
      });

      group('PriorityQueue Tests', () {
        late PriorityQueue<int> queue;

        setUp(() {
          queue = PriorityQueue<int>((a, b) => a.compareTo(b));
        });

        test('should maintain priority order', () {
          queue.add(5);
          queue.add(2);
          queue.add(8);
          queue.add(1);
          queue.add(9);
          
          final results = <int>[];
          while (!queue.isEmpty) {
            results.add(queue.removeFirst()!);
          }
          
          expect(results, equals([1, 2, 5, 8, 9]));
        });

        test('should handle custom comparator', () {
          // Max heap (reverse order)
          final maxQueue = PriorityQueue<int>((a, b) => b.compareTo(a));
          
          maxQueue.add(5);
          maxQueue.add(2);
          maxQueue.add(8);
          maxQueue.add(1);
          
          expect(maxQueue.removeFirst(), equals(8));
          expect(maxQueue.removeFirst(), equals(5));
          expect(maxQueue.removeFirst(), equals(2));
          expect(maxQueue.removeFirst(), equals(1));
        });
      });

      group('StringMatcher Tests', () {
        test('should perform fuzzy matching', () {
          expect(StringMatcher.fuzzyMatch('doc', 'documents'), isTrue);
          expect(StringMatcher.fuzzyMatch('usr', 'user'), isTrue);
          expect(StringMatcher.fuzzyMatch('xyz', 'documents'), isFalse);
        });

        test('should calculate similarity correctly', () {
          expect(StringMatcher.similarity('hello', 'hello'), equals(1.0));
          expect(StringMatcher.similarity('hello', 'hallo'), greaterThan(0.8));
          expect(StringMatcher.similarity('hello', 'world'), lessThan(0.5));
        });

        test('should handle regex matching', () {
          expect(StringMatcher.regexMatch(r'\d+', 'file123.txt'), isTrue);
          expect(StringMatcher.regexMatch(r'\.jpg$', 'image.jpg'), isTrue);
          expect(StringMatcher.regexMatch(r'\.jpg$', 'image.png'), isFalse);
        });
      });
    });

    group('Integration Tests', () {
      test('should integrate cache and local storage', () async {
        SharedPreferences.setMockInitialValues({});
        
        final cacheService = CacheService();
        final localStorage = LocalStorageService();
        
        await cacheService.initialize();
        await localStorage.initialize();
        
        // Save preferences to local storage
        final preferences = UserPreferences.defaultPreferences().copyWith(theme: 'dark');
        await localStorage.saveUserPreferences(preferences);
        
        // Cache the preferences
        await cacheService.cacheData('user_prefs', preferences.toMap());
        
        // Retrieve from cache
        final cachedPrefs = await cacheService.getCachedData<Map<String, dynamic>>('user_prefs');
        expect(cachedPrefs?['theme'], equals('dark'));
        
        // Clean up
        await cacheService.clearAllCache();
      });

      test('should handle concurrent operations', () async {
        final cache = LRUCache<String, String>(10);
        
        // Perform concurrent operations
        final futures = <Future<void>>[];
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() {
            cache.put('key_$i', 'value_$i');
            cache.get('key_${i ~/ 2}');
          }));
        }
        
        await Future.wait(futures);
        
        // Should not crash and should have some data
        expect(cache.size, greaterThan(0));
        expect(cache.size, lessThanOrEqualTo(10));
      });
    });
  });
}
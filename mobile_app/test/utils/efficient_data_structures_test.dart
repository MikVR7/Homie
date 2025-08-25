import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/utils/efficient_data_structures.dart';

void main() {
  group('Efficient Data Structures Tests', () {
    group('Trie Tests', () {
      late Trie<String> trie;

      setUp(() {
        trie = EfficientDataStructures.createPathTrie();
      });

      test('should insert and search values', () {
        trie.insert('hello', 'world');
        trie.insert('help', 'assistance');
        trie.insert('hero', 'champion');

        expect(trie.search('hello'), equals('world'));
        expect(trie.search('help'), equals('assistance'));
        expect(trie.search('hero'), equals('champion'));
        expect(trie.search('nonexistent'), isNull);
      });

      test('should check if keys exist', () {
        trie.insert('test', 'value');

        expect(trie.contains('test'), isTrue);
        expect(trie.contains('nonexistent'), isFalse);
      });

      test('should provide autocomplete suggestions', () {
        trie.insert('apple', 'fruit1');
        trie.insert('application', 'software');
        trie.insert('apply', 'action');
        trie.insert('banana', 'fruit2');

        final suggestions = trie.getAutocompleteSuggestions('app');
        
        expect(suggestions.length, equals(3));
        expect(suggestions.contains('apple'), isTrue);
        expect(suggestions.contains('application'), isTrue);
        expect(suggestions.contains('apply'), isTrue);
        expect(suggestions.contains('banana'), isFalse);
      });

      test('should limit autocomplete suggestions', () {
        for (int i = 0; i < 20; i++) {
          trie.insert('test$i', 'value$i');
        }

        final suggestions = trie.getAutocompleteSuggestions('test', limit: 5);
        expect(suggestions.length, equals(5));
      });

      test('should remove keys', () {
        trie.insert('remove_me', 'value');
        trie.insert('keep_me', 'value');

        expect(trie.contains('remove_me'), isTrue);
        expect(trie.remove('remove_me'), isTrue);
        expect(trie.contains('remove_me'), isFalse);
        expect(trie.contains('keep_me'), isTrue);

        // Try to remove non-existent key
        expect(trie.remove('nonexistent'), isFalse);
      });

      test('should get all keys', () {
        trie.insert('key1', 'value1');
        trie.insert('key2', 'value2');
        trie.insert('key3', 'value3');

        final allKeys = trie.getAllKeys();
        expect(allKeys.length, equals(3));
        expect(allKeys.contains('key1'), isTrue);
        expect(allKeys.contains('key2'), isTrue);
        expect(allKeys.contains('key3'), isTrue);
      });

      test('should track size correctly', () {
        expect(trie.size, equals(0));
        expect(trie.isEmpty, isTrue);

        trie.insert('key1', 'value1');
        expect(trie.size, equals(1));
        expect(trie.isEmpty, isFalse);

        trie.insert('key2', 'value2');
        expect(trie.size, equals(2));

        trie.remove('key1');
        expect(trie.size, equals(1));

        trie.clear();
        expect(trie.size, equals(0));
        expect(trie.isEmpty, isTrue);
      });

      test('should provide statistics', () {
        trie.insert('a', 'value1');
        trie.insert('ab', 'value2');
        trie.insert('abc', 'value3');

        final stats = trie.getStatistics();
        expect(stats['size'], equals(3));
        expect(stats['totalNodes'], greaterThan(3));
        expect(stats['maxDepth'], greaterThan(0));
      });
    });

    group('LRU Cache Tests', () {
      late LRUCache<String, String> cache;

      setUp(() {
        cache = EfficientDataStructures.createLRUCache<String, String>(3);
      });

      test('should store and retrieve values', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');

        expect(cache.get('key1'), equals('value1'));
        expect(cache.get('key2'), equals('value2'));
        expect(cache.get('nonexistent'), isNull);
      });

      test('should evict least recently used items', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');
        cache.put('key3', 'value3');

        // All should be present
        expect(cache.get('key1'), equals('value1'));
        expect(cache.get('key2'), equals('value2'));
        expect(cache.get('key3'), equals('value3'));

        // Add fourth item, should evict key1 (least recently used)
        cache.put('key4', 'value4');

        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), equals('value2'));
        expect(cache.get('key3'), equals('value3'));
        expect(cache.get('key4'), equals('value4'));
      });

      test('should update access order on get', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');
        cache.put('key3', 'value3');

        // Access key1 to make it most recently used
        cache.get('key1');

        // Add fourth item, should evict key2 (now least recently used)
        cache.put('key4', 'value4');

        expect(cache.get('key1'), equals('value1'));
        expect(cache.get('key2'), isNull);
        expect(cache.get('key3'), equals('value3'));
        expect(cache.get('key4'), equals('value4'));
      });

      test('should update existing keys without eviction', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');
        cache.put('key3', 'value3');

        // Update existing key
        cache.put('key2', 'updated_value2');

        expect(cache.size, equals(3));
        expect(cache.get('key2'), equals('updated_value2'));
      });

      test('should remove keys', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');

        expect(cache.remove('key1'), equals('value1'));
        expect(cache.get('key1'), isNull);
        expect(cache.size, equals(1));

        expect(cache.remove('nonexistent'), isNull);
      });

      test('should check key existence', () {
        cache.put('key1', 'value1');

        expect(cache.containsKey('key1'), isTrue);
        expect(cache.containsKey('nonexistent'), isFalse);
      });

      test('should provide keys and values', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');

        final keys = cache.keys.toList();
        final values = cache.values.toList();

        expect(keys.length, equals(2));
        expect(values.length, equals(2));
        expect(keys.contains('key1'), isTrue);
        expect(keys.contains('key2'), isTrue);
        expect(values.contains('value1'), isTrue);
        expect(values.contains('value2'), isTrue);
      });

      test('should track hit rate', () {
        cache.put('key1', 'value1');

        // Hit
        cache.get('key1');
        // Miss
        cache.get('nonexistent');

        expect(cache.hitRate, equals(0.5));
      });

      test('should clear cache', () {
        cache.put('key1', 'value1');
        cache.put('key2', 'value2');

        cache.clear();

        expect(cache.size, equals(0));
        expect(cache.hitRate, equals(0.0));
        expect(cache.get('key1'), isNull);
      });

      test('should provide statistics', () {
        cache.put('key1', 'value1');
        cache.get('key1');
        cache.get('nonexistent');

        final stats = cache.getStatistics();

        expect(stats['size'], equals(1));
        expect(stats['capacity'], equals(3));
        expect(stats['hitCount'], equals(1));
        expect(stats['missCount'], equals(1));
        expect(stats['hitRate'], equals(0.5));
        expect(stats['utilizationRate'], closeTo(0.33, 0.01));
      });
    });

    group('Bloom Filter Tests', () {
      late BloomFilter bloomFilter;

      setUp(() {
        bloomFilter = EfficientDataStructures.createBloomFilter(100);
      });

      test('should add items and check membership', () {
        bloomFilter.add('item1');
        bloomFilter.add('item2');
        bloomFilter.add('item3');

        expect(bloomFilter.mightContain('item1'), isTrue);
        expect(bloomFilter.mightContain('item2'), isTrue);
        expect(bloomFilter.mightContain('item3'), isTrue);
      });

      test('should return false for items not added', () {
        bloomFilter.add('item1');

        // These should definitely return false
        expect(bloomFilter.mightContain('definitely_not_added'), isFalse);
        expect(bloomFilter.mightContain('another_item'), isFalse);
      });

      test('should handle false positives but no false negatives', () {
        final testItems = <String>[];
        final notAddedItems = <String>[];

        // Add some items
        for (int i = 0; i < 50; i++) {
          final item = 'item_$i';
          testItems.add(item);
          bloomFilter.add(item);
        }

        // Create items that were not added
        for (int i = 50; i < 100; i++) {
          notAddedItems.add('item_$i');
        }

        // All added items should return true (no false negatives)
        for (final item in testItems) {
          expect(bloomFilter.mightContain(item), isTrue);
        }

        // Count false positives among not-added items
        int falsePositives = 0;
        for (final item in notAddedItems) {
          if (bloomFilter.mightContain(item)) {
            falsePositives++;
          }
        }

        // False positive rate should be reasonable (less than 50%)
        final falsePositiveRate = falsePositives / notAddedItems.length;
        expect(falsePositiveRate, lessThan(0.5));
      });

      test('should provide statistics', () {
        bloomFilter.add('item1');
        bloomFilter.add('item2');
        bloomFilter.add('item3');

        final stats = bloomFilter.getStatistics();

        expect(stats['size'], greaterThan(0));
        expect(stats['hashFunctions'], greaterThan(0));
        expect(stats['itemCount'], equals(3));
        expect(stats['setBits'], greaterThan(0));
        expect(stats['fillRatio'], greaterThan(0));
        expect(stats['fillRatio'], lessThan(1));
      });

      test('should clear filter', () {
        bloomFilter.add('item1');
        bloomFilter.add('item2');

        expect(bloomFilter.mightContain('item1'), isTrue);

        bloomFilter.clear();

        // After clearing, should not contain any items
        expect(bloomFilter.mightContain('item1'), isFalse);
        expect(bloomFilter.mightContain('item2'), isFalse);

        final stats = bloomFilter.getStatistics();
        expect(stats['itemCount'], equals(0));
        expect(stats['setBits'], equals(0));
      });
    });

    group('Priority Queue Tests', () {
      late PriorityQueue<int> priorityQueue;

      setUp(() {
        priorityQueue = EfficientDataStructures.createPriorityQueue<int>((a, b) => a.compareTo(b));
      });

      test('should maintain priority order', () {
        priorityQueue.add(5);
        priorityQueue.add(1);
        priorityQueue.add(3);
        priorityQueue.add(2);
        priorityQueue.add(4);

        expect(priorityQueue.removeFirst(), equals(1));
        expect(priorityQueue.removeFirst(), equals(2));
        expect(priorityQueue.removeFirst(), equals(3));
        expect(priorityQueue.removeFirst(), equals(4));
        expect(priorityQueue.removeFirst(), equals(5));
      });

      test('should handle custom comparators', () {
        // Max heap (reverse order)
        final maxHeap = EfficientDataStructures.createPriorityQueue<int>((a, b) => b.compareTo(a));

        maxHeap.add(1);
        maxHeap.add(5);
        maxHeap.add(3);

        expect(maxHeap.removeFirst(), equals(5));
        expect(maxHeap.removeFirst(), equals(3));
        expect(maxHeap.removeFirst(), equals(1));
      });

      test('should peek at first element', () {
        priorityQueue.add(5);
        priorityQueue.add(1);
        priorityQueue.add(3);

        expect(priorityQueue.first, equals(1));
        expect(priorityQueue.length, equals(3)); // Should not remove

        priorityQueue.removeFirst();
        expect(priorityQueue.first, equals(3));
      });

      test('should handle empty queue', () {
        expect(priorityQueue.isEmpty, isTrue);
        expect(priorityQueue.first, isNull);
        expect(priorityQueue.removeFirst(), isNull);
      });

      test('should clear queue', () {
        priorityQueue.add(1);
        priorityQueue.add(2);
        priorityQueue.add(3);

        expect(priorityQueue.length, equals(3));

        priorityQueue.clear();

        expect(priorityQueue.isEmpty, isTrue);
        expect(priorityQueue.length, equals(0));
      });

      test('should convert to sorted list', () {
        priorityQueue.add(5);
        priorityQueue.add(1);
        priorityQueue.add(3);
        priorityQueue.add(2);

        final sortedList = priorityQueue.toList();

        expect(sortedList, equals([1, 2, 3, 5]));
        expect(priorityQueue.length, equals(4)); // Original should be unchanged
      });
    });

    group('String Matcher Tests', () {
      test('should perform fuzzy matching', () {
        expect(StringMatcher.fuzzyMatch('abc', 'aabbcc'), isTrue);
        expect(StringMatcher.fuzzyMatch('abc', 'axbxcx'), isTrue);
        expect(StringMatcher.fuzzyMatch('abc', 'abcdef'), isTrue);
        expect(StringMatcher.fuzzyMatch('abc', 'def'), isFalse);
        expect(StringMatcher.fuzzyMatch('abc', 'acb'), isFalse); // Order matters
        expect(StringMatcher.fuzzyMatch('', 'anything'), isTrue); // Empty pattern matches anything
        expect(StringMatcher.fuzzyMatch('abc', ''), isFalse); // Non-empty pattern doesn't match empty text
      });

      test('should calculate string similarity', () {
        expect(StringMatcher.similarity('hello', 'hello'), equals(1.0));
        expect(StringMatcher.similarity('hello', 'hallo'), greaterThan(0.5));
        expect(StringMatcher.similarity('hello', 'world'), lessThan(0.5));
        expect(StringMatcher.similarity('', ''), equals(1.0));
        expect(StringMatcher.similarity('hello', ''), equals(0.0));
        expect(StringMatcher.similarity('', 'hello'), equals(0.0));
      });

      test('should perform regex matching', () {
        expect(StringMatcher.regexMatch(r'\d+', 'test123'), isTrue);
        expect(StringMatcher.regexMatch(r'\d+', 'testABC'), isFalse);
        expect(StringMatcher.regexMatch(r'[a-z]+', 'hello'), isTrue);
        expect(StringMatcher.regexMatch(r'[a-z]+', 'HELLO'), isFalse);
        expect(StringMatcher.regexMatch(r'invalid[', 'test'), isFalse); // Invalid regex
      });

      test('should find regex matches', () {
        final matches = StringMatcher.findMatches(r'\d+', 'test123and456');
        expect(matches.length, equals(2));
        expect(matches.contains('123'), isTrue);
        expect(matches.contains('456'), isTrue);

        final noMatches = StringMatcher.findMatches(r'\d+', 'noNumbers');
        expect(noMatches.isEmpty, isTrue);

        final invalidMatches = StringMatcher.findMatches(r'invalid[', 'test');
        expect(invalidMatches.isEmpty, isTrue);
      });

      test('should perform case-insensitive contains', () {
        expect(StringMatcher.containsIgnoreCase('Hello World', 'WORLD'), isTrue);
        expect(StringMatcher.containsIgnoreCase('Hello World', 'hello'), isTrue);
        expect(StringMatcher.containsIgnoreCase('Hello World', 'xyz'), isFalse);
        expect(StringMatcher.containsIgnoreCase('', 'test'), isFalse);
        expect(StringMatcher.containsIgnoreCase('test', ''), isTrue);
      });

      test('should perform word boundary matching', () {
        expect(StringMatcher.wordMatch('hello', 'hello world'), isTrue);
        expect(StringMatcher.wordMatch('hello', 'say hello there'), isTrue);
        expect(StringMatcher.wordMatch('hello', 'hellothere'), isFalse);
        expect(StringMatcher.wordMatch('world', 'hello world!'), isTrue);
        expect(StringMatcher.wordMatch('or', 'hello world'), isFalse); // Should not match partial words
      });
    });

    group('Integration Tests', () {
      test('should use multiple data structures together', () {
        final trie = EfficientDataStructures.createPathTrie();
        final cache = EfficientDataStructures.createLRUCache<String, String>(10);
        final bloomFilter = EfficientDataStructures.createBloomFilter(100);

        // Add data to all structures
        final testData = ['apple', 'application', 'apply', 'banana', 'band'];

        for (final item in testData) {
          trie.insert(item, 'value_$item');
          cache.put(item, 'cached_$item');
          bloomFilter.add(item);
        }

        // Test trie autocomplete
        final suggestions = trie.getAutocompleteSuggestions('app');
        expect(suggestions.length, equals(3));

        // Test cache retrieval
        expect(cache.get('apple'), equals('cached_apple'));

        // Test bloom filter membership
        expect(bloomFilter.mightContain('apple'), isTrue);
        expect(bloomFilter.mightContain('nonexistent'), isFalse);

        // Test string matching for filtering
        final filteredItems = testData.where((item) => 
            StringMatcher.fuzzyMatch('ap', item)).toList();
        expect(filteredItems.length, equals(3)); // apple, application, apply
      });

      test('should handle large datasets efficiently', () {
        final stopwatch = Stopwatch()..start();

        final trie = EfficientDataStructures.createPathTrie();
        final cache = EfficientDataStructures.createLRUCache<String, int>(1000);
        final bloomFilter = EfficientDataStructures.createBloomFilter(10000);

        // Add 1000 items
        for (int i = 0; i < 1000; i++) {
          final key = 'item_$i';
          trie.insert(key, i);
          cache.put(key, i);
          bloomFilter.add(key);
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second

        // Verify data integrity
        expect(trie.size, equals(1000));
        expect(cache.size, equals(1000));

        // Test retrieval performance
        stopwatch.reset();
        stopwatch.start();

        for (int i = 0; i < 100; i++) {
          final key = 'item_$i';
          trie.search(key);
          cache.get(key);
          bloomFilter.mightContain(key);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms for 100 operations
      });

      test('should maintain data consistency', () {
        final trie = EfficientDataStructures.createPathTrie();
        final cache = EfficientDataStructures.createLRUCache<String, String>(5);

        // Add items
        trie.insert('key1', 'value1');
        trie.insert('key2', 'value2');
        cache.put('key1', 'cached1');
        cache.put('key2', 'cached2');

        // Verify consistency
        expect(trie.contains('key1'), isTrue);
        expect(cache.containsKey('key1'), isTrue);

        // Remove from trie
        trie.remove('key1');
        cache.remove('key1');

        // Verify removal
        expect(trie.contains('key1'), isFalse);
        expect(cache.containsKey('key1'), isFalse);
        expect(trie.contains('key2'), isTrue);
        expect(cache.containsKey('key2'), isTrue);
      });
    });
  });
}
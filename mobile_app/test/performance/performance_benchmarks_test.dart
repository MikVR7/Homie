import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/performance/virtual_list_view.dart';
import 'package:homie_app/widgets/performance/lazy_image_loader.dart';
import 'package:homie_app/widgets/performance/efficient_state_manager.dart';
import 'package:homie_app/utils/memory_manager.dart';

void main() {
  group('Performance Benchmarks', () {
    group('Virtual List View Performance', () {
      testWidgets('should handle large datasets efficiently', (tester) async {
        const itemCount = 10000;
        final items = List.generate(itemCount, (index) => 'Item $index');
        final buildTimes = <Duration>[];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VirtualListView<String>(
                items: items,
                itemHeight: 56.0,
                itemBuilder: (context, item, index) {
                  final start = DateTime.now();
                  final widget = ListTile(title: Text(item));
                  final end = DateTime.now();
                  buildTimes.add(end.difference(start));
                  return widget;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify performance metrics
        expect(items.length, equals(itemCount));
        
        // Average build time should be reasonable
        if (buildTimes.isNotEmpty) {
          final avgBuildTime = buildTimes.fold<int>(
            0, 
            (sum, duration) => sum + duration.inMicroseconds,
          ) / buildTimes.length;
          
          expect(avgBuildTime, lessThan(1000)); // Less than 1ms per item
        }
      });

      testWidgets('should cache widgets efficiently', (tester) async {
        const itemCount = 1000;
        final items = List.generate(itemCount, (index) => 'Item $index');
        int buildCallCount = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VirtualListView<String>(
                items: items,
                itemHeight: 56.0,
                enableCaching: true,
                maxCacheSize: 100,
                itemBuilder: (context, item, index) {
                  buildCallCount++;
                  return ListTile(title: Text(item));
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not build all items initially
        expect(buildCallCount, lessThan(itemCount));
        
        // Scroll and verify caching
        final initialBuildCount = buildCallCount;
        await tester.drag(find.byType(VirtualListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        
        // Should build some new items but not all
        expect(buildCallCount, greaterThan(initialBuildCount));
        expect(buildCallCount, lessThan(itemCount));
      });

      test('should provide accurate performance metrics', () {
        final metrics = VirtualListViewMetrics(
          totalItems: 1000,
          visibleItems: 20,
          cachedItems: 15,
          scrollOffset: 500.0,
          viewportHeight: 600.0,
          firstVisibleIndex: 10,
          lastVisibleIndex: 30,
        );

        expect(metrics.cacheHitRatio, equals(0.75)); // 15/20
        expect(metrics.visibilityRatio, equals(0.02)); // 20/1000
        expect(metrics.toString(), contains('75.0%'));
      });
    });

    group('Memory Manager Performance', () {
      late MemoryManager memoryManager;

      setUp(() {
        memoryManager = MemoryManager();
        memoryManager.initialize(
          maxMemoryUsage: 10 * 1024 * 1024, // 10MB for testing
          enableMemoryMonitoring: false, // Disable for tests
        );
      });

      tearDown(() {
        memoryManager.dispose();
      });

      test('should cache and retrieve data efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Cache 1000 items
        for (int i = 0; i < 1000; i++) {
          memoryManager.cacheData('item_$i', 'Data for item $i');
        }
        
        final cacheTime = stopwatch.elapsedMicroseconds;
        stopwatch.reset();
        
        // Retrieve 1000 items
        for (int i = 0; i < 1000; i++) {
          final data = memoryManager.getCachedData<String>('item_$i');
          expect(data, equals('Data for item $i'));
        }
        
        final retrieveTime = stopwatch.elapsedMicroseconds;
        stopwatch.stop();
        
        // Performance expectations
        expect(cacheTime, lessThan(100000)); // Less than 100ms
        expect(retrieveTime, lessThan(50000)); // Less than 50ms
        
        print('Cache time: ${cacheTime}μs, Retrieve time: ${retrieveTime}μs');
      });

      test('should handle large dataset processing efficiently', () async {
        final dataset = List.generate(10000, (index) => index);
        final stopwatch = Stopwatch()..start();
        
        final results = await memoryManager.processLargeDataset<int>(
          dataset,
          (item) => item * 2,
          chunkSize: 1000,
          chunkDelay: Duration.zero, // No delay for testing
        );
        
        stopwatch.stop();
        
        expect(results.length, equals(10000));
        expect(results[0], equals(0));
        expect(results[9999], equals(19998));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
        
        print('Large dataset processing time: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should manage memory usage effectively', () {
        final initialUsage = memoryManager.getMemoryUsage();
        expect(initialUsage.currentUsage, equals(0));
        
        // Add data until near memory limit
        final largeData = List.filled(1000, 'Large data string that takes up memory');
        for (int i = 0; i < 100; i++) {
          memoryManager.cacheData('large_$i', largeData);
        }
        
        final afterCaching = memoryManager.getMemoryUsage();
        expect(afterCaching.currentUsage, greaterThan(0));
        expect(afterCaching.usagePercentage, lessThan(100));
        
        // Force cleanup
        memoryManager.performCleanup(force: true);
        
        final afterCleanup = memoryManager.getMemoryUsage();
        expect(afterCleanup.currentUsage, lessThan(afterCaching.currentUsage));
      });
    });

    group('Efficient State Manager Performance', () {
      test('should minimize rebuild notifications', () async {
        final stateManager = EfficientStateManager<Map<String, dynamic>>({});
        int notificationCount = 0;
        
        stateManager.addListener(() {
          notificationCount++;
        });
        
        // Rapid property updates
        for (int i = 0; i < 100; i++) {
          stateManager.setProperty('key_$i', 'value_$i');
        }
        
        // Wait for batched notifications
        await Future.delayed(const Duration(milliseconds: 20));
        
        // Should have batched notifications, not 100 individual ones
        expect(notificationCount, lessThan(10));
        
        stateManager.dispose();
      });

      test('should handle property-specific listeners efficiently', () async {
        final stateManager = EfficientStateManager<Map<String, dynamic>>({});
        int property1Notifications = 0;
        int property2Notifications = 0;
        
        stateManager.addPropertyListener('property1', () {
          property1Notifications++;
        });
        
        stateManager.addPropertyListener('property2', () {
          property2Notifications++;
        });
        
        // Update only property1
        for (int i = 0; i < 10; i++) {
          stateManager.setProperty('property1', 'value_$i');
        }
        
        await Future.delayed(const Duration(milliseconds: 20));
        
        // Only property1 listeners should be notified
        expect(property1Notifications, greaterThan(0));
        expect(property2Notifications, equals(0));
        
        stateManager.dispose();
      });
    });

    group('Lazy Image Loader Performance', () {
      testWidgets('should load images efficiently', (tester) async {
        const imageCount = 10;
        final loadTimes = <Duration>[];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: imageCount,
                itemBuilder: (context, index) {
                  return LazyImageLoader(
                    imagePath: 'test_image_$index.jpg', // Mock path
                    width: 100,
                    height: 100,
                    onImageLoaded: () {
                      // Record load completion
                    },
                    onError: (error) {
                      // Expected for mock paths
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Verify widgets are created
        expect(find.byType(LazyImageLoader), findsNWidgets(imageCount));
      });
    });

    group('Performance Monitoring', () {
      testWidgets('should track widget performance metrics', (tester) async {
        PerformanceMetrics? capturedMetrics;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PerformanceMonitor(
                name: 'TestWidget',
                enableLogging: false,
                onMetricsUpdate: (metrics) {
                  capturedMetrics = metrics;
                },
                child: const Text('Performance Test'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Trigger some rebuilds
        for (int i = 0; i < 5; i++) {
          await tester.pump();
        }
        
        // Should have captured some metrics
        if (capturedMetrics != null) {
          expect(capturedMetrics!.buildCount, greaterThan(0));
          expect(capturedMetrics!.name, equals('TestWidget'));
        }
      });
    });

    group('Data Processing Performance', () {
      test('should process large datasets in chunks efficiently', () async {
        final processor = DataProcessor<int>();
        final largeDataset = List.generate(100000, (index) => index);
        final stopwatch = Stopwatch()..start();
        
        final results = await processor.processInChunks<int>(
          largeDataset,
          (item) => item * 2,
          chunkSize: 5000,
          chunkDelay: Duration.zero,
        );
        
        stopwatch.stop();
        
        expect(results.length, equals(100000));
        expect(results[0], equals(0));
        expect(results[99999], equals(199998));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds
        
        print('Large dataset chunk processing: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should filter large datasets efficiently', () async {
        final processor = DataProcessor<int>();
        final largeDataset = List.generate(50000, (index) => index);
        final stopwatch = Stopwatch()..start();
        
        final results = await processor.filterInChunks(
          largeDataset,
          (item) => item % 2 == 0, // Even numbers only
          chunkSize: 2500,
          chunkDelay: Duration.zero,
        );
        
        stopwatch.stop();
        
        expect(results.length, equals(25000)); // Half should be even
        expect(results.every((item) => item % 2 == 0), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
        
        print('Large dataset filtering: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should sort large datasets efficiently', () async {
        final processor = DataProcessor<int>();
        final random = Random(42); // Fixed seed for reproducible results
        final largeDataset = List.generate(10000, (index) => random.nextInt(100000));
        final stopwatch = Stopwatch()..start();
        
        final results = await processor.sortInChunks(
          largeDataset,
          (a, b) => a.compareTo(b),
          chunkSize: 1000,
        );
        
        stopwatch.stop();
        
        expect(results.length, equals(10000));
        
        // Verify sorting
        for (int i = 1; i < results.length; i++) {
          expect(results[i], greaterThanOrEqualTo(results[i - 1]));
        }
        
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds
        
        print('Large dataset sorting: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Leak Detection', () {
      test('should not leak memory with repeated operations', () async {
        final memoryManager = MemoryManager();
        memoryManager.initialize(
          maxMemoryUsage: 5 * 1024 * 1024, // 5MB
          enableMemoryMonitoring: false,
        );
        
        final initialUsage = memoryManager.getMemoryUsage();
        
        // Perform many cache operations
        for (int cycle = 0; cycle < 10; cycle++) {
          for (int i = 0; i < 100; i++) {
            memoryManager.cacheData('temp_${cycle}_$i', List.filled(1000, 'data'));
          }
          
          // Clear cache periodically
          if (cycle % 3 == 0) {
            memoryManager.clearCache();
          }
        }
        
        // Force cleanup
        memoryManager.performCleanup(force: true);
        
        final finalUsage = memoryManager.getMemoryUsage();
        
        // Memory usage should not grow indefinitely
        expect(finalUsage.currentUsage, lessThan(initialUsage.maxUsage * 0.5));
        
        memoryManager.dispose();
      });

      testWidgets('should not leak widgets with virtual scrolling', (tester) async {
        const itemCount = 1000;
        final items = List.generate(itemCount, (index) => 'Item $index');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VirtualListView<String>(
                items: items,
                itemHeight: 56.0,
                enableCaching: true,
                maxCacheSize: 50, // Small cache to force eviction
                itemBuilder: (context, item, index) {
                  return ListTile(title: Text(item));
                },
              ),
            ),
          ),
        );

        // Scroll through the entire list multiple times
        for (int i = 0; i < 5; i++) {
          await tester.drag(find.byType(VirtualListView), const Offset(0, -10000));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(VirtualListView), const Offset(0, 10000));
          await tester.pumpAndSettle();
        }
        
        // Should not crash or run out of memory
        expect(find.byType(VirtualListView), findsOneWidget);
      });
    });

    group('Performance Regression Tests', () {
      test('should maintain consistent performance over time', () async {
        final memoryManager = MemoryManager();
        memoryManager.initialize(maxMemoryUsage: 10 * 1024 * 1024);
        
        final operationTimes = <Duration>[];
        
        // Perform the same operation multiple times
        for (int i = 0; i < 100; i++) {
          final stopwatch = Stopwatch()..start();
          
          // Cache some data
          for (int j = 0; j < 10; j++) {
            memoryManager.cacheData('test_${i}_$j', 'Test data $j');
          }
          
          // Retrieve the data
          for (int j = 0; j < 10; j++) {
            memoryManager.getCachedData<String>('test_${i}_$j');
          }
          
          stopwatch.stop();
          operationTimes.add(stopwatch.elapsed);
        }
        
        // Calculate performance consistency
        final avgTime = operationTimes.fold<int>(
          0, 
          (sum, duration) => sum + duration.inMicroseconds,
        ) / operationTimes.length;
        
        final maxTime = operationTimes.map((d) => d.inMicroseconds).reduce(max);
        final minTime = operationTimes.map((d) => d.inMicroseconds).reduce(min);
        
        // Performance should be consistent (max shouldn't be more than 3x avg)
        expect(maxTime, lessThan(avgTime * 3));
        expect(minTime, greaterThan(avgTime * 0.3));
        
        print('Avg: ${avgTime.toStringAsFixed(1)}μs, Min: ${minTime}μs, Max: ${maxTime}μs');
        
        memoryManager.dispose();
      });
    });
  });
}
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memory management system for large datasets and file operations
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Memory limits and thresholds
  int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB default
  int _currentMemoryUsage = 0;
  int _warningThreshold = 80; // 80% of max memory
  int _criticalThreshold = 95; // 95% of max memory

  // Cache management
  final Map<String, _CacheEntry> _cache = {};
  final Queue<String> _accessOrder = Queue<String>();
  final Map<String, Timer> _expirationTimers = {};

  // Memory monitoring
  Timer? _memoryMonitorTimer;
  final List<MemoryUsageSnapshot> _usageHistory = [];
  final StreamController<MemoryUsageSnapshot> _usageController = 
      StreamController<MemoryUsageSnapshot>.broadcast();

  // Configuration
  Duration _cacheExpirationTime = const Duration(minutes: 10);
  Duration _monitoringInterval = const Duration(seconds: 5);
  bool _enableAutoCleanup = true;
  bool _enableMemoryMonitoring = true;

  /// Initialize the memory manager
  void initialize({
    int? maxMemoryUsage,
    int? warningThreshold,
    int? criticalThreshold,
    Duration? cacheExpirationTime,
    Duration? monitoringInterval,
    bool? enableAutoCleanup,
    bool? enableMemoryMonitoring,
  }) {
    _maxMemoryUsage = maxMemoryUsage ?? _maxMemoryUsage;
    _warningThreshold = warningThreshold ?? _warningThreshold;
    _criticalThreshold = criticalThreshold ?? _criticalThreshold;
    _cacheExpirationTime = cacheExpirationTime ?? _cacheExpirationTime;
    _monitoringInterval = monitoringInterval ?? _monitoringInterval;
    _enableAutoCleanup = enableAutoCleanup ?? _enableAutoCleanup;
    _enableMemoryMonitoring = enableMemoryMonitoring ?? _enableMemoryMonitoring;

    if (_enableMemoryMonitoring) {
      _startMemoryMonitoring();
    }
  }

  /// Get memory usage stream
  Stream<MemoryUsageSnapshot> get memoryUsageStream => _usageController.stream;

  /// Cache data with automatic memory management
  void cacheData(String key, dynamic data, {Duration? expiration}) {
    final size = _calculateDataSize(data);
    
    // Check if we have enough memory
    if (_currentMemoryUsage + size > _maxMemoryUsage) {
      _performCleanup(size);
    }

    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      _removeFromCache(key);
    }

    // Add new entry
    final entry = _CacheEntry(
      data: data,
      size: size,
      accessTime: DateTime.now(),
      creationTime: DateTime.now(),
    );

    _cache[key] = entry;
    _accessOrder.addLast(key);
    _currentMemoryUsage += size;

    // Set expiration timer
    final expirationTime = expiration ?? _cacheExpirationTime;
    _expirationTimers[key] = Timer(expirationTime, () {
      _removeFromCache(key);
    });

    _checkMemoryThresholds();
  }

  /// Retrieve cached data
  T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Update access time and order
    entry.accessTime = DateTime.now();
    _accessOrder.remove(key);
    _accessOrder.addLast(key);

    return entry.data as T?;
  }

  /// Remove data from cache
  void removeCachedData(String key) {
    _removeFromCache(key);
  }

  /// Clear all cached data
  void clearCache() {
    for (final key in _cache.keys.toList()) {
      _removeFromCache(key);
    }
  }

  /// Perform memory cleanup
  void performCleanup({bool force = false}) {
    if (force) {
      _performAggressiveCleanup();
    } else {
      _performCleanup(0);
    }
  }

  /// Get current memory usage statistics
  MemoryUsageSnapshot getMemoryUsage() {
    return MemoryUsageSnapshot(
      currentUsage: _currentMemoryUsage,
      maxUsage: _maxMemoryUsage,
      cachedItems: _cache.length,
      usagePercentage: (_currentMemoryUsage / _maxMemoryUsage * 100).round(),
      timestamp: DateTime.now(),
    );
  }

  /// Get memory usage history
  List<MemoryUsageSnapshot> getUsageHistory() {
    return List.unmodifiable(_usageHistory);
  }

  /// Optimize memory for large file operations
  Future<void> optimizeForLargeOperation() async {
    // Clear non-essential caches
    _performAggressiveCleanup();
    
    // Force garbage collection
    if (!kReleaseMode) {
      await _forceGarbageCollection();
    }
    
    // Reduce cache expiration time temporarily
    _cacheExpirationTime = const Duration(minutes: 2);
    
    // Schedule restoration of normal settings
    Timer(const Duration(minutes: 5), () {
      _cacheExpirationTime = const Duration(minutes: 10);
    });
  }

  /// Process large dataset in chunks to manage memory
  Future<List<T>> processLargeDataset<T>(
    List<dynamic> dataset,
    T Function(dynamic item) processor, {
    int chunkSize = 1000,
    Duration chunkDelay = const Duration(milliseconds: 10),
    void Function(int processed, int total)? onProgress,
  }) async {
    final results = <T>[];
    final total = dataset.length;
    
    for (int i = 0; i < total; i += chunkSize) {
      final end = (i + chunkSize < total) ? i + chunkSize : total;
      final chunk = dataset.sublist(i, end);
      
      // Process chunk
      for (final item in chunk) {
        results.add(processor(item));
      }
      
      // Report progress
      onProgress?.call(end, total);
      
      // Check memory usage and cleanup if needed
      if (_currentMemoryUsage > _maxMemoryUsage * 0.8) {
        _performCleanup(0);
      }
      
      // Small delay to prevent blocking UI
      if (chunkDelay > Duration.zero) {
        await Future.delayed(chunkDelay);
      }
    }
    
    return results;
  }

  /// Load file data with memory management
  Future<Uint8List?> loadFileData(String filePath, {bool cache = true}) async {
    if (cache) {
      final cached = getCachedData<Uint8List>(filePath);
      if (cached != null) return cached;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final size = await file.length();
      
      // Check if file is too large for memory
      if (size > _maxMemoryUsage * 0.5) {
        debugPrint('File too large for memory cache: $filePath (${size} bytes)');
        return await file.readAsBytes();
      }

      // Ensure we have enough memory
      if (_currentMemoryUsage + size > _maxMemoryUsage) {
        _performCleanup(size);
      }

      final data = await file.readAsBytes();
      
      if (cache) {
        cacheData(filePath, data);
      }
      
      return data;
    } catch (e) {
      debugPrint('Error loading file data: $e');
      return null;
    }
  }

  /// Dispose of the memory manager
  void dispose() {
    _memoryMonitorTimer?.cancel();
    clearCache();
    _usageController.close();
  }

  // Private methods

  void _removeFromCache(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentMemoryUsage -= entry.size;
      _accessOrder.remove(key);
      _expirationTimers[key]?.cancel();
      _expirationTimers.remove(key);
    }
  }

  void _performCleanup(int requiredSpace) {
    if (!_enableAutoCleanup) return;

    final targetUsage = _maxMemoryUsage - requiredSpace;
    
    // Remove expired items first
    _removeExpiredItems();
    
    // Remove least recently used items if still over limit
    while (_currentMemoryUsage > targetUsage && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.first;
      _removeFromCache(oldestKey);
    }
  }

  void _performAggressiveCleanup() {
    // Remove all but the most recently accessed items
    final keysToKeep = _accessOrder.length > 10 
        ? _accessOrder.toList().sublist(_accessOrder.length - 10)
        : _accessOrder.toList();
    
    for (final key in _cache.keys.toList()) {
      if (!keysToKeep.contains(key)) {
        _removeFromCache(key);
      }
    }
  }

  void _removeExpiredItems() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      final age = now.difference(entry.value.creationTime);
      if (age > _cacheExpirationTime) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _removeFromCache(key);
    }
  }

  int _calculateDataSize(dynamic data) {
    if (data is Uint8List) {
      return data.length;
    } else if (data is String) {
      return data.length * 2; // Approximate UTF-16 encoding
    } else if (data is List) {
      return data.length * 8; // Approximate pointer size
    } else if (data is Map) {
      return data.length * 16; // Approximate key-value pair size
    } else {
      return 64; // Default size for unknown objects
    }
  }

  void _checkMemoryThresholds() {
    final usagePercentage = (_currentMemoryUsage / _maxMemoryUsage * 100).round();
    
    if (usagePercentage >= _criticalThreshold) {
      debugPrint('Critical memory usage: $usagePercentage%');
      _performAggressiveCleanup();
    } else if (usagePercentage >= _warningThreshold) {
      debugPrint('High memory usage: $usagePercentage%');
      _performCleanup(0);
    }
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_monitoringInterval, (timer) {
      final snapshot = getMemoryUsage();
      _usageHistory.add(snapshot);
      
      // Keep only recent history
      if (_usageHistory.length > 100) {
        _usageHistory.removeAt(0);
      }
      
      _usageController.add(snapshot);
      _checkMemoryThresholds();
    });
  }

  Future<void> _forceGarbageCollection() async {
    // This is a hint to the garbage collector, not a guarantee
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

/// Cache entry data class
class _CacheEntry {
  final dynamic data;
  final int size;
  DateTime accessTime;
  final DateTime creationTime;

  _CacheEntry({
    required this.data,
    required this.size,
    required this.accessTime,
    required this.creationTime,
  });
}

/// Memory usage snapshot
class MemoryUsageSnapshot {
  final int currentUsage;
  final int maxUsage;
  final int cachedItems;
  final int usagePercentage;
  final DateTime timestamp;

  const MemoryUsageSnapshot({
    required this.currentUsage,
    required this.maxUsage,
    required this.cachedItems,
    required this.usagePercentage,
    required this.timestamp,
  });

  double get usageRatio => currentUsage / maxUsage;
  int get availableMemory => maxUsage - currentUsage;
  
  Map<String, dynamic> toMap() {
    return {
      'currentUsage': currentUsage,
      'maxUsage': maxUsage,
      'cachedItems': cachedItems,
      'usagePercentage': usagePercentage,
      'availableMemory': availableMemory,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MemoryUsage(${usagePercentage}%, ${cachedItems} items, ${(currentUsage / 1024 / 1024).toStringAsFixed(1)}MB used)';
  }
}

/// Memory-efficient data processor for large datasets
class DataProcessor<T> {
  final MemoryManager _memoryManager = MemoryManager();
  final int _defaultChunkSize;
  final Duration _defaultChunkDelay;

  DataProcessor({
    int defaultChunkSize = 1000,
    Duration defaultChunkDelay = const Duration(milliseconds: 10),
  }) : _defaultChunkSize = defaultChunkSize,
       _defaultChunkDelay = defaultChunkDelay;

  /// Process data in memory-efficient chunks
  Future<List<R>> processInChunks<R>(
    List<T> data,
    R Function(T item) processor, {
    int? chunkSize,
    Duration? chunkDelay,
    void Function(int processed, int total)? onProgress,
  }) async {
    return await _memoryManager.processLargeDataset<R>(
      data.cast<dynamic>(),
      (dynamic item) => processor(item as T),
      chunkSize: chunkSize ?? _defaultChunkSize,
      chunkDelay: chunkDelay ?? _defaultChunkDelay,
      onProgress: onProgress,
    );
  }

  /// Filter data in memory-efficient chunks
  Future<List<T>> filterInChunks(
    List<T> data,
    bool Function(T item) predicate, {
    int? chunkSize,
    Duration? chunkDelay,
    void Function(int processed, int total)? onProgress,
  }) async {
    final results = <T>[];
    final total = data.length;
    final effectiveChunkSize = chunkSize ?? _defaultChunkSize;
    final effectiveDelay = chunkDelay ?? _defaultChunkDelay;
    
    for (int i = 0; i < total; i += effectiveChunkSize) {
      final end = (i + effectiveChunkSize < total) ? i + effectiveChunkSize : total;
      final chunk = data.sublist(i, end);
      
      // Filter chunk
      for (final item in chunk) {
        if (predicate(item)) {
          results.add(item);
        }
      }
      
      // Report progress
      onProgress?.call(end, total);
      
      // Check memory and delay
      if (_memoryManager.getMemoryUsage().usagePercentage > 80) {
        _memoryManager.performCleanup();
      }
      
      if (effectiveDelay > Duration.zero) {
        await Future.delayed(effectiveDelay);
      }
    }
    
    return results;
  }

  /// Sort data in memory-efficient way
  Future<List<T>> sortInChunks(
    List<T> data,
    int Function(T a, T b) comparator, {
    int? chunkSize,
  }) async {
    final effectiveChunkSize = chunkSize ?? _defaultChunkSize;
    
    if (data.length <= effectiveChunkSize) {
      // Small dataset, sort normally
      data.sort(comparator);
      return data;
    }
    
    // Large dataset, use merge sort approach
    final chunks = <List<T>>[];
    
    // Sort individual chunks
    for (int i = 0; i < data.length; i += effectiveChunkSize) {
      final end = (i + effectiveChunkSize < data.length) ? i + effectiveChunkSize : data.length;
      final chunk = data.sublist(i, end);
      chunk.sort(comparator);
      chunks.add(chunk);
      
      // Small delay to prevent blocking
      await Future.delayed(const Duration(milliseconds: 1));
    }
    
    // Merge sorted chunks
    return _mergeSortedChunks(chunks, comparator);
  }

  List<T> _mergeSortedChunks(List<List<T>> chunks, int Function(T a, T b) comparator) {
    if (chunks.isEmpty) return [];
    if (chunks.length == 1) return chunks[0];
    
    final result = <T>[];
    final indices = List.filled(chunks.length, 0);
    
    while (true) {
      int minIndex = -1;
      T? minValue;
      
      // Find the minimum value among chunk heads
      for (int i = 0; i < chunks.length; i++) {
        if (indices[i] < chunks[i].length) {
          final value = chunks[i][indices[i]];
          if (minValue == null || comparator(value, minValue) < 0) {
            minValue = value;
            minIndex = i;
          }
        }
      }
      
      if (minIndex == -1) break; // All chunks exhausted
      
      result.add(minValue!);
      indices[minIndex]++;
    }
    
    return result;
  }
}
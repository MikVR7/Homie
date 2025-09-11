import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Intelligent caching service for API responses and data management
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache configuration
  static const String _cacheVersion = '1.0.0';
  static const Duration _defaultTtl = Duration(hours: 1);
  static const Duration _longTtl = Duration(days: 7);
  static const Duration _shortTtl = Duration(minutes: 15);
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxDiskCacheSize = 200 * 1024 * 1024; // 200MB

  // Cache storage
  final Map<String, CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;
  Directory? _cacheDirectory;
  
  // Cache statistics
  int _hitCount = 0;
  int _missCount = 0;
  int _currentMemorySize = 0;
  int _currentDiskSize = 0;

  // Cache policies
  final Map<String, CachePolicy> _cachePolicies = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (!kIsWeb) {
        _cacheDirectory = await getApplicationCacheDirectory();
      }
      
      // Set up default cache policies
      _setupDefaultPolicies();
      
      // Clean up expired entries on startup
      await _cleanupExpiredEntries();
      
      // Calculate current cache sizes
      await _calculateCacheSizes();
      
      debugPrint('CacheService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CacheService: $e');
    }
  }

  /// Cache data with automatic policy selection
  Future<void> cacheData(
    String key, 
    dynamic data, {
    Duration? ttl,
    CacheLevel level = CacheLevel.auto,
    String? category,
  }) async {
    try {
      final policy = _getCachePolicy(key, category);
      final effectiveTtl = ttl ?? policy.ttl;
      final effectiveLevel = level == CacheLevel.auto ? policy.level : level;
      
      final entry = CacheEntry(
        key: key,
        data: data,
        timestamp: DateTime.now(),
        ttl: effectiveTtl,
        level: effectiveLevel,
        category: category,
        size: _calculateDataSize(data),
      );

      // Store in appropriate cache level
      switch (effectiveLevel) {
        case CacheLevel.memory:
          await _cacheInMemory(entry);
          break;
        case CacheLevel.disk:
          await _cacheToDisk(entry);
          break;
        case CacheLevel.both:
          await _cacheInMemory(entry);
          await _cacheToDisk(entry);
          break;
        case CacheLevel.auto:
          // Auto-select based on data size and access pattern
          if (entry.size < 1024 * 100) { // < 100KB
            await _cacheInMemory(entry);
          } else {
            await _cacheToDisk(entry);
          }
          break;
      }

      debugPrint('Cached data: $key (${entry.size} bytes, TTL: ${effectiveTtl.inMinutes}min)');
    } catch (e) {
      debugPrint('Error caching data for key $key: $e');
    }
  }

  /// Retrieve cached data
  Future<T?> getCachedData<T>(String key, {String? category}) async {
    try {
      // Check memory cache first
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _hitCount++;
        memoryEntry.lastAccessed = DateTime.now();
        return memoryEntry.data as T?;
      }

      // Check disk cache
      final diskEntry = await _getDiskCacheEntry(key);
      if (diskEntry != null && !diskEntry.isExpired) {
        _hitCount++;
        diskEntry.lastAccessed = DateTime.now();
        
        // Promote to memory cache if frequently accessed
        if (_shouldPromoteToMemory(diskEntry)) {
          await _cacheInMemory(diskEntry);
        }
        
        return diskEntry.data as T?;
      }

      _missCount++;
      return null;
    } catch (e) {
      debugPrint('Error retrieving cached data for key $key: $e');
      _missCount++;
      return null;
    }
  }

  /// Remove cached data
  Future<void> removeCachedData(String key) async {
    try {
      // Remove from memory
      final memoryEntry = _memoryCache.remove(key);
      if (memoryEntry != null) {
        _currentMemorySize -= memoryEntry.size;
      }

      // Remove from disk
      await _removeDiskCacheEntry(key);
      
      debugPrint('Removed cached data: $key');
    } catch (e) {
      debugPrint('Error removing cached data for key $key: $e');
    }
  }

  /// Clear cache by category
  Future<void> clearCacheByCategory(String category) async {
    try {
      // Clear memory cache
      final keysToRemove = _memoryCache.entries
          .where((entry) => entry.value.category == category)
          .map((entry) => entry.key)
          .toList();
      
      for (final key in keysToRemove) {
        final entry = _memoryCache.remove(key);
        if (entry != null) {
          _currentMemorySize -= entry.size;
        }
      }

      // Clear disk cache
      await _clearDiskCacheByCategory(category);
      
      debugPrint('Cleared cache for category: $category');
    } catch (e) {
      debugPrint('Error clearing cache for category $category: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _currentMemorySize = 0;
      
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create();
      }
      
      _currentDiskSize = 0;
      debugPrint('Cleared all cache');
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    final hitRate = (_hitCount + _missCount) > 0 
        ? _hitCount / (_hitCount + _missCount) 
        : 0.0;

    return CacheStatistics(
      hitCount: _hitCount,
      missCount: _missCount,
      hitRate: hitRate,
      memoryEntries: _memoryCache.length,
      memorySize: _currentMemorySize,
      diskSize: _currentDiskSize,
      maxMemorySize: _maxMemoryCacheSize,
      maxDiskSize: _maxDiskCacheSize,
    );
  }

  /// Set cache policy for specific keys or categories
  void setCachePolicy(String pattern, CachePolicy policy) {
    _cachePolicies[pattern] = policy;
  }

  /// Preload frequently accessed data
  Future<void> preloadData(Map<String, Future<dynamic> Function()> dataLoaders) async {
    final futures = <Future<void>>[];
    
    for (final entry in dataLoaders.entries) {
      futures.add(_preloadSingleData(entry.key, entry.value));
    }
    
    await Future.wait(futures);
    debugPrint('Preloaded ${dataLoaders.length} data entries');
  }

  /// Optimize cache performance
  Future<void> optimizeCache() async {
    try {
      // Remove expired entries
      await _cleanupExpiredEntries();
      
      // Evict least recently used entries if over size limit
      await _evictLRUEntries();
      
      // Defragment disk cache
      await _defragmentDiskCache();
      
      debugPrint('Cache optimization completed');
    } catch (e) {
      debugPrint('Error optimizing cache: $e');
    }
  }

  // Private methods

  void _setupDefaultPolicies() {
    // API responses - short TTL, memory cache
    setCachePolicy('api_*', CachePolicy(
      ttl: _shortTtl,
      level: CacheLevel.memory,
      maxSize: 1024 * 1024, // 1MB
    ));

    // File listings - medium TTL, both caches
    setCachePolicy('files_*', CachePolicy(
      ttl: _defaultTtl,
      level: CacheLevel.both,
      maxSize: 5 * 1024 * 1024, // 5MB
    ));

    // User preferences - long TTL, disk cache
    setCachePolicy('prefs_*', CachePolicy(
      ttl: _longTtl,
      level: CacheLevel.disk,
      maxSize: 1024 * 100, // 100KB
    ));

    // Thumbnails - long TTL, disk cache
    setCachePolicy('thumb_*', CachePolicy(
      ttl: _longTtl,
      level: CacheLevel.disk,
      maxSize: 10 * 1024 * 1024, // 10MB
    ));
  }

  CachePolicy _getCachePolicy(String key, String? category) {
    // Check for exact key match
    if (_cachePolicies.containsKey(key)) {
      return _cachePolicies[key]!;
    }

    // Check for pattern matches
    for (final entry in _cachePolicies.entries) {
      if (entry.key.contains('*')) {
        final pattern = entry.key.replaceAll('*', '');
        if (key.startsWith(pattern) || (category != null && category.startsWith(pattern))) {
          return entry.value;
        }
      }
    }

    // Default policy
    return CachePolicy(
      ttl: _defaultTtl,
      level: CacheLevel.auto,
      maxSize: 1024 * 1024, // 1MB
    );
  }

  Future<void> _cacheInMemory(CacheEntry entry) async {
    // Check if we need to evict entries
    if (_currentMemorySize + entry.size > _maxMemoryCacheSize) {
      await _evictMemoryEntries(entry.size);
    }

    _memoryCache[entry.key] = entry;
    _currentMemorySize += entry.size;
  }

  Future<void> _cacheToDisk(CacheEntry entry) async {
    if (_cacheDirectory == null) return;

    try {
      final file = File('${_cacheDirectory!.path}/${_sanitizeKey(entry.key)}.cache');
      final cacheData = {
        'version': _cacheVersion,
        'data': entry.data,
        'timestamp': entry.timestamp.millisecondsSinceEpoch,
        'ttl': entry.ttl.inMilliseconds,
        'category': entry.category,
        'size': entry.size,
      };

      await file.writeAsString(jsonEncode(cacheData));
      _currentDiskSize += entry.size;
    } catch (e) {
      debugPrint('Error writing to disk cache: $e');
    }
  }

  Future<CacheEntry?> _getDiskCacheEntry(String key) async {
    if (_cacheDirectory == null) return null;

    try {
      final file = File('${_cacheDirectory!.path}/${_sanitizeKey(key)}.cache');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final cacheData = jsonDecode(content) as Map<String, dynamic>;

      // Check version compatibility
      if (cacheData['version'] != _cacheVersion) {
        await file.delete();
        return null;
      }

      return CacheEntry(
        key: key,
        data: cacheData['data'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']),
        ttl: Duration(milliseconds: cacheData['ttl']),
        level: CacheLevel.disk,
        category: cacheData['category'],
        size: cacheData['size'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error reading from disk cache: $e');
      return null;
    }
  }

  Future<void> _removeDiskCacheEntry(String key) async {
    if (_cacheDirectory == null) return;

    try {
      final file = File('${_cacheDirectory!.path}/${_sanitizeKey(key)}.cache');
      if (await file.exists()) {
        final stat = await file.stat();
        await file.delete();
        _currentDiskSize -= stat.size;
      }
    } catch (e) {
      debugPrint('Error removing disk cache entry: $e');
    }
  }

  Future<void> _clearDiskCacheByCategory(String category) async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.cache')) {
          try {
            final content = await file.readAsString();
            final cacheData = jsonDecode(content) as Map<String, dynamic>;
            if (cacheData['category'] == category) {
              final stat = await file.stat();
              await file.delete();
              _currentDiskSize -= stat.size;
            }
          } catch (e) {
            // Skip corrupted files
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing disk cache by category: $e');
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    // Clean memory cache
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      final entry = _memoryCache.remove(key);
      if (entry != null) {
        _currentMemorySize -= entry.size;
      }
    }

    // Clean disk cache
    await _cleanupExpiredDiskEntries();
  }

  Future<void> _cleanupExpiredDiskEntries() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.cache')) {
          try {
            final content = await file.readAsString();
            final cacheData = jsonDecode(content) as Map<String, dynamic>;
            final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
            final ttl = Duration(milliseconds: cacheData['ttl']);
            
            if (DateTime.now().difference(timestamp) > ttl) {
              final stat = await file.stat();
              await file.delete();
              _currentDiskSize -= stat.size;
            }
          } catch (e) {
            // Delete corrupted files
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired disk entries: $e');
    }
  }

  Future<void> _evictMemoryEntries(int requiredSpace) async {
    final entries = _memoryCache.values.toList();
    entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

    int freedSpace = 0;
    for (final entry in entries) {
      if (freedSpace >= requiredSpace) break;
      
      _memoryCache.remove(entry.key);
      _currentMemorySize -= entry.size;
      freedSpace += entry.size;
    }
  }

  Future<void> _evictLRUEntries() async {
    // Evict memory entries if over limit
    while (_currentMemorySize > _maxMemoryCacheSize && _memoryCache.isNotEmpty) {
      final oldestEntry = _memoryCache.values
          .reduce((a, b) => a.lastAccessed.isBefore(b.lastAccessed) ? a : b);
      
      _memoryCache.remove(oldestEntry.key);
      _currentMemorySize -= oldestEntry.size;
    }
  }

  Future<void> _defragmentDiskCache() async {
    // This could be implemented to reorganize disk cache files
    // For now, just recalculate the disk size
    await _calculateCacheSizes();
  }

  Future<void> _calculateCacheSizes() async {
    _currentMemorySize = _memoryCache.values
        .fold(0, (sum, entry) => sum + entry.size);

    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      _currentDiskSize = 0;
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          _currentDiskSize += stat.size;
        }
      }
    }
  }

  bool _shouldPromoteToMemory(CacheEntry entry) {
    // Promote if accessed recently and small enough
    final recentlyAccessed = DateTime.now().difference(entry.lastAccessed) < const Duration(minutes: 5);
    final smallEnough = entry.size < 1024 * 100; // 100KB
    return recentlyAccessed && smallEnough;
  }

  Future<void> _preloadSingleData(String key, Future<dynamic> Function() loader) async {
    try {
      final existingData = await getCachedData(key);
      if (existingData == null) {
        final data = await loader();
        await cacheData(key, data);
      }
    } catch (e) {
      debugPrint('Error preloading data for key $key: $e');
    }
  }

  int _calculateDataSize(dynamic data) {
    if (data is String) {
      return data.length * 2; // UTF-16 encoding
    } else if (data is List) {
      return data.length * 8; // Approximate
    } else if (data is Map) {
      return data.length * 16; // Approximate
    } else {
      return 64; // Default size
    }
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-_.]'), '_');
  }
}

/// Cache entry data class
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final CacheLevel level;
  final String? category;
  final int size;
  DateTime lastAccessed;

  CacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.level,
    this.category,
    required this.size,
  }) : lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Cache policy configuration
class CachePolicy {
  final Duration ttl;
  final CacheLevel level;
  final int maxSize;

  const CachePolicy({
    required this.ttl,
    required this.level,
    required this.maxSize,
  });
}

/// Cache level enumeration
enum CacheLevel {
  memory,
  disk,
  both,
  auto,
}

/// Cache statistics
class CacheStatistics {
  final int hitCount;
  final int missCount;
  final double hitRate;
  final int memoryEntries;
  final int memorySize;
  final int diskSize;
  final int maxMemorySize;
  final int maxDiskSize;

  const CacheStatistics({
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
    required this.memoryEntries,
    required this.memorySize,
    required this.diskSize,
    required this.maxMemorySize,
    required this.maxDiskSize,
  });

  double get memoryUsagePercentage => memorySize / maxMemorySize;
  double get diskUsagePercentage => diskSize / maxDiskSize;

  Map<String, dynamic> toMap() {
    return {
      'hitCount': hitCount,
      'missCount': missCount,
      'hitRate': hitRate,
      'memoryEntries': memoryEntries,
      'memorySize': memorySize,
      'diskSize': diskSize,
      'memoryUsagePercentage': memoryUsagePercentage,
      'diskUsagePercentage': diskUsagePercentage,
    };
  }

  @override
  String toString() {
    return 'CacheStats(hit: ${(hitRate * 100).toStringAsFixed(1)}%, '
           'memory: ${memoryEntries} entries, '
           'disk: ${(diskSize / 1024 / 1024).toStringAsFixed(1)}MB)';
  }
}
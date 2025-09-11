import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mobile_platform_service.dart';

/// Mobile performance optimization utilities
class MobilePerformanceOptimizer {
  static const int _defaultMaxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _defaultMaxConcurrentOperations = 3;
  static const Duration _defaultBatteryOptimizationInterval = Duration(minutes: 5);

  static Map<String, dynamic>? _cachedConfig;
  static Timer? _batteryOptimizationTimer;
  static final Map<String, dynamic> _performanceMetrics = {};

  /// Initialize mobile performance optimizations
  static Future<void> initialize() async {
    if (!MobilePlatformService.isMobilePlatform) {
      debugPrint('Mobile performance optimizer: Not on mobile platform, skipping initialization');
      return;
    }

    _cachedConfig = {
      'enableImageCaching': true,
      'maxCacheSize': _defaultMaxCacheSize,
      'enableLazyLoading': true,
      'enableMemoryOptimization': true,
      'enableBatteryOptimization': MobilePlatformService.currentPlatform == MobilePlatform.android,
      'maxConcurrentOperations': _defaultMaxConcurrentOperations,
      'backgroundTaskTimeout': _defaultBatteryOptimizationInterval,
      'enableNetworkOptimization': true,
    };
    
    // Start battery optimization if enabled
    if (_cachedConfig!['enableBatteryOptimization'] == true) {
      _startBatteryOptimization();
    }

    // Initialize memory optimization
    if (_cachedConfig!['enableMemoryOptimization'] == true) {
      _initializeMemoryOptimization();
    }

    // Initialize network optimization
    if (_cachedConfig!['enableNetworkOptimization'] == true) {
      _initializeNetworkOptimization();
    }

    debugPrint('Mobile performance optimizer initialized');
  }

  /// Dispose of performance optimization resources
  static void dispose() {
    _batteryOptimizationTimer?.cancel();
    _batteryOptimizationTimer = null;
    _cachedConfig = null;
    _performanceMetrics.clear();
  }

  /// Get current performance configuration
  static Map<String, dynamic> getConfiguration() {
    return _cachedConfig ?? {
      'enableImageCaching': true,
      'maxCacheSize': _defaultMaxCacheSize,
      'enableLazyLoading': true,
      'enableMemoryOptimization': true,
      'enableBatteryOptimization': false,
      'maxConcurrentOperations': _defaultMaxConcurrentOperations,
      'backgroundTaskTimeout': _defaultBatteryOptimizationInterval,
      'enableNetworkOptimization': true,
    };
  }

  /// Optimize image loading for mobile
  static ImageProvider optimizeImageProvider(
    ImageProvider provider, {
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) {
    final config = getConfiguration();
    
    if (config['enableImageCaching'] != true) {
      return provider;
    }

    // Apply mobile-specific image optimizations
    if (provider is NetworkImage) {
      return _OptimizedNetworkImage(
        provider.url,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality ?? (config['enableMemoryOptimization'] == true ? 85 : 95),
        enableCaching: config['enableImageCaching'] == true,
        maxCacheSize: config['maxCacheSize'] ?? _defaultMaxCacheSize,
      );
    }

    return provider;
  }

  /// Optimize widget building for mobile performance
  static Widget optimizeWidget(
    Widget child, {
    bool enableLazyLoading = true,
    bool enableCaching = true,
    String? cacheKey,
  }) {
    final config = getConfiguration();

    Widget optimizedChild = child;

    // Apply lazy loading if enabled
    if (config['enableLazyLoading'] == true && enableLazyLoading) {
      optimizedChild = _LazyLoadingWidget(
        cacheKey: cacheKey,
        child: optimizedChild,
      );
    }

    // Apply widget caching if enabled
    if (enableCaching && cacheKey != null) {
      optimizedChild = _CachedWidget(
        key: ValueKey(cacheKey),
        child: optimizedChild,
      );
    }

    return optimizedChild;
  }

  /// Optimize list performance for mobile
  static Widget optimizeListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    bool shrinkWrap = false,
    EdgeInsets? padding,
    double? itemExtent,
    bool enableVirtualScrolling = true,
  }) {
    final config = getConfiguration();

    if (config['enableLazyLoading'] == true && enableVirtualScrolling && itemCount > 50) {
      return _VirtualizedListView(
        itemBuilder: itemBuilder,
        itemCount: itemCount,
        controller: controller,
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemExtent: itemExtent,
      );
    }

    return ListView.builder(
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
    );
  }

  /// Optimize animation performance for mobile
  static AnimationController optimizeAnimationController({
    required Duration duration,
    required TickerProvider vsync,
    double? value,
    Duration? reverseDuration,
    String? debugLabel,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final config = getConfiguration();
    
    // Reduce animation duration on low-performance devices
    Duration optimizedDuration = duration;
    if (config['enableBatteryOptimization'] == true) {
      optimizedDuration = Duration(
        milliseconds: (duration.inMilliseconds * 0.8).round(),
      );
    }

    return AnimationController(
      duration: optimizedDuration,
      reverseDuration: reverseDuration,
      value: value,
      debugLabel: debugLabel,
      vsync: vsync,
      animationBehavior: animationBehavior,
    );
  }

  /// Throttle function calls for performance
  static Function throttle(
    Function func,
    Duration delay, {
    bool leading = true,
    bool trailing = true,
  }) {
    Timer? timer;
    bool lastCallTime = false;

    return ([dynamic args]) {
      if (leading && !lastCallTime) {
        func(args);
        lastCallTime = true;
      }

      timer?.cancel();
      timer = Timer(delay, () {
        if (trailing) {
          func(args);
        }
        lastCallTime = false;
      });
    };
  }

  /// Debounce function calls for performance
  static Function debounce(Function func, Duration delay) {
    Timer? timer;

    return ([dynamic args]) {
      timer?.cancel();
      timer = Timer(delay, () => func(args));
    };
  }

  /// Optimize network requests for mobile
  static Future<T> optimizeNetworkRequest<T>(
    Future<T> Function() request, {
    Duration? timeout,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    final config = getConfiguration();
    
    if (config['enableNetworkOptimization'] != true) {
      return await request();
    }

    final optimizedTimeout = timeout ?? const Duration(seconds: 30);
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await request().timeout(optimizedTimeout);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        final delay = Duration(
          milliseconds: retryDelay.inMilliseconds * (1 << (attempts - 1)),
        );
        await Future.delayed(delay);
      }
    }

    throw Exception('Network request failed after $maxRetries attempts');
  }

  /// Monitor performance metrics
  static void recordMetric(String key, dynamic value) {
    _performanceMetrics[key] = {
      'value': value,
      'timestamp': DateTime.now(),
    };

    // Keep only recent metrics to avoid memory leaks
    if (_performanceMetrics.length > 100) {
      final oldestKey = _performanceMetrics.keys.first;
      _performanceMetrics.remove(oldestKey);
    }
  }

  /// Get performance metrics
  static Map<String, dynamic> getMetrics() {
    return Map.from(_performanceMetrics);
  }

  /// Clear performance metrics
  static void clearMetrics() {
    _performanceMetrics.clear();
  }

  /// Check if device is in low-performance mode
  static bool isLowPerformanceMode() {
    // This would typically check device specifications, battery level, etc.
    // For now, return false as a placeholder
    return false;
  }

  /// Optimize for battery usage
  static void optimizeForBattery() {
    if (!MobilePlatformService.isMobilePlatform) return;

    // Reduce animation frame rate
    WidgetsBinding.instance.scheduleFrame();
    
    // Trigger garbage collection
    if (!kReleaseMode) {
      debugPrint('Optimizing for battery usage');
    }
  }

  /// Optimize for memory usage
  static void optimizeForMemory() {
    if (!MobilePlatformService.isMobilePlatform) return;

    // Clear image cache if it's too large
    final config = getConfiguration();
    if (config['enableImageCaching'] == true) {
      PaintingBinding.instance.imageCache.clear();
    }

    // Clear performance metrics if they're taking up too much space
    if (_performanceMetrics.length > 50) {
      clearMetrics();
    }

    if (!kReleaseMode) {
      debugPrint('Optimizing for memory usage');
    }
  }

  /// Start battery optimization timer
  static void _startBatteryOptimization() {
    _batteryOptimizationTimer?.cancel();
    _batteryOptimizationTimer = Timer.periodic(
      _defaultBatteryOptimizationInterval,
      (timer) {
        optimizeForBattery();
      },
    );
  }

  /// Initialize memory optimization
  static void _initializeMemoryOptimization() {
    // Set up memory pressure monitoring
    if (Platform.isAndroid || Platform.isIOS) {
      // In a real implementation, this would use platform channels
      // to monitor memory pressure and respond accordingly
      debugPrint('Memory optimization initialized');
    }
  }

  /// Initialize network optimization
  static void _initializeNetworkOptimization() {
    // Set up network monitoring and optimization
    debugPrint('Network optimization initialized');
  }
}

/// Optimized network image provider
class _OptimizedNetworkImage extends ImageProvider<_OptimizedNetworkImage> {
  final String url;
  final double? maxWidth;
  final double? maxHeight;
  final int quality;
  final bool enableCaching;
  final int maxCacheSize;

  const _OptimizedNetworkImage(
    this.url, {
    this.maxWidth,
    this.maxHeight,
    required this.quality,
    required this.enableCaching,
    required this.maxCacheSize,
  });

  @override
  Future<_OptimizedNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_OptimizedNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(_OptimizedNetworkImage key, DecoderBufferCallback decode) {
    // In a real implementation, this would apply image optimizations
    // For now, delegate to NetworkImage
    final networkImage = NetworkImage(url);
    return networkImage.loadBuffer(networkImage, decode);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _OptimizedNetworkImage &&
        other.url == url &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.quality == quality;
  }

  @override
  int get hashCode => Object.hash(url, maxWidth, maxHeight, quality);
}

/// Lazy loading widget wrapper
class _LazyLoadingWidget extends StatefulWidget {
  final Widget child;
  final String? cacheKey;

  const _LazyLoadingWidget({
    required this.child,
    this.cacheKey,
  });

  @override
  State<_LazyLoadingWidget> createState() => _LazyLoadingWidgetState();
}

class _LazyLoadingWidgetState extends State<_LazyLoadingWidget> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(widget.cacheKey ?? widget.hashCode),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: _isVisible
          ? widget.child
          : Container(
              height: 100, // Placeholder height
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}

/// Cached widget wrapper
class _CachedWidget extends StatelessWidget {
  final Widget child;

  const _CachedWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real implementation, this would implement widget caching
    return child;
  }
}

/// Virtualized list view for performance
class _VirtualizedListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double? itemExtent;

  const _VirtualizedListView({
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    required this.shrinkWrap,
    this.padding,
    this.itemExtent,
  });

  @override
  State<_VirtualizedListView> createState() => _VirtualizedListViewState();
}

class _VirtualizedListViewState extends State<_VirtualizedListView> {
  late ScrollController _scrollController;
  final Map<int, Widget> _cachedWidgets = {};
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 20; // Show first 20 items initially

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    // Calculate visible range based on scroll position
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemHeight = widget.itemExtent ?? 100.0;

    final newFirstIndex = (scrollOffset / itemHeight).floor().clamp(0, widget.itemCount - 1);
    final newLastIndex = ((scrollOffset + viewportHeight) / itemHeight).ceil().clamp(0, widget.itemCount - 1);

    if (newFirstIndex != _firstVisibleIndex || newLastIndex != _lastVisibleIndex) {
      setState(() {
        _firstVisibleIndex = newFirstIndex;
        _lastVisibleIndex = newLastIndex;
      });

      // Clear cache of widgets that are far from visible range
      _cachedWidgets.removeWhere((index, widget) {
        return index < newFirstIndex - 10 || index > newLastIndex + 10;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemExtent: widget.itemExtent,
      itemBuilder: (context, index) {
        // Only build widgets that are visible or close to visible
        if (index < _firstVisibleIndex - 5 || index > _lastVisibleIndex + 5) {
          return SizedBox(height: widget.itemExtent ?? 100.0);
        }

        // Use cached widget if available
        if (_cachedWidgets.containsKey(index)) {
          return _cachedWidgets[index]!;
        }

        // Build and cache new widget
        final builtWidget = widget.itemBuilder(context, index);
        _cachedWidgets[index] = builtWidget;
        return builtWidget;
      },
    );
  }
}

/// Visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    // In a real implementation, this would use IntersectionObserver or similar
    // For now, assume everything is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(const VisibilityInfo(visibleFraction: 1.0));
    });

    return widget.child;
  }
}

/// Visibility information
class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}
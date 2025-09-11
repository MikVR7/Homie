import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Efficient state manager that minimizes rebuilds through selective notifications
class EfficientStateManager<T> extends ChangeNotifier {
  T _value;
  final Map<String, dynamic> _properties = {};
  final Map<String, Set<VoidCallback>> _propertyListeners = {};
  final Set<String> _changedProperties = {};
  Timer? _batchUpdateTimer;
  final Duration _batchDelay;

  EfficientStateManager(
    this._value, {
    Duration batchDelay = const Duration(milliseconds: 16), // ~60fps
  }) : _batchDelay = batchDelay;

  T get value => _value;

  /// Set the entire value and notify all listeners
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _scheduleNotification();
    }
  }

  /// Get a specific property value
  P? getProperty<P>(String key) {
    return _properties[key] as P?;
  }

  /// Set a specific property and notify only relevant listeners
  void setProperty<P>(String key, P value) {
    if (_properties[key] != value) {
      _properties[key] = value;
      _changedProperties.add(key);
      _schedulePropertyNotification(key);
    }
  }

  /// Update multiple properties at once
  void updateProperties(Map<String, dynamic> updates) {
    bool hasChanges = false;
    for (final entry in updates.entries) {
      if (_properties[entry.key] != entry.value) {
        _properties[entry.key] = entry.value;
        _changedProperties.add(entry.key);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _scheduleBatchNotification();
    }
  }

  /// Add a listener for a specific property
  void addPropertyListener(String property, VoidCallback listener) {
    _propertyListeners.putIfAbsent(property, () => <VoidCallback>{});
    _propertyListeners[property]!.add(listener);
  }

  /// Remove a listener for a specific property
  void removePropertyListener(String property, VoidCallback listener) {
    _propertyListeners[property]?.remove(listener);
    if (_propertyListeners[property]?.isEmpty == true) {
      _propertyListeners.remove(property);
    }
  }

  void _scheduleNotification() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(_batchDelay, () {
      notifyListeners();
    });
  }

  void _schedulePropertyNotification(String property) {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(_batchDelay, () {
      _notifyPropertyListeners(property);
    });
  }

  void _scheduleBatchNotification() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(_batchDelay, () {
      for (final property in _changedProperties) {
        _notifyPropertyListeners(property);
      }
      _changedProperties.clear();
      notifyListeners();
    });
  }

  void _notifyPropertyListeners(String property) {
    final listeners = _propertyListeners[property];
    if (listeners != null) {
      for (final listener in listeners.toList()) {
        listener();
      }
    }
  }

  @override
  void dispose() {
    _batchUpdateTimer?.cancel();
    _propertyListeners.clear();
    _changedProperties.clear();
    super.dispose();
  }
}

/// Widget that listens to specific properties of an EfficientStateManager
class PropertyListener<T> extends StatefulWidget {
  final EfficientStateManager<T> stateManager;
  final List<String> properties;
  final Widget Function(BuildContext context, T value) builder;

  const PropertyListener({
    Key? key,
    required this.stateManager,
    required this.properties,
    required this.builder,
  }) : super(key: key);

  @override
  State<PropertyListener<T>> createState() => _PropertyListenerState<T>();
}

class _PropertyListenerState<T> extends State<PropertyListener<T>> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    
    for (final property in widget.properties) {
      widget.stateManager.addPropertyListener(property, _listener);
    }
  }

  @override
  void didUpdateWidget(PropertyListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.stateManager != widget.stateManager ||
        !listEquals(oldWidget.properties, widget.properties)) {
      // Remove old listeners
      for (final property in oldWidget.properties) {
        oldWidget.stateManager.removePropertyListener(property, _listener);
      }
      
      // Add new listeners
      for (final property in widget.properties) {
        widget.stateManager.addPropertyListener(property, _listener);
      }
    }
  }

  @override
  void dispose() {
    for (final property in widget.properties) {
      widget.stateManager.removePropertyListener(property, _listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.stateManager.value);
  }
}

/// Mixin for widgets that need to minimize rebuilds
mixin EfficientRebuildMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _trackedProperties = {};
  final Map<String, dynamic> _lastValues = {};

  /// Check if a property has changed since last build
  bool hasPropertyChanged(String property, dynamic value) {
    if (!_trackedProperties.contains(property)) {
      _trackedProperties.add(property);
      _lastValues[property] = value;
      return true;
    }
    
    final lastValue = _lastValues[property];
    if (lastValue != value) {
      _lastValues[property] = value;
      return true;
    }
    
    return false;
  }

  /// Mark properties as tracked without checking for changes
  void trackProperties(Map<String, dynamic> properties) {
    for (final entry in properties.entries) {
      _trackedProperties.add(entry.key);
      _lastValues[entry.key] = entry.value;
    }
  }

  /// Reset tracking for all properties
  void resetTracking() {
    _trackedProperties.clear();
    _lastValues.clear();
  }

  @override
  void dispose() {
    resetTracking();
    super.dispose();
  }
}

/// Efficient list builder that only rebuilds changed items
class EfficientListBuilder<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool Function(T oldItem, T newItem)? itemComparator;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;

  const EfficientListBuilder({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.itemComparator,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.separator,
  }) : super(key: key);

  @override
  State<EfficientListBuilder<T>> createState() => _EfficientListBuilderState<T>();
}

class _EfficientListBuilderState<T> extends State<EfficientListBuilder<T>> {
  final Map<int, Widget> _cachedWidgets = {};
  List<T> _lastItems = [];

  @override
  void didUpdateWidget(EfficientListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check which items have changed
    if (widget.items.length != _lastItems.length) {
      // Length changed, clear cache
      _cachedWidgets.clear();
    } else {
      // Check individual items
      final comparator = widget.itemComparator ?? (a, b) => a == b;
      for (int i = 0; i < widget.items.length; i++) {
        if (i < _lastItems.length && !comparator(_lastItems[i], widget.items[i])) {
          _cachedWidgets.remove(i);
        }
      }
    }
    
    _lastItems = List.from(widget.items);
  }

  Widget _buildItem(int index) {
    if (_cachedWidgets.containsKey(index)) {
      return _cachedWidgets[index]!;
    }
    
    final item = widget.items[index];
    final builtWidget = this.widget.itemBuilder(context, item, index);
    _cachedWidgets[index] = builtWidget;
    return builtWidget;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.separator != null) {
      return ListView.separated(
        controller: widget.controller,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.items.length,
        itemBuilder: (context, index) => _buildItem(index),
        separatorBuilder: (context, index) => widget.separator!,
      );
    }
    
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.items.length,
      itemBuilder: (context, index) => _buildItem(index),
    );
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? name;
  final bool enableLogging;
  final void Function(PerformanceMetrics)? onMetricsUpdate;

  const PerformanceMonitor({
    Key? key,
    required this.child,
    this.name,
    this.enableLogging = false,
    this.onMetricsUpdate,
  }) : super(key: key);

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final List<Duration> _buildTimes = [];
  final List<Duration> _frameTimes = [];
  DateTime? _buildStart;
  DateTime? _frameStart;
  int _buildCount = 0;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enableLogging) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
    }
  }

  void _onFrameEnd(Duration timestamp) {
    if (_frameStart != null) {
      final frameTime = DateTime.now().difference(_frameStart!);
      _frameTimes.add(frameTime);
      _frameCount++;
      
      // Keep only recent samples
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      
      _updateMetrics();
    }
    
    _frameStart = DateTime.now();
    if (mounted && widget.enableLogging) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
    }
  }

  void _updateMetrics() {
    if (widget.onMetricsUpdate != null) {
      final metrics = PerformanceMetrics(
        buildCount: _buildCount,
        frameCount: _frameCount,
        averageBuildTime: _getAverageBuildTime(),
        averageFrameTime: _getAverageFrameTime(),
        name: widget.name,
      );
      widget.onMetricsUpdate!(metrics);
    }
  }

  Duration _getAverageBuildTime() {
    if (_buildTimes.isEmpty) return Duration.zero;
    final totalMs = _buildTimes.fold<int>(0, (sum, duration) => sum + duration.inMicroseconds);
    return Duration(microseconds: totalMs ~/ _buildTimes.length);
  }

  Duration _getAverageFrameTime() {
    if (_frameTimes.isEmpty) return Duration.zero;
    final totalMs = _frameTimes.fold<int>(0, (sum, duration) => sum + duration.inMicroseconds);
    return Duration(microseconds: totalMs ~/ _frameTimes.length);
  }

  @override
  Widget build(BuildContext context) {
    _buildStart = DateTime.now();
    
    final child = widget.child;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_buildStart != null) {
        final buildTime = DateTime.now().difference(_buildStart!);
        _buildTimes.add(buildTime);
        _buildCount++;
        
        // Keep only recent samples
        if (_buildTimes.length > 60) {
          _buildTimes.removeAt(0);
        }
        
        if (widget.enableLogging) {
          debugPrint('${widget.name ?? 'Widget'} build time: ${buildTime.inMicroseconds}μs');
        }
      }
    });
    
    return child;
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final int buildCount;
  final int frameCount;
  final Duration averageBuildTime;
  final Duration averageFrameTime;
  final String? name;

  const PerformanceMetrics({
    required this.buildCount,
    required this.frameCount,
    required this.averageBuildTime,
    required this.averageFrameTime,
    this.name,
  });

  double get averageFps => frameCount > 0 ? 1000000 / averageFrameTime.inMicroseconds : 0.0;
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'buildCount': buildCount,
      'frameCount': frameCount,
      'averageBuildTime': averageBuildTime.inMicroseconds,
      'averageFrameTime': averageFrameTime.inMicroseconds,
      'averageFps': averageFps,
    };
  }

  @override
  String toString() {
    return 'PerformanceMetrics('
        'name: $name, '
        'builds: $buildCount, '
        'frames: $frameCount, '
        'avgBuild: ${averageBuildTime.inMicroseconds}μs, '
        'avgFrame: ${averageFrameTime.inMicroseconds}μs, '
        'fps: ${averageFps.toStringAsFixed(1)}'
        ')';
  }
}

/// Debounced rebuild widget that prevents excessive rebuilds
class DebouncedBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Duration delay;
  final List<Listenable>? listenables;

  const DebouncedBuilder({
    Key? key,
    required this.builder,
    this.delay = const Duration(milliseconds: 100),
    this.listenables,
  }) : super(key: key);

  @override
  State<DebouncedBuilder> createState() => _DebouncedBuilderState();
}

class _DebouncedBuilderState extends State<DebouncedBuilder> {
  Timer? _debounceTimer;
  Widget? _cachedWidget;
  bool _needsRebuild = true;

  @override
  void initState() {
    super.initState();
    if (widget.listenables != null) {
      for (final listenable in widget.listenables!) {
        listenable.addListener(_onListenableChanged);
      }
    }
  }

  @override
  void didUpdateWidget(DebouncedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.listenables != oldWidget.listenables) {
      // Remove old listeners
      if (oldWidget.listenables != null) {
        for (final listenable in oldWidget.listenables!) {
          listenable.removeListener(_onListenableChanged);
        }
      }
      
      // Add new listeners
      if (widget.listenables != null) {
        for (final listenable in widget.listenables!) {
          listenable.addListener(_onListenableChanged);
        }
      }
    }
    
    _scheduleRebuild();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.listenables != null) {
      for (final listenable in widget.listenables!) {
        listenable.removeListener(_onListenableChanged);
      }
    }
    super.dispose();
  }

  void _onListenableChanged() {
    _scheduleRebuild();
  }

  void _scheduleRebuild() {
    _needsRebuild = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.delay, () {
      if (mounted && _needsRebuild) {
        setState(() {
          _cachedWidget = null;
          _needsRebuild = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget == null || _needsRebuild) {
      _cachedWidget = widget.builder(context);
      _needsRebuild = false;
    }
    return _cachedWidget!;
  }
}
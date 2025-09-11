import 'package:flutter/material.dart';

/// A virtual list view widget for performance testing
/// This is a simplified implementation for testing purposes
class VirtualListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemExtent;
  final double? itemHeight; // Add itemHeight parameter expected by tests
  final bool enableCaching; // Add enableCaching parameter expected by tests
  final ScrollController? controller;

  const VirtualListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.itemExtent = 50.0,
    this.itemHeight,
    this.enableCaching = false,
    this.controller,
  }) : super(key: key);

  @override
  State<VirtualListView<T>> createState() => _VirtualListViewState<T>();
}

class _VirtualListViewState<T> extends State<VirtualListView<T>> {
  late ScrollController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveItemExtent = widget.itemHeight ?? widget.itemExtent;
    return ListView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      itemExtent: effectiveItemExtent,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const SizedBox.shrink();
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}

/// Metrics for virtual list view performance testing
class VirtualListViewMetrics {
  final int totalItems;
  final int visibleItems;
  final int? cachedItems;
  final double? scrollOffset;
  final double memoryUsage;
  final Duration renderTime;

  VirtualListViewMetrics({
    required this.totalItems,
    required this.visibleItems,
    this.cachedItems,
    this.scrollOffset,
    required this.memoryUsage,
    required this.renderTime,
  });

  double get visibilityRatio => visibleItems / totalItems;

  @override
  String toString() {
    final percentage = (visibilityRatio * 100).toStringAsFixed(1);
    return 'VirtualListViewMetrics(totalItems: $totalItems, visibleItems: $visibleItems, visibilityRatio: $percentage%)';
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/mobile_platform_service.dart';

/// Mobile-specific touch gesture widgets and handlers
class MobileTouchGestures {
  static const double _defaultSwipeThreshold = 0.3;
  static const Duration _defaultLongPressDelay = Duration(milliseconds: 500);
  static const Duration _defaultDoubleTapDelay = Duration(milliseconds: 300);

  /// Create a swipe-to-delete gesture detector
  static Widget swipeToDelete({
    required Widget child,
    required VoidCallback onDelete,
    Color? deleteColor,
    IconData? deleteIcon,
    String? deleteLabel,
    double threshold = _defaultSwipeThreshold,
    bool enableHapticFeedback = true,
  }) {
    return _SwipeToDeleteWidget(
      onDelete: onDelete,
      deleteColor: deleteColor ?? Colors.red,
      deleteIcon: deleteIcon ?? Icons.delete,
      deleteLabel: deleteLabel ?? 'Delete',
      threshold: threshold,
      enableHapticFeedback: enableHapticFeedback,
      child: child,
    );
  }

  /// Create a swipe-to-action gesture detector
  static Widget swipeToAction({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Widget? leftAction,
    Widget? rightAction,
    double threshold = _defaultSwipeThreshold,
    bool enableHapticFeedback = true,
  }) {
    return _SwipeToActionWidget(
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      leftAction: leftAction,
      rightAction: rightAction,
      threshold: threshold,
      enableHapticFeedback: enableHapticFeedback,
      child: child,
    );
  }

  /// Create a long press gesture detector with haptic feedback
  static Widget longPressAction({
    required Widget child,
    required VoidCallback onLongPress,
    Duration delay = _defaultLongPressDelay,
    bool enableHapticFeedback = true,
    HapticFeedbackType hapticType = HapticFeedbackType.medium,
  }) {
    return _LongPressActionWidget(
      onLongPress: onLongPress,
      delay: delay,
      enableHapticFeedback: enableHapticFeedback,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Create a double tap gesture detector
  static Widget doubleTapAction({
    required Widget child,
    required VoidCallback onDoubleTap,
    Duration timeout = _defaultDoubleTapDelay,
    bool enableHapticFeedback = true,
    HapticFeedbackType hapticType = HapticFeedbackType.selection,
  }) {
    return _DoubleTapActionWidget(
      onDoubleTap: onDoubleTap,
      timeout: timeout,
      enableHapticFeedback: enableHapticFeedback,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Create a pinch-to-zoom gesture detector
  static Widget pinchToZoom({
    required Widget child,
    double minScale = 0.5,
    double maxScale = 3.0,
    bool enableHapticFeedback = true,
  }) {
    return _PinchToZoomWidget(
      minScale: minScale,
      maxScale: maxScale,
      enableHapticFeedback: enableHapticFeedback,
      child: child,
    );
  }

  /// Create a pull-to-refresh gesture detector
  static Widget pullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
    Color? backgroundColor,
    double displacement = 40.0,
    bool enableHapticFeedback = true,
  }) {
    return _PullToRefreshWidget(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      displacement: displacement,
      enableHapticFeedback: enableHapticFeedback,
      child: child,
    );
  }

  /// Trigger haptic feedback if enabled and supported
  static Future<void> triggerHapticFeedback(
    HapticFeedbackType type, {
    bool enabled = true,
  }) async {
    if (enabled && MobilePlatformService.isHapticFeedbackSupported) {
      await MobilePlatformService.triggerHapticFeedback(type);
    }
  }
}

/// Swipe-to-delete widget implementation
class _SwipeToDeleteWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final Color deleteColor;
  final IconData deleteIcon;
  final String deleteLabel;
  final double threshold;
  final bool enableHapticFeedback;

  const _SwipeToDeleteWidget({
    required this.child,
    required this.onDelete,
    required this.deleteColor,
    required this.deleteIcon,
    required this.deleteLabel,
    required this.threshold,
    required this.enableHapticFeedback,
  });

  @override
  State<_SwipeToDeleteWidget> createState() => _SwipeToDeleteWidgetState();
}

class _SwipeToDeleteWidgetState extends State<_SwipeToDeleteWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final delta = details.delta.dx;
        if (delta < 0) {
          // Swiping left
          final progress = (-delta / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
          _controller.value = progress;

          if (progress > widget.threshold && !_hasTriggeredHaptic) {
            _hasTriggeredHaptic = true;
            MobileTouchGestures.triggerHapticFeedback(
              HapticFeedbackType.medium,
              enabled: widget.enableHapticFeedback,
            );
          }
        }
      },
      onPanEnd: (details) {
        if (_controller.value > widget.threshold) {
          // Complete the delete action
          _controller.forward().then((_) {
            widget.onDelete();
          });
        } else {
          // Reset to original position
          _controller.reverse();
        }
        _hasTriggeredHaptic = false;
      },
      child: Stack(
        children: [
          // Delete background
          Positioned.fill(
            child: Container(
              color: widget.deleteColor,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controller.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.deleteIcon,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.deleteLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Main content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value * MediaQuery.of(context).size.width,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Swipe-to-action widget implementation
class _SwipeToActionWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftAction;
  final Widget? rightAction;
  final double threshold;
  final bool enableHapticFeedback;

  const _SwipeToActionWidget({
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftAction,
    this.rightAction,
    required this.threshold,
    required this.enableHapticFeedback,
  });

  @override
  State<_SwipeToActionWidget> createState() => _SwipeToActionWidgetState();
}

class _SwipeToActionWidgetState extends State<_SwipeToActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragPosition = 0.0;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta.dx;
          _dragPosition = _dragPosition.clamp(-200.0, 200.0);
        });

        final progress = (_dragPosition.abs() / 200.0).clamp(0.0, 1.0);
        if (progress > widget.threshold && !_hasTriggeredHaptic) {
          _hasTriggeredHaptic = true;
          MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.light,
            enabled: widget.enableHapticFeedback,
          );
        }
      },
      onPanEnd: (details) {
        final progress = (_dragPosition.abs() / 200.0).clamp(0.0, 1.0);
        
        if (progress > widget.threshold) {
          if (_dragPosition < 0 && widget.onSwipeLeft != null) {
            widget.onSwipeLeft!();
          } else if (_dragPosition > 0 && widget.onSwipeRight != null) {
            widget.onSwipeRight!();
          }
        }

        setState(() {
          _dragPosition = 0.0;
        });
        _hasTriggeredHaptic = false;
      },
      child: Stack(
        children: [
          // Left action
          if (widget.leftAction != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  opacity: _dragPosition > 0 ? (_dragPosition / 200.0).clamp(0.0, 1.0) : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: widget.leftAction!,
                ),
              ),
            ),
          // Right action
          if (widget.rightAction != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _dragPosition < 0 ? (-_dragPosition / 200.0).clamp(0.0, 1.0) : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: widget.rightAction!,
                ),
              ),
            ),
          // Main content
          Transform.translate(
            offset: Offset(_dragPosition, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Long press action widget implementation
class _LongPressActionWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration delay;
  final bool enableHapticFeedback;
  final HapticFeedbackType hapticType;

  const _LongPressActionWidget({
    required this.child,
    required this.onLongPress,
    required this.delay,
    required this.enableHapticFeedback,
    required this.hapticType,
  });

  @override
  State<_LongPressActionWidget> createState() => _LongPressActionWidgetState();
}

class _LongPressActionWidgetState extends State<_LongPressActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.delay,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _controller.forward();
      },
      onLongPressEnd: (details) {
        _controller.reverse();
        MobileTouchGestures.triggerHapticFeedback(
          widget.hapticType,
          enabled: widget.enableHapticFeedback,
        );
        widget.onLongPress();
      },
      onLongPressCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Double tap action widget implementation
class _DoubleTapActionWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;
  final Duration timeout;
  final bool enableHapticFeedback;
  final HapticFeedbackType hapticType;

  const _DoubleTapActionWidget({
    required this.child,
    required this.onDoubleTap,
    required this.timeout,
    required this.enableHapticFeedback,
    required this.hapticType,
  });

  @override
  State<_DoubleTapActionWidget> createState() => _DoubleTapActionWidgetState();
}

class _DoubleTapActionWidgetState extends State<_DoubleTapActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        _controller.forward().then((_) {
          _controller.reverse();
        });
        MobileTouchGestures.triggerHapticFeedback(
          widget.hapticType,
          enabled: widget.enableHapticFeedback,
        );
        widget.onDoubleTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Pinch-to-zoom widget implementation
class _PinchToZoomWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final bool enableHapticFeedback;

  const _PinchToZoomWidget({
    required this.child,
    required this.minScale,
    required this.maxScale,
    required this.enableHapticFeedback,
  });

  @override
  State<_PinchToZoomWidget> createState() => _PinchToZoomWidgetState();
}

class _PinchToZoomWidgetState extends State<_PinchToZoomWidget> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  bool _hasTriggeredMinHaptic = false;
  bool _hasTriggeredMaxHaptic = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
        _hasTriggeredMinHaptic = false;
        _hasTriggeredMaxHaptic = false;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_previousScale * details.scale).clamp(widget.minScale, widget.maxScale);
        });

        // Trigger haptic feedback at boundaries
        if (_scale <= widget.minScale && !_hasTriggeredMinHaptic) {
          _hasTriggeredMinHaptic = true;
          MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.light,
            enabled: widget.enableHapticFeedback,
          );
        } else if (_scale >= widget.maxScale && !_hasTriggeredMaxHaptic) {
          _hasTriggeredMaxHaptic = true;
          MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.light,
            enabled: widget.enableHapticFeedback,
          );
        }
      },
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Pull-to-refresh widget implementation
class _PullToRefreshWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final bool enableHapticFeedback;

  const _PullToRefreshWidget({
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    required this.displacement,
    required this.enableHapticFeedback,
  });

  @override
  State<_PullToRefreshWidget> createState() => _PullToRefreshWidgetState();
}

class _PullToRefreshWidgetState extends State<_PullToRefreshWidget> {
  bool _hasTriggeredHaptic = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.enableHapticFeedback && !_hasTriggeredHaptic) {
          _hasTriggeredHaptic = true;
          await MobileTouchGestures.triggerHapticFeedback(HapticFeedbackType.light);
          // Reset haptic flag after a delay
          Future.delayed(const Duration(seconds: 1), () {
            _hasTriggeredHaptic = false;
          });
        }
        return widget.onRefresh();
      },
      color: widget.color,
      backgroundColor: widget.backgroundColor,
      displacement: widget.displacement,
      child: widget.child,
    );
  }
}

/// Mobile touch target size helper
class MobileTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? minSize;
  final EdgeInsets? padding;

  const MobileTouchTarget({
    Key? key,
    required this.child,
    this.onTap,
    this.minSize,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = MobilePlatformService.getMobileConfiguration();
    final targetSize = minSize ?? config.minimumTouchTargetSize;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: targetSize,
          minHeight: targetSize,
        ),
        padding: padding ?? const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}

/// Mobile-optimized button with proper touch targets
class MobileButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool enableHapticFeedback;

  const MobileButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = MobilePlatformService.getMobileConfiguration();
    
    Widget button = isPrimary
        ? ElevatedButton.icon(
            onPressed: onPressed != null
                ? () {
                    MobileTouchGestures.triggerHapticFeedback(
                      HapticFeedbackType.light,
                      enabled: enableHapticFeedback,
                    );
                    onPressed!();
                  }
                : null,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(text),
          )
        : OutlinedButton.icon(
            onPressed: onPressed != null
                ? () {
                    MobileTouchGestures.triggerHapticFeedback(
                      HapticFeedbackType.light,
                      enabled: enableHapticFeedback,
                    );
                    onPressed!();
                  }
                : null,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(text),
          );

    return Container(
      constraints: BoxConstraints(
        minHeight: config.minimumTouchTargetSize,
      ),
      child: button,
    );
  }
}
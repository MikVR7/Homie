import 'package:flutter/material.dart';
import 'material_motion.dart';

/// Skeleton loading animations for better user experience during data loading
class SkeletonLoading extends StatefulWidget {
  const SkeletonLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.direction = SkeletonDirection.ltr,
  }) : super(key: key);

  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;
  final SkeletonDirection direction;

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.period,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MaterialMotion.linear,
    ));

    if (widget.isLoading) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(SkeletonLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    _controller.repeat();
  }

  void _stopAnimation() {
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? 
        theme.colorScheme.surface.withOpacity(0.1);
    final highlightColor = widget.highlightColor ?? 
        theme.colorScheme.surface.withOpacity(0.3);

    if (!widget.isLoading) {
      return MaterialMotion.fadeTransition(
        animation: const AlwaysStoppedAnimation(1.0),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: _getGradientBegin(),
              end: _getGradientEnd(),
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }

  Alignment _getGradientBegin() {
    switch (widget.direction) {
      case SkeletonDirection.ltr:
        return Alignment.centerLeft;
      case SkeletonDirection.rtl:
        return Alignment.centerRight;
      case SkeletonDirection.ttb:
        return Alignment.topCenter;
      case SkeletonDirection.btt:
        return Alignment.bottomCenter;
    }
  }

  Alignment _getGradientEnd() {
    switch (widget.direction) {
      case SkeletonDirection.ltr:
        return Alignment.centerRight;
      case SkeletonDirection.rtl:
        return Alignment.centerLeft;
      case SkeletonDirection.ttb:
        return Alignment.bottomCenter;
      case SkeletonDirection.btt:
        return Alignment.topCenter;
    }
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

enum SkeletonDirection {
  ltr, // Left to right
  rtl, // Right to left
  ttb, // Top to bottom
  btt, // Bottom to top
}

/// Pre-built skeleton widgets for common use cases
class SkeletonWidgets {
  /// Skeleton for text lines
  static Widget text({
    Key? key,
    bool isLoading = true,
    double height = 16.0,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Skeleton for avatars/circular images
  static Widget avatar({
    Key? key,
    bool isLoading = true,
    double radius = 20.0,
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  /// Skeleton for rectangular images
  static Widget image({
    Key? key,
    bool isLoading = true,
    double width = 100.0,
    double height = 100.0,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Skeleton for cards
  static Widget card({
    Key? key,
    bool isLoading = true,
    double height = 200.0,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Card(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton for list items
  static Widget listItem({
    Key? key,
    bool isLoading = true,
    bool hasAvatar = true,
    bool hasSubtitle = true,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (hasAvatar) ...[
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for file browser items
  static Widget fileBrowserItem({
    Key? key,
    bool isLoading = true,
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // File icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for organization preview
  static Widget organizationPreview({
    Key? key,
    bool isLoading = true,
    int itemCount = 3,
  }) {
    return SkeletonLoading(
      key: key,
      isLoading: isLoading,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // Items
              ...List.generate(itemCount, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

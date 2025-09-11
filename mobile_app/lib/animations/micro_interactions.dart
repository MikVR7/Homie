import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'material_motion.dart';

/// Micro-interactions for enhanced user feedback following Material Design 3
class MicroInteractions {
  /// Button with press animation and haptic feedback
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = MaterialMotion.extraShort,
    double pressedScale = 0.95,
    bool hapticFeedback = true,
    Color? splashColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) {
    return _AnimatedButton(
      onPressed: onPressed,
      duration: duration,
      pressedScale: pressedScale,
      hapticFeedback: hapticFeedback,
      splashColor: splashColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Card with hover and press animations
  static Widget animatedCard({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = MaterialMotion.short2,
    double hoverScale = 1.02,
    double pressedScale = 0.98,
    double elevation = 2.0,
    double hoverElevation = 4.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    Color? shadowColor,
  }) {
    return _AnimatedCard(
      onTap: onTap,
      duration: duration,
      hoverScale: hoverScale,
      pressedScale: pressedScale,
      elevation: elevation,
      hoverElevation: hoverElevation,
      borderRadius: borderRadius,
      shadowColor: shadowColor,
      child: child,
    );
  }

  /// Icon with rotation animation
  static Widget rotatingIcon({
    required IconData icon,
    required bool isRotated,
    Duration duration = MaterialMotion.short3,
    double size = 24.0,
    Color? color,
  }) {
    return AnimatedRotation(
      turns: isRotated ? 0.5 : 0.0,
      duration: duration,
      curve: MaterialMotion.emphasized,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  /// Expandable widget with smooth animation
  static Widget expandable({
    required Widget child,
    required bool isExpanded,
    Duration duration = MaterialMotion.medium1,
    Axis axis = Axis.vertical,
  }) {
    return AnimatedSize(
      duration: duration,
      curve: MaterialMotion.emphasized,
      child: AnimatedContainer(
        duration: duration,
        curve: MaterialMotion.emphasized,
        height: axis == Axis.vertical ? (isExpanded ? null : 0) : null,
        width: axis == Axis.horizontal ? (isExpanded ? null : 0) : null,
        child: isExpanded ? child : const SizedBox.shrink(),
      ),
    );
  }

  /// Progress indicator with smooth animation
  static Widget animatedProgress({
    required double value,
    Duration duration = MaterialMotion.short4,
    Color? backgroundColor,
    Color? valueColor,
    double height = 4.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(2)),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: MaterialMotion.emphasized,
      tween: Tween(begin: 0.0, end: value),
      builder: (context, animatedValue, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                color: valueColor ?? Theme.of(context).primaryColor,
                borderRadius: borderRadius,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pulsing widget for attention
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
    bool enabled = true,
  }) {
    if (!enabled) return child;

    return _PulsingWidget(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  /// Shimmer effect for loading states
  static Widget shimmer({
    required Widget child,
    bool enabled = true,
    Duration period = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    if (!enabled) return child;

    return _ShimmerWidget(
      period: period,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double size = 48.0,
    Color color = Colors.green,
    Duration duration = MaterialMotion.medium2,
  }) {
    return _SuccessCheckmark(
      size: size,
      color: color,
      duration: duration,
    );
  }

  /// Error shake animation
  static Widget errorShake({
    required Widget child,
    bool enabled = false,
    Duration duration = MaterialMotion.short4,
  }) {
    return _ShakeWidget(
      enabled: enabled,
      duration: duration,
      child: child,
    );
  }

  /// Ripple animation for custom areas
  static Widget ripple({
    required Widget child,
    required VoidCallback onTap,
    Color? splashColor,
    Color? highlightColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: splashColor,
        highlightColor: highlightColor,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// Floating action button with bounce
  static Widget bouncingFAB({
    required VoidCallback onPressed,
    required Widget child,
    Duration duration = MaterialMotion.short3,
    double bounceScale = 1.2,
  }) {
    return _BouncingFAB(
      onPressed: onPressed,
      duration: duration,
      bounceScale: bounceScale,
      child: child,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.pressedScale,
    required this.hapticFeedback,
    this.splashColor,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double pressedScale;
  final bool hapticFeedback;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MaterialMotion.emphasized,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {}, // Handled by GestureDetector
                splashColor: widget.splashColor,
                borderRadius: widget.borderRadius,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({
    required this.child,
    required this.onTap,
    required this.duration,
    required this.hoverScale,
    required this.pressedScale,
    required this.elevation,
    required this.hoverElevation,
    this.borderRadius,
    this.shadowColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double hoverScale;
  final double pressedScale;
  final double elevation;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final Color? shadowColor;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _currentScale {
    if (_isPressed) return widget.pressedScale;
    if (_isHovered) return widget.hoverScale;
    return 1.0;
  }

  double get _currentElevation {
    if (_isHovered) return widget.hoverElevation;
    return widget.elevation;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: MaterialMotion.emphasized,
          transform: Matrix4.identity()..scale(_currentScale),
          child: Card(
            elevation: _currentElevation,
            shadowColor: widget.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _PulsingWidget extends StatefulWidget {
  const _PulsingWidget({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  const _ShimmerWidget({
    required this.child,
    required this.period,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Duration period;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.period,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor ?? theme.colorScheme.surface.withOpacity(0.1),
                widget.highlightColor ?? theme.colorScheme.surface.withOpacity(0.3),
                widget.baseColor ?? theme.colorScheme.surface.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
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

class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark({
    required this.size,
    required this.color,
    required this.duration,
  });

  final double size;
  final Color color;
  final Duration duration;

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: MaterialMotion.emphasized),
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: MaterialMotion.emphasized),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              circleAnimation: _circleAnimation,
              checkAnimation: _checkAnimation,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.circleAnimation,
    required this.checkAnimation,
    required this.color,
  });

  final Animation<double> circleAnimation;
  final Animation<double> checkAnimation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (3.14159 / 180),
      360 * (3.14159 / 180) * circleAnimation.value,
      false,
      paint,
    );

    // Draw checkmark
    if (checkAnimation.value > 0) {
      final checkPath = Path();
      final checkStart = Offset(size.width * 0.3, size.height * 0.5);
      final checkMiddle = Offset(size.width * 0.45, size.height * 0.65);
      final checkEnd = Offset(size.width * 0.7, size.height * 0.35);

      checkPath.moveTo(checkStart.dx, checkStart.dy);
      
      if (checkAnimation.value <= 0.5) {
        final progress = checkAnimation.value * 2;
        final currentX = checkStart.dx + (checkMiddle.dx - checkStart.dx) * progress;
        final currentY = checkStart.dy + (checkMiddle.dy - checkStart.dy) * progress;
        checkPath.lineTo(currentX, currentY);
      } else {
        checkPath.lineTo(checkMiddle.dx, checkMiddle.dy);
        final progress = (checkAnimation.value - 0.5) * 2;
        final currentX = checkMiddle.dx + (checkEnd.dx - checkMiddle.dx) * progress;
        final currentY = checkMiddle.dy + (checkEnd.dy - checkMiddle.dy) * progress;
        checkPath.lineTo(currentX, currentY);
      }

      canvas.drawPath(checkPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ShakeWidget extends StatefulWidget {
  const _ShakeWidget({
    required this.child,
    required this.enabled,
    required this.duration,
  });

  final Widget child;
  final bool enabled;
  final Duration duration;

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.forward().then((_) => _controller.reset());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue = math.sin(4 * math.pi * _animation.value) * 2;
        return Transform.translate(
          offset: Offset(sineValue, 0.0),
          child: widget.child,
        );
      },
    );
  }
}

class _BouncingFAB extends StatefulWidget {
  const _BouncingFAB({
    required this.onPressed,
    required this.child,
    required this.duration,
    required this.bounceScale,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;
  final double bounceScale;

  @override
  State<_BouncingFAB> createState() => _BouncingFABState();
}

class _BouncingFABState extends State<_BouncingFAB>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.bounceScale,
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

  void _onPressed() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: FloatingActionButton(
            onPressed: _onPressed,
            child: widget.child,
          ),
        );
      },
    );
  }
}

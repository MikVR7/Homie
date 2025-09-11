import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Material Design 3 motion system implementation
/// Provides standardized animations and transitions following Material Design 3 guidelines
class MaterialMotion {
  // Motion easing curves based on Material Design 3
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve decelerated = Curves.easeOut;
  static const Curve accelerated = Curves.easeIn;
  static const Curve linear = Curves.linear;

  // Motion durations based on Material Design 3
  static const Duration extraShort = Duration(milliseconds: 50);
  static const Duration short1 = Duration(milliseconds: 100);
  static const Duration short2 = Duration(milliseconds: 150);
  static const Duration short3 = Duration(milliseconds: 200);
  static const Duration short4 = Duration(milliseconds: 250);
  static const Duration medium1 = Duration(milliseconds: 300);
  static const Duration medium2 = Duration(milliseconds: 350);
  static const Duration medium3 = Duration(milliseconds: 400);
  static const Duration medium4 = Duration(milliseconds: 450);
  static const Duration long1 = Duration(milliseconds: 500);
  static const Duration long2 = Duration(milliseconds: 600);
  static const Duration long3 = Duration(milliseconds: 700);
  static const Duration long4 = Duration(milliseconds: 800);
  static const Duration extraLong1 = Duration(milliseconds: 900);
  static const Duration extraLong2 = Duration(milliseconds: 1000);
  static const Duration extraLong3 = Duration(milliseconds: 1100);
  static const Duration extraLong4 = Duration(milliseconds: 1200);

  /// Standard fade transition
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = medium1,
    Curve curve = standard,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }

  /// Standard slide transition
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Duration duration = medium2,
    Curve curve = emphasized,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }

  /// Scale transition for emphasis
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.8,
    double end = 1.0,
    Duration duration = short4,
    Curve curve = emphasized,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      alignment: alignment,
      child: child,
    );
  }

  /// Shared axis transition (for navigation)
  static Widget sharedAxisTransition({
    required Widget child,
    required Animation<double> animation,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
    Duration duration = medium2,
  }) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: const AlwaysStoppedAnimation(0.0),
      transitionType: _convertTransitionType(transitionType),
      child: child,
    );
  }

  static SharedAxisTransitionType _convertTransitionType(SharedAxisTransitionType type) {
    switch (type) {
      case SharedAxisTransitionType.horizontal:
        return SharedAxisTransitionType.horizontal;
      case SharedAxisTransitionType.vertical:
        return SharedAxisTransitionType.vertical;
      case SharedAxisTransitionType.scaled:
        return SharedAxisTransitionType.scaled;
    }
  }

  /// Container transform (for hero-like transitions)
  static Widget containerTransform({
    required Widget Function(BuildContext, VoidCallback) closedBuilder,
    required Widget Function(BuildContext, VoidCallback) openBuilder,
    Duration duration = long1,
    Curve curve = emphasized,
  }) {
    return OpenContainer(
      transitionDuration: duration,
      transitionType: ContainerTransitionType.fade,
      closedBuilder: closedBuilder,
      openBuilder: openBuilder,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  /// Staggered list animation
  static Widget staggeredListAnimation({
    required Widget child,
    required int index,
    required Animation<double> animation,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = medium3,
    Curve curve = emphasized,
  }) {
    final itemDelay = delay.inMilliseconds * index;
    final totalDuration = duration.inMilliseconds + itemDelay;
    
    final delayedAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(
        itemDelay / totalDuration,
        1.0,
        curve: curve,
      ),
    ));

    return FadeTransition(
      opacity: delayedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.2),
          end: Offset.zero,
        ).animate(delayedAnimation),
        child: child,
      ),
    );
  }

  /// Ripple effect animation
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color? splashColor,
    Color? highlightColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
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

  /// Loading animation with pulsing effect
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1200),
    double minOpacity = 0.3,
    double maxOpacity = 1.0,
  }) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0.0),
      builder: (context, _) {
        return TweenAnimationBuilder<double>(
          duration: duration,
          tween: Tween(begin: minOpacity, end: maxOpacity),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// Micro-interaction for buttons
  static Widget buttonPress({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = extraShort,
    double pressedScale = 0.95,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTapDown: (_) {
              // Scale down on press
            },
            onTapUp: (_) {
              onPressed();
              // Scale back up
            },
            onTapCancel: () {
              // Scale back up on cancel
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// Use SharedAxisTransitionType from animations package
// The enum and classes are provided by the animations package

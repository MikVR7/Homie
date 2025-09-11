import 'package:flutter/material.dart';
import 'material_motion.dart';

/// Custom page transitions following Material Design 3 principles
class PageTransitions {
  /// Shared axis horizontal transition (for forward navigation)
  static PageRouteBuilder sharedAxisHorizontal<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.medium2,
    bool reverse = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final offsetAnimation = Tween<Offset>(
          begin: reverse ? const Offset(-1.0, 0.0) : begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        final secondaryOffsetAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: reverse ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: MaterialMotion.emphasized,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: SlideTransition(
            position: secondaryOffsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis vertical transition (for modal/bottom sheets)
  static PageRouteBuilder sharedAxisVertical<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.medium2,
    bool reverse = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final offsetAnimation = Tween<Offset>(
          begin: reverse ? const Offset(0.0, -1.0) : begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Fade through transition (for tab switches)
  static PageRouteBuilder fadeThrough<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.short4,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeInAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1.0, curve: MaterialMotion.decelerated),
        ));

        final fadeOutAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.35, curve: MaterialMotion.accelerated),
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        return FadeTransition(
          opacity: fadeInAnimation,
          child: FadeTransition(
            opacity: fadeOutAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Container transform transition (for cards to detail views)
  static PageRouteBuilder containerTransform<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.long1,
    Color? backgroundColor,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: backgroundColor ?? Colors.black.withOpacity(0.5),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        );

        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Scale transition (for dialogs and overlays)
  static PageRouteBuilder scale<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.short4,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.standard,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            alignment: alignment,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide up transition (for bottom sheets)
  static PageRouteBuilder slideUp<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.medium2,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final offsetAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MaterialMotion.emphasized,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Custom curve transition
  static PageRouteBuilder customCurve<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = MaterialMotion.medium2,
    Curve curve = MaterialMotion.emphasized,
    PageTransitionType type = PageTransitionType.fade,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        switch (type) {
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: curvedAnimation,
              child: child,
            );
          case PageTransitionType.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          case PageTransitionType.slideLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          case PageTransitionType.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          case PageTransitionType.slideDown:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
        }
      },
    );
  }
}

enum PageTransitionType {
  fade,
  scale,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
}

/// Extension for Navigator to use custom transitions
extension NavigatorTransitions on NavigatorState {
  /// Push with shared axis horizontal transition
  Future<T?> pushSharedAxisHorizontal<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return push<T>(PageTransitions.sharedAxisHorizontal<T>(
      page: page,
      settings: settings,
    ) as Route<T>);
  }

  /// Push with fade through transition
  Future<T?> pushFadeThrough<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return push<T>(PageTransitions.fadeThrough<T>(
      page: page,
      settings: settings,
    ) as Route<T>);
  }

  /// Push with container transform
  Future<T?> pushContainerTransform<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Color? backgroundColor,
  }) {
    return push<T>(PageTransitions.containerTransform<T>(
      page: page,
      settings: settings,
      backgroundColor: backgroundColor,
    ) as Route<T>);
  }

  /// Push with scale transition
  Future<T?> pushScale<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Alignment alignment = Alignment.center,
  }) {
    return push<T>(PageTransitions.scale<T>(
      page: page,
      settings: settings,
      alignment: alignment,
    ) as Route<T>);
  }

  /// Push with slide up transition
  Future<T?> pushSlideUp<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return push<T>(PageTransitions.slideUp<T>(
      page: page,
      settings: settings,
    ) as Route<T>);
  }
}

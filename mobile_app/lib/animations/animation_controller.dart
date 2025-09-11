import 'package:flutter/material.dart';
import 'material_motion.dart';
import 'skeleton_loading.dart';
import 'page_transitions.dart';
import 'micro_interactions.dart';

/// Central animation controller for managing all animations in the app
class AppAnimationController {
  static final AppAnimationController _instance = AppAnimationController._internal();
  factory AppAnimationController() => _instance;
  AppAnimationController._internal();

  bool _animationsEnabled = true;
  bool _reducedMotion = false;

  /// Whether animations are globally enabled
  bool get animationsEnabled => _animationsEnabled && !_reducedMotion;

  /// Enable or disable animations globally
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
  }

  /// Set reduced motion mode (for accessibility)
  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
  }

  /// Get appropriate duration based on current settings
  Duration getDuration(Duration duration) {
    if (!animationsEnabled) return Duration.zero;
    if (_reducedMotion) return Duration(milliseconds: duration.inMilliseconds ~/ 2);
    return duration;
  }

  /// Get appropriate curve based on current settings
  Curve getCurve(Curve curve) {
    if (!animationsEnabled || _reducedMotion) return Curves.linear;
    return curve;
  }
}

/// Widget builder for conditionally animated widgets
class AnimatedBuilder extends StatelessWidget {
  const AnimatedBuilder({
    Key? key,
    required this.builder,
    this.fallback,
  }) : super(key: key);

  final Widget Function(BuildContext context, bool animationsEnabled) builder;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final controller = AppAnimationController();
    if (!controller.animationsEnabled && fallback != null) {
      return fallback!;
    }
    return builder(context, controller.animationsEnabled);
  }
}

/// Enhanced Material App with animation controls
class AnimatedMaterialApp extends StatelessWidget {
  const AnimatedMaterialApp({
    Key? key,
    required this.home,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.navigatorKey,
    this.debugShowCheckedModeBanner = false,
  }) : super(key: key);

  final Widget home;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final Map<String, WidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: key,
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: home,
      routes: routes ?? {},
      initialRoute: initialRoute,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      onGenerateRoute: onGenerateRoute ?? _generateRoute,
      builder: (context, child) {
        // Initialize animation settings based on platform accessibility
        final mediaQuery = MediaQuery.of(context);
        final controller = AppAnimationController();
        
        // Check for reduced motion preference
        if (mediaQuery.disableAnimations) {
          controller.setReducedMotion(true);
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Default route generation with custom transitions
    if (onGenerateRoute != null) {
      return onGenerateRoute!(settings);
    }

    // Fallback to Material page route
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Route not found: ${settings.name}')),
        body: const Center(
          child: Text('Route not found'),
        ),
      ),
      settings: settings,
    );
  }
}

/// Animation presets for common use cases
class AnimationPresets {
  /// Quick fade in animation
  static Widget quickFadeIn({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: AppAnimationController().getDuration(MaterialMotion.short2),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: AppAnimationController().getCurve(MaterialMotion.decelerated),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered list items
  static Widget staggeredList({
    required List<Widget> children,
    Duration itemDelay = const Duration(milliseconds: 100),
    Duration itemDuration = MaterialMotion.short3,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          duration: AppAnimationController().getDuration(
            Duration(milliseconds: itemDuration.inMilliseconds + (itemDelay.inMilliseconds * index))
          ),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: AppAnimationController().getCurve(MaterialMotion.emphasized),
          builder: (context, value, child) {
            final delayedValue = ((value * children.length) - index).clamp(0.0, 1.0);
            return Opacity(
              opacity: delayedValue,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - delayedValue)),
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  /// Hero-like transition for images
  static Widget heroTransition({
    required String tag,
    required Widget child,
    Duration duration = MaterialMotion.medium2,
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AppAnimationController().getCurve(MaterialMotion.emphasized),
          )),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Loading state with skeleton
  static Widget loadingState({
    required Widget child,
    required bool isLoading,
    Widget? skeleton,
  }) {
    if (isLoading && skeleton != null) {
      return SkeletonLoading(
        isLoading: true,
        child: skeleton,
      );
    }

    return AnimatedSwitcher(
      duration: AppAnimationController().getDuration(MaterialMotion.short3),
      switchInCurve: AppAnimationController().getCurve(MaterialMotion.decelerated),
      switchOutCurve: AppAnimationController().getCurve(MaterialMotion.accelerated),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : child,
    );
  }

  /// Notification banner with slide animation
  static Widget notificationBanner({
    required Widget child,
    required bool visible,
    Duration duration = MaterialMotion.medium1,
  }) {
    return AnimatedSlide(
      duration: AppAnimationController().getDuration(duration),
      curve: AppAnimationController().getCurve(MaterialMotion.emphasized),
      offset: visible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: AppAnimationController().getDuration(duration),
        opacity: visible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }

  /// Button with loading state
  static Widget loadingButton({
    required Widget child,
    required VoidCallback? onPressed,
    required bool isLoading,
    Duration duration = MaterialMotion.short2,
  }) {
    return AnimatedContainer(
      duration: AppAnimationController().getDuration(duration),
      curve: AppAnimationController().getCurve(MaterialMotion.standard),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: AppAnimationController().getDuration(duration),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : child,
        ),
      ),
    );
  }

  /// Expandable section
  static Widget expandableSection({
    required Widget child,
    required bool isExpanded,
    required String title,
    Duration duration = MaterialMotion.medium1,
  }) {
    return Column(
      children: [
        MicroInteractions.animatedButton(
          onPressed: () {}, // Should be handled by parent
          child: Row(
            children: [
              Text(title),
              const Spacer(),
              MicroInteractions.rotatingIcon(
                icon: Icons.expand_more,
                isRotated: isExpanded,
              ),
            ],
          ),
        ),
        MicroInteractions.expandable(
          isExpanded: isExpanded,
          duration: AppAnimationController().getDuration(duration),
          child: child,
        ),
      ],
    );
  }

  /// Modal overlay with backdrop
  static Widget modalOverlay({
    required Widget child,
    required bool visible,
    VoidCallback? onDismiss,
    Duration duration = MaterialMotion.short4,
  }) {
    return AnimatedOpacity(
      duration: AppAnimationController().getDuration(duration),
      opacity: visible ? 1.0 : 0.0,
      child: visible
          ? GestureDetector(
              onTap: onDismiss,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent dismissal when tapping modal
                    child: AnimatedScale(
                      duration: AppAnimationController().getDuration(duration),
                      curve: AppAnimationController().getCurve(MaterialMotion.emphasized),
                      scale: visible ? 1.0 : 0.8,
                      child: child,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Navigation extensions with animations
extension AnimatedNavigation on NavigatorState {
  /// Push with automatic transition selection
  Future<T?> pushAnimated<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    PageTransitionType transitionType = PageTransitionType.slideRight,
  }) {
    if (!AppAnimationController().animationsEnabled) {
      return push<T>(MaterialPageRoute(
        builder: (context) => page,
        settings: settings,
      ));
    }

    switch (transitionType) {
      case PageTransitionType.fade:
        return pushFadeThrough<T>(page, settings: settings);
      case PageTransitionType.slideRight:
        return pushSharedAxisHorizontal<T>(page, settings: settings);
      case PageTransitionType.scale:
        return pushScale<T>(page, settings: settings);
      case PageTransitionType.slideUp:
        return pushSlideUp<T>(page, settings: settings);
      default:
        return pushSharedAxisHorizontal<T>(page, settings: settings);
    }
  }

  /// Push replacement with transition
  Future<T?> pushReplacementAnimated<T extends Object?, TO extends Object?>(
    Widget page, {
    RouteSettings? settings,
    TO? result,
    PageTransitionType transitionType = PageTransitionType.fade,
  }) {
    if (!AppAnimationController().animationsEnabled) {
      return pushReplacement<T, TO>(MaterialPageRoute(
        builder: (context) => page,
        settings: settings,
      ), result: result);
    }

    final route = PageTransitions.customCurve<T>(
      page: page,
      settings: settings,
      type: transitionType,
    );
    
    return pushReplacement<T, TO>(route as Route<T>, result: result);
  }
}

/// Performance monitoring for animations
class AnimationPerformanceMonitor {
  static final List<Duration> _animationDurations = [];
  static final List<String> _animationTypes = [];

  static void logAnimation(String type, Duration duration) {
    _animationTypes.add(type);
    _animationDurations.add(duration);
    
    // Keep only last 100 entries
    if (_animationTypes.length > 100) {
      _animationTypes.removeAt(0);
      _animationDurations.removeAt(0);
    }
  }

  static Map<String, dynamic> getPerformanceStats() {
    if (_animationDurations.isEmpty) {
      return {'message': 'No animation data available'};
    }

    final totalDuration = _animationDurations.reduce((a, b) => a + b);
    final averageDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ _animationDurations.length,
    );

    final animationCounts = <String, int>{};
    for (final type in _animationTypes) {
      animationCounts[type] = (animationCounts[type] ?? 0) + 1;
    }

    return {
      'totalAnimations': _animationTypes.length,
      'averageDuration': averageDuration.inMilliseconds,
      'animationTypes': animationCounts,
      'totalTime': totalDuration.inMilliseconds,
    };
  }

  static void reset() {
    _animationTypes.clear();
    _animationDurations.clear();
  }
}

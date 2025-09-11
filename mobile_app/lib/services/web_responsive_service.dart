import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web-specific responsive design service
class WebResponsiveService {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  /// Get current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < _mobileBreakpoint) {
      return ScreenSize.mobile;
    } else if (width < _tabletBreakpoint) {
      return ScreenSize.tablet;
    } else if (width < _desktopBreakpoint) {
      return ScreenSize.desktop;
    } else {
      return ScreenSize.largeDesktop;
    }
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// Check if current screen is desktop or larger
  static bool isDesktop(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.desktop || size == ScreenSize.largeDesktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(16);
      case ScreenSize.tablet:
        return const EdgeInsets.all(24);
      case ScreenSize.desktop:
        return const EdgeInsets.all(32);
      case ScreenSize.largeDesktop:
        return const EdgeInsets.all(48);
    }
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case ScreenSize.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
  }

  /// Get responsive column count for grid layouts
  static int getResponsiveColumns(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    int largeDesktopColumns = 4,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobileColumns;
      case ScreenSize.tablet:
        return tabletColumns;
      case ScreenSize.desktop:
        return desktopColumns;
      case ScreenSize.largeDesktop:
        return largeDesktopColumns;
    }
  }

  /// Get responsive font size multiplier
  static double getResponsiveFontScale(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return 0.9;
      case ScreenSize.tablet:
        return 1.0;
      case ScreenSize.desktop:
        return 1.1;
      case ScreenSize.largeDesktop:
        return 1.2;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, {
    double baseSize = 24,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return baseSize * 0.9;
      case ScreenSize.tablet:
        return baseSize;
      case ScreenSize.desktop:
        return baseSize * 1.1;
      case ScreenSize.largeDesktop:
        return baseSize * 1.2;
    }
  }

  /// Get responsive button size
  static Size getResponsiveButtonSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return const Size(120, 40);
      case ScreenSize.tablet:
        return const Size(140, 44);
      case ScreenSize.desktop:
        return const Size(160, 48);
      case ScreenSize.largeDesktop:
        return const Size(180, 52);
    }
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return screenWidth - 32; // Full width with margin
      case ScreenSize.tablet:
        return (screenWidth - 72) / 2; // Two columns with margins
      case ScreenSize.desktop:
        return (screenWidth - 128) / 3; // Three columns with margins
      case ScreenSize.largeDesktop:
        return (screenWidth - 192) / 4; // Four columns with margins
    }
  }

  /// Get responsive max content width
  static double getMaxContentWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 800;
      case ScreenSize.desktop:
        return 1200;
      case ScreenSize.largeDesktop:
        return 1400;
    }
  }

  /// Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return MediaQuery.of(context).size.width * 0.8; // 80% of screen
      case ScreenSize.tablet:
        return 300;
      case ScreenSize.desktop:
        return 320;
      case ScreenSize.largeDesktop:
        return 360;
    }
  }

  /// Check if sidebar should be persistent (always visible)
  static bool shouldShowPersistentSidebar(BuildContext context) {
    return isDesktop(context);
  }

  /// Get responsive layout type
  static LayoutType getLayoutType(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return LayoutType.stack; // Single column, stacked layout
      case ScreenSize.tablet:
        return LayoutType.adaptive; // Adaptive layout based on content
      case ScreenSize.desktop:
      case ScreenSize.largeDesktop:
        return LayoutType.sidebar; // Sidebar + main content layout
    }
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return kToolbarHeight;
      case ScreenSize.tablet:
        return kToolbarHeight + 8;
      case ScreenSize.desktop:
        return kToolbarHeight + 16;
      case ScreenSize.largeDesktop:
        return kToolbarHeight + 24;
    }
  }

  /// Initialize responsive web features
  static void initializeWebFeatures() {
    if (!kIsWeb) return;

    // Set viewport meta tag for proper mobile rendering
    _setViewportMeta();
    
    // Add responsive CSS classes to body
    _addResponsiveClasses();
    
    // Listen for window resize events
    _setupResizeListener();
  }

  static void _setViewportMeta() {
    final viewport = html.document.querySelector('meta[name="viewport"]');
    if (viewport == null) {
      final meta = html.MetaElement()
        ..name = 'viewport'
        ..content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
      html.document.head!.append(meta);
    }
  }

  static void _addResponsiveClasses() {
    final body = html.document.body;
    if (body != null) {
      body.classes.add('homie-app');
      body.classes.add('responsive-layout');
    }
  }

  static void _setupResizeListener() {
    html.window.onResize.listen((_) {
      // Trigger Flutter rebuild on window resize
      // This is handled automatically by MediaQuery
    });
  }
}

/// Screen size categories
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Layout types for different screen sizes
enum LayoutType {
  stack,     // Single column, stacked layout (mobile)
  adaptive,  // Adaptive layout based on content (tablet)
  sidebar,   // Sidebar + main content layout (desktop)
}

/// Responsive layout builder widget
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveLayoutBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = WebResponsiveService.getScreenSize(context);
    return builder(context, screenSize);
  }
}

/// Responsive value provider
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  T getValue(BuildContext context) {
    final screenSize = WebResponsiveService.getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}
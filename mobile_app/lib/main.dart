import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:homie_app/providers/app_state.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/financial_provider.dart';
import 'package:homie_app/providers/construction_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/providers/accessibility_provider.dart';
import 'package:homie_app/widgets/accessibility/keyboard_shortcuts.dart';
import 'package:homie_app/screens/dashboard_screen.dart';
import 'package:homie_app/screens/file_organizer/file_organizer_screen.dart';
import 'package:homie_app/screens/financial/financial_screen.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/config/app_arguments.dart';

void main(List<String> args) {
  try {
    // Initialize application arguments using professional parser
    AppArguments.initialize(args);
    
    // Handle environment variables as fallback (only on non-web platforms)
    if (!kIsWeb && args.isEmpty) {
      try {
        final envRoute = Platform.environment['INITIAL_ROUTE'];
        if (envRoute != null && envRoute.isNotEmpty) {
          // Re-initialize with environment route if no args provided
          AppArguments.initialize(['--route=$envRoute']);
        }
      } catch (e) {
        // Platform.environment not available (e.g., on web), ignore
        if (kDebugMode) {
          print('Platform.environment not available: $e');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error parsing arguments: $e');
    }
    // Initialize with empty args as fallback
    AppArguments.initialize([]);
  }
  
  runApp(const HomieApp());
}

class HomieApp extends StatelessWidget {
  const HomieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        ChangeNotifierProvider(create: (_) => FileOrganizerProvider()),
        ChangeNotifierProvider(create: (_) => FinancialProvider()),
        ChangeNotifierProvider(create: (_) => ConstructionProvider()),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibilityProvider, _) {
          return MaterialApp.router(
            title: 'Homie - Home Management System',
            theme: _buildAccessibleTheme(context, accessibilityProvider),
            routerConfig: _createRouter(), // Create router when needed
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return KeyboardShortcuts(
                onOrganize: () => _handleGlobalShortcut(context, 'organize'),
                onExecute: () => _handleGlobalShortcut(context, 'execute'),
                onCancel: () => _handleGlobalShortcut(context, 'cancel'),
                onRefresh: () => _handleGlobalShortcut(context, 'refresh'),
                onHelp: () => _handleGlobalShortcut(context, 'help'),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(accessibilityProvider.textScale),
                  ),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Handle global keyboard shortcuts
void _handleGlobalShortcut(BuildContext context, String action) {
  final currentRoute = GoRouterState.of(context).matchedLocation;
  
  switch (action) {
    case 'organize':
      if (currentRoute == '/file-organizer') {
        // Trigger organize action in file organizer
        final fileOrganizerProvider = context.read<FileOrganizerProvider>();
        if (fileOrganizerProvider.sourcePath.isNotEmpty && 
            fileOrganizerProvider.destinationPath.isNotEmpty) {
          fileOrganizerProvider.analyzeFolder();
        }
      } else {
        // Navigate to file organizer
        context.go('/file-organizer');
      }
      break;
    case 'execute':
      if (currentRoute == '/file-organizer') {
        // Execute operations in file organizer
        final fileOrganizerProvider = context.read<FileOrganizerProvider>();
        if (fileOrganizerProvider.operations.isNotEmpty) {
          fileOrganizerProvider.executeOperations();
        }
      }
      break;
    case 'cancel':
      // Handle escape/cancel based on current screen
      final fileOrganizerProvider = context.read<FileOrganizerProvider>();
      if (fileOrganizerProvider.isAnalyzing || fileOrganizerProvider.isExecuting) {
        // Cancel current operation
        fileOrganizerProvider.cancelOperations();
      }
      break;
    case 'refresh':
      // Refresh current screen data
      if (currentRoute == '/file-organizer') {
        final fileOrganizerProvider = context.read<FileOrganizerProvider>();
        fileOrganizerProvider.refreshDrives();
      }
      break;
    case 'help':
      // Help handled by KeyboardShortcuts widget
      break;
  }
}

ThemeData _buildAccessibleTheme(BuildContext context, AccessibilityProvider accessibilityProvider) {
  final baseTheme = AppTheme.darkTheme;
  final colorScheme = accessibilityProvider.getColorScheme(context);
  final textTheme = accessibilityProvider.getTextTheme(context);
  
  return baseTheme.copyWith(
    colorScheme: colorScheme,
    textTheme: textTheme,
    // Enhanced focus indicators for accessibility
    focusColor: accessibilityProvider.highContrastMode
        ? colorScheme.primary
        : baseTheme.focusColor,
    highlightColor: accessibilityProvider.highContrastMode
        ? colorScheme.primary.withOpacity(0.3)
        : baseTheme.highlightColor,
    splashColor: accessibilityProvider.highContrastMode
        ? colorScheme.primary.withOpacity(0.2)
        : baseTheme.splashColor,
    // Button themes with accessibility support
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: accessibilityProvider.getButtonConstraints().biggest,
        animationDuration: accessibilityProvider.getAnimationDuration(
          const Duration(milliseconds: 200),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: accessibilityProvider.highContrastMode
              ? BorderSide(color: colorScheme.outline, width: 1)
              : BorderSide.none,
        ),
      ),
    ),
    // Text button themes
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: accessibilityProvider.getButtonConstraints().biggest,
        animationDuration: accessibilityProvider.getAnimationDuration(
          const Duration(milliseconds: 200),
        ),
      ),
    ),
    // Icon button themes
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: accessibilityProvider.getButtonConstraints().biggest,
        animationDuration: accessibilityProvider.getAnimationDuration(
          const Duration(milliseconds: 200),
        ),
      ),
    ),
    // Enhanced input decoration for accessibility
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      border: accessibilityProvider.highContrastMode
          ? OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.outline, width: 2),
            )
          : baseTheme.inputDecorationTheme.border,
      focusedBorder: accessibilityProvider.highContrastMode
          ? OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary, width: 3),
            )
          : baseTheme.inputDecorationTheme.focusedBorder,
    ),
  );
}

/// Create router with proper initialization order
GoRouter _createRouter() {
  final args = AppArguments.instance;
  return GoRouter(
    initialLocation: args.initialRoute,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/file-organizer',
        builder: (context, state) {
          return FileOrganizerScreen(
            isStandaloneLaunch: args.isStandaloneLaunch,
            initialSourcePath: args.sourcePath,
            initialDestinationPath: args.destinationPath,
          );
        },
      ),
      GoRoute(
        path: '/financial',
        builder: (context, state) => FinancialScreen(
          isStandaloneLaunch: args.isStandaloneLaunch,
        ),
      ),
    ],
  );
}

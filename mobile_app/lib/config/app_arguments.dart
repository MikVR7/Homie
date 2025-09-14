// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

/// Professional command line argument parser for the Homie application.
/// Handles all supported command line parameters with proper validation and defaults.
class AppArguments {
  static AppArguments? _instance;
  
  final String initialRoute;
  final bool isStandaloneLaunch;
  final String? sourcePath;
  final String? destinationPath;
  final bool debugMode;
  final String? logLevel;

  const AppArguments._({
    required this.initialRoute,
    required this.isStandaloneLaunch,
    this.sourcePath,
    this.destinationPath,
    this.debugMode = false,
    this.logLevel,
  });

  /// Singleton instance accessor
  static AppArguments get instance {
    if (_instance == null) {
      throw StateError('AppArguments not initialized. Call AppArguments.initialize() first.');
    }
    return _instance!;
  }

  /// Initialize the application arguments from command line args
  static AppArguments initialize(List<String> args) {
    if (_instance != null) {
      if (kDebugMode) {
        print('⚠️  AppArguments already initialized, returning existing instance');
      }
      return _instance!;
    }

    final parser = _ArgumentParser(args);
    _instance = parser.parse();
    
    if (kDebugMode) {
      _instance!._logParsedArguments();
    }
    
    return _instance!;
  }

  /// Reset instance to allow re-initialization (for environment variable fallback)
  static void resetInstance() {
    _instance = null;
  }

  /// Check if any file organizer specific arguments were provided
  bool get hasFileOrganizerArgs => sourcePath != null || destinationPath != null;

  /// Get file organizer configuration
  FileOrganizerConfig get fileOrganizerConfig => FileOrganizerConfig(
    sourcePath: sourcePath,
    destinationPath: destinationPath,
  );

  void _logParsedArguments() {
    print('📋 Application Arguments Parsed:');
    print('   Route: $initialRoute');
    print('   Standalone: $isStandaloneLaunch');
    if (sourcePath != null) print('   Source: $sourcePath');
    if (destinationPath != null) print('   Destination: $destinationPath');
    if (debugMode) print('   Debug Mode: enabled');
    if (logLevel != null) print('   Log Level: $logLevel');
  }
}

/// Configuration specific to File Organizer module
class FileOrganizerConfig {
  final String? sourcePath;
  final String? destinationPath;

  const FileOrganizerConfig({
    this.sourcePath,
    this.destinationPath,
  });

  /// Get source path or default
  String getSourcePath([String defaultPath = '/home/mikele/Downloads']) {
    return sourcePath ?? defaultPath;
  }

  /// Get destination path or default
  String getDestinationPath([String defaultPath = '/home/mikele/Downloads/Organized']) {
    return destinationPath ?? defaultPath;
  }

  bool get hasCustomPaths => sourcePath != null || destinationPath != null;
}

/// Internal argument parser implementation
class _ArgumentParser {
  final List<String> _args;
  
  const _ArgumentParser(this._args);

  AppArguments parse() {
    String initialRoute = '/';
    bool isStandaloneLaunch = false;
    String? sourcePath;
    String? destinationPath;
    bool debugMode = false;
    String? logLevel;

    for (final arg in _args) {
      if (arg.startsWith('--route=')) {
        initialRoute = arg.substring(8);
        isStandaloneLaunch = true;
      } else if (arg.startsWith('--source=')) {
        sourcePath = _extractValue(arg);
        _validatePath(sourcePath, 'source');
      } else if (arg.startsWith('--destination=')) {
        destinationPath = _extractValue(arg);
        _validatePath(destinationPath, 'destination');
      } else if (arg == '--debug') {
        debugMode = true;
      } else if (arg.startsWith('--log-level=')) {
        logLevel = _extractValue(arg);
        _validateLogLevel(logLevel);
      } else if (arg.startsWith('--')) {
        if (kDebugMode) {
          print('⚠️  Unknown argument: $arg');
        }
      }
    }

    return AppArguments._(
      initialRoute: initialRoute,
      isStandaloneLaunch: isStandaloneLaunch,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      debugMode: debugMode,
      logLevel: logLevel,
    );
  }

  String _extractValue(String arg) {
    final equalIndex = arg.indexOf('=');
    if (equalIndex == -1 || equalIndex == arg.length - 1) {
      throw ArgumentError('Invalid argument format: $arg');
    }
    return arg.substring(equalIndex + 1);
  }

  void _validatePath(String? path, String paramName) {
    if (path == null || path.isEmpty) {
      throw ArgumentError('$paramName path cannot be empty');
    }
    
    if (!path.startsWith('/')) {
      throw ArgumentError('$paramName path must be absolute: $path');
    }
  }

  void _validateLogLevel(String? level) {
    const validLevels = ['debug', 'info', 'warning', 'error'];
    if (level != null && !validLevels.contains(level.toLowerCase())) {
      throw ArgumentError('Invalid log level: $level. Valid levels: ${validLevels.join(', ')}');
    }
  }
}

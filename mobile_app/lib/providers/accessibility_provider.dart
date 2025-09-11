import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Provider for managing accessibility settings and state throughout the app
class AccessibilityProvider extends ChangeNotifier {
  // Visual accessibility settings
  bool _highContrastMode = false;
  double _textScale = 1.0;
  bool _reduceMotion = false;
  bool _largeButtons = false;

  // Keyboard navigation state
  bool _keyboardNavigationEnabled = true;
  FocusNode? _currentFocus;
  List<FocusNode> _focusHistory = [];

  // Screen reader settings
  bool _announceStateChanges = true;
  bool _verboseDescriptions = false;

  // Getters for accessibility settings
  bool get highContrastMode => _highContrastMode;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;
  bool get largeButtons => _largeButtons;
  bool get keyboardNavigationEnabled => _keyboardNavigationEnabled;
  bool get announceStateChanges => _announceStateChanges;
  bool get verboseDescriptions => _verboseDescriptions;
  FocusNode? get currentFocus => _currentFocus;

  /// Toggle high contrast mode for better visibility
  void toggleHighContrast() {
    _highContrastMode = !_highContrastMode;
    notifyListeners();
    if (_announceStateChanges) {
      _announceToScreenReader(
        _highContrastMode ? 'High contrast mode enabled' : 'High contrast mode disabled'
      );
    }
  }

  /// Set text scale factor for better readability
  void setTextScale(double scale) {
    if (scale >= 0.8 && scale <= 2.0) {
      _textScale = scale;
      notifyListeners();
      if (_announceStateChanges) {
        _announceToScreenReader('Text size changed to ${(scale * 100).round()}%');
      }
    }
  }

  /// Toggle motion reduction for users sensitive to animations
  void toggleReduceMotion() {
    _reduceMotion = !_reduceMotion;
    notifyListeners();
    if (_announceStateChanges) {
      _announceToScreenReader(
        _reduceMotion ? 'Animations reduced' : 'Animations enabled'
      );
    }
  }

  /// Toggle larger button sizes for easier interaction
  void toggleLargeButtons() {
    _largeButtons = !_largeButtons;
    notifyListeners();
    if (_announceStateChanges) {
      _announceToScreenReader(
        _largeButtons ? 'Large buttons enabled' : 'Normal buttons enabled'
      );
    }
  }

  /// Toggle keyboard navigation support
  void toggleKeyboardNavigation() {
    _keyboardNavigationEnabled = !_keyboardNavigationEnabled;
    notifyListeners();
  }

  /// Toggle screen reader state change announcements
  void toggleStateAnnouncements() {
    _announceStateChanges = !_announceStateChanges;
    notifyListeners();
  }

  /// Toggle verbose descriptions for screen readers
  void toggleVerboseDescriptions() {
    _verboseDescriptions = !_verboseDescriptions;
    notifyListeners();
  }

  /// Set current focus and maintain focus history
  void setCurrentFocus(FocusNode? focus) {
    if (_currentFocus != focus) {
      if (_currentFocus != null && !_focusHistory.contains(_currentFocus)) {
        _focusHistory.add(_currentFocus!);
        if (_focusHistory.length > 10) {
          _focusHistory.removeAt(0);
        }
      }
      _currentFocus = focus;
      notifyListeners();
    }
  }

  /// Navigate to previous focus in history
  void focusPrevious(BuildContext context) {
    if (_focusHistory.isNotEmpty) {
      final previousFocus = _focusHistory.removeLast();
      if (previousFocus.canRequestFocus) {
        FocusScope.of(context).requestFocus(previousFocus);
        setCurrentFocus(previousFocus);
      }
    }
  }

  /// Get color scheme for current accessibility settings
  ColorScheme getColorScheme(BuildContext context) {
    final baseScheme = Theme.of(context).colorScheme;
    
    if (_highContrastMode) {
      return ColorScheme.fromSeed(
        seedColor: baseScheme.primary,
        brightness: baseScheme.brightness,
        contrastLevel: 1.0, // High contrast
      );
    }
    
    return baseScheme;
  }

  /// Get text theme with accessibility adjustments
  TextTheme getTextTheme(BuildContext context) {
    final baseTheme = Theme.of(context).textTheme;
    
    return baseTheme.copyWith(
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * _textScale,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * _textScale,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * _textScale,
      ),
    );
  }

  /// Get button size constraints based on accessibility settings
  BoxConstraints getButtonConstraints() {
    if (_largeButtons) {
      return const BoxConstraints(
        minHeight: 48.0,
        minWidth: 48.0,
      );
    }
    return const BoxConstraints(
      minHeight: 40.0,
      minWidth: 40.0,
    );
  }

  /// Get animation duration based on motion settings
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_reduceMotion) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Announce message to screen reader
  void _announceToScreenReader(String message) {
    // Use SemanticsService for all platforms
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Announce operation progress to screen reader
  void announceProgress(String operation, int current, int total) {
    if (_announceStateChanges) {
      final percentage = ((current / total) * 100).round();
      _announceToScreenReader('$operation: $percentage% complete, $current of $total files');
    }
  }

  /// Announce error to screen reader
  void announceError(String error) {
    if (_announceStateChanges) {
      _announceToScreenReader('Error: $error');
    }
  }

  /// Announce success to screen reader
  void announceSuccess(String message) {
    if (_announceStateChanges) {
      _announceToScreenReader('Success: $message');
    }
  }

  /// Reset all accessibility settings to defaults
  void resetToDefaults() {
    _highContrastMode = false;
    _textScale = 1.0;
    _reduceMotion = false;
    _largeButtons = false;
    _keyboardNavigationEnabled = true;
    _announceStateChanges = true;
    _verboseDescriptions = false;
    _currentFocus = null;
    _focusHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _focusHistory.clear();
    super.dispose();
  }
}

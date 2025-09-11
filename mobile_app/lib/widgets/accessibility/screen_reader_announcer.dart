import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'dart:async';

/// Widget for making live announcements to screen readers
class ScreenReaderAnnouncer extends StatefulWidget {
  final Widget child;
  final String? announcement;
  final bool politeness; // true for polite, false for assertive
  final Duration? delay;

  const ScreenReaderAnnouncer({
    Key? key,
    required this.child,
    this.announcement,
    this.politeness = true,
    this.delay,
  }) : super(key: key);

  @override
  State<ScreenReaderAnnouncer> createState() => _ScreenReaderAnnouncerState();
}

class _ScreenReaderAnnouncerState extends State<ScreenReaderAnnouncer> {
  Timer? _announcementTimer;
  String? _lastAnnouncement;

  @override
  void didUpdateWidget(ScreenReaderAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.announcement != null && 
        widget.announcement != _lastAnnouncement &&
        widget.announcement!.isNotEmpty) {
      _scheduleAnnouncement(widget.announcement!);
    }
  }

  void _scheduleAnnouncement(String announcement) {
    _announcementTimer?.cancel();
    
    final delay = widget.delay ?? const Duration(milliseconds: 100);
    
    _announcementTimer = Timer(delay, () {
      _makeAnnouncement(announcement);
      _lastAnnouncement = announcement;
    });
  }

  void _makeAnnouncement(String announcement) {
    if (mounted) {
      SemanticsService.announce(
        announcement,
        TextDirection.ltr,
        assertiveness: widget.politeness 
            ? Assertiveness.polite 
            : Assertiveness.assertive,
      );
    }
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Live region widget for announcing dynamic content changes
class LiveRegion extends StatefulWidget {
  final Widget child;
  final String? liveText;
  final bool atomic;
  final bool relevant;
  final LiveRegionPoliteness politeness;

  const LiveRegion({
    Key? key,
    required this.child,
    this.liveText,
    this.atomic = false,
    this.relevant = true,
    this.politeness = LiveRegionPoliteness.polite,
  }) : super(key: key);

  @override
  State<LiveRegion> createState() => _LiveRegionState();
}

class _LiveRegionState extends State<LiveRegion> {
  String? _previousText;

  @override
  void didUpdateWidget(LiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.liveText != _previousText && 
        widget.liveText != null &&
        widget.liveText!.isNotEmpty) {
      _announceChange();
      _previousText = widget.liveText;
    }
  }

  void _announceChange() {
    if (widget.liveText != null) {
      SemanticsService.announce(
        widget.liveText!,
        TextDirection.ltr,
        assertiveness: widget.politeness == LiveRegionPoliteness.assertive
            ? Assertiveness.assertive
            : Assertiveness.polite,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: widget.child,
    );
  }
}

enum LiveRegionPoliteness {
  polite,
  assertive,
}

/// Progress announcer for file operations
class ProgressAnnouncer extends StatefulWidget {
  final Widget child;
  final int currentStep;
  final int totalSteps;
  final String operation;
  final bool announceEveryStep;
  final int announceInterval; // Announce every N steps

  const ProgressAnnouncer({
    Key? key,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    required this.operation,
    this.announceEveryStep = false,
    this.announceInterval = 10,
  }) : super(key: key);

  @override
  State<ProgressAnnouncer> createState() => _ProgressAnnouncerState();
}

class _ProgressAnnouncerState extends State<ProgressAnnouncer> {
  int? _lastAnnouncedStep;
  Timer? _announcementTimer;

  @override
  void didUpdateWidget(ProgressAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.currentStep != oldWidget.currentStep) {
      _checkAndAnnounceProgress();
    }
  }

  void _checkAndAnnounceProgress() {
    final shouldAnnounce = widget.announceEveryStep ||
        _lastAnnouncedStep == null ||
        (widget.currentStep - _lastAnnouncedStep!) >= widget.announceInterval ||
        widget.currentStep == widget.totalSteps;

    if (shouldAnnounce) {
      _announceProgress();
    }
  }

  void _announceProgress() {
    _announcementTimer?.cancel();
    
    _announcementTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        final percentage = ((widget.currentStep / widget.totalSteps) * 100).round();
        final announcement = '${widget.operation}: $percentage% complete, '
            '${widget.currentStep} of ${widget.totalSteps} files';
        
        SemanticsService.announce(
          announcement,
          TextDirection.ltr,
          assertiveness: Assertiveness.polite,
        );
        
        _lastAnnouncedStep = widget.currentStep;
      }
    });
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiveRegion(
      liveText: _buildProgressText(),
      child: widget.child,
    );
  }

  String _buildProgressText() {
    if (widget.totalSteps == 0) return '';
    
    final percentage = ((widget.currentStep / widget.totalSteps) * 100).round();
    return '${widget.operation} progress: $percentage%';
  }
}

/// Error announcer for accessibility
class ErrorAnnouncer extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final bool clearOnAnnounce;

  const ErrorAnnouncer({
    Key? key,
    required this.child,
    this.errorMessage,
    this.clearOnAnnounce = true,
  }) : super(key: key);

  @override
  State<ErrorAnnouncer> createState() => _ErrorAnnouncerState();
}

class _ErrorAnnouncerState extends State<ErrorAnnouncer> {
  String? _lastErrorMessage;

  @override
  void didUpdateWidget(ErrorAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.errorMessage != null &&
        widget.errorMessage != _lastErrorMessage &&
        widget.errorMessage!.isNotEmpty) {
      _announceError();
    }
  }

  void _announceError() {
    if (widget.errorMessage != null) {
      SemanticsService.announce(
        'Error: ${widget.errorMessage}',
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
      
      _lastErrorMessage = widget.errorMessage;
      
      if (widget.clearOnAnnounce) {
        // Clear the error after announcement
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _lastErrorMessage = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Success announcer for completed operations
class SuccessAnnouncer extends StatefulWidget {
  final Widget child;
  final String? successMessage;
  final bool clearOnAnnounce;

  const SuccessAnnouncer({
    Key? key,
    required this.child,
    this.successMessage,
    this.clearOnAnnounce = true,
  }) : super(key: key);

  @override
  State<SuccessAnnouncer> createState() => _SuccessAnnouncerState();
}

class _SuccessAnnouncerState extends State<SuccessAnnouncer> {
  String? _lastSuccessMessage;

  @override
  void didUpdateWidget(SuccessAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.successMessage != null &&
        widget.successMessage != _lastSuccessMessage &&
        widget.successMessage!.isNotEmpty) {
      _announceSuccess();
    }
  }

  void _announceSuccess() {
    if (widget.successMessage != null) {
      SemanticsService.announce(
        'Success: ${widget.successMessage}',
        TextDirection.ltr,
        assertiveness: Assertiveness.polite,
      );
      
      _lastSuccessMessage = widget.successMessage;
      
      if (widget.clearOnAnnounce) {
        // Clear the success message after announcement
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _lastSuccessMessage = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Utility class for making announcements from anywhere in the app
class AccessibilityAnnouncer {
  static void announce(String message, {bool assertive = false}) {
    SemanticsService.announce(
      message,
      TextDirection.ltr,
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }

  static void announceProgress(String operation, int current, int total) {
    final percentage = ((current / total) * 100).round();
    announce('$operation: $percentage% complete, $current of $total files');
  }

  static void announceError(String error) {
    announce('Error: $error', assertive: true);
  }

  static void announceSuccess(String message) {
    announce('Success: $message');
  }

  static void announceNavigation(String location) {
    announce('Navigated to $location');
  }

  static void announceStateChange(String change) {
    announce(change);
  }
}

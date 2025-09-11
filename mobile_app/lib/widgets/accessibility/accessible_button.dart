import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';

/// Accessible button widget with enhanced semantics and keyboard support
class AccessibleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isDestructive;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;

  const AccessibleButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.isDestructive = false,
    this.isPrimary = false,
    this.isLoading = false,
    this.icon,
    this.padding,
    this.tooltip,
  }) : super(key: key);

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> 
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      final accessibilityProvider = context.read<AccessibilityProvider>();
      accessibilityProvider.setCurrentFocus(_focusNode);
      
      // Announce focus for screen readers
      if (accessibilityProvider.announceStateChanges && widget.semanticLabel != null) {
        SemanticsService.announce(
          'Focused on ${widget.semanticLabel}',
          TextDirection.ltr,
        );
      }
    }
  }

  void _handleTap() {
    if (widget.isLoading || widget.onPressed == null) return;
    
    // Provide haptic feedback
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    
    widget.onPressed?.call();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered && !context.read<AccessibilityProvider>().reduceMotion) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    final colorScheme = accessibilityProvider.getColorScheme(context);
    final textTheme = accessibilityProvider.getTextTheme(context);
    final buttonConstraints = accessibilityProvider.getButtonConstraints();
    
    // Determine button colors based on type and state
    Color backgroundColor;
    Color foregroundColor;
    Color focusColor;
    
    if (widget.isDestructive) {
      backgroundColor = widget.onPressed == null 
          ? colorScheme.error.withOpacity(0.3)
          : colorScheme.error;
      foregroundColor = colorScheme.onError;
      focusColor = colorScheme.error.withOpacity(0.2);
    } else if (widget.isPrimary) {
      backgroundColor = widget.onPressed == null 
          ? colorScheme.primary.withOpacity(0.3)
          : colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      focusColor = colorScheme.primary.withOpacity(0.2);
    } else {
      backgroundColor = widget.onPressed == null 
          ? colorScheme.surface.withOpacity(0.3)
          : colorScheme.surface;
      foregroundColor = colorScheme.onSurface;
      focusColor = colorScheme.onSurface.withOpacity(0.1);
    }

    Widget buttonChild = widget.child;
    
    if (widget.isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
          widget.child,
        ],
      );
    } else if (widget.icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          widget.child,
        ],
      );
    }

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: accessibilityProvider.reduceMotion ? 1.0 : _scaleAnimation.value,
          child: Container(
            constraints: buttonConstraints,
            child: Material(
              color: backgroundColor,
              elevation: _isFocused ? 4 : 2,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _handleTap,
                onHover: _handleHover,
                focusNode: _focusNode,
                borderRadius: BorderRadius.circular(8),
                focusColor: focusColor,
                hoverColor: backgroundColor.withOpacity(0.8),
                splashColor: foregroundColor.withOpacity(0.2),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: _isFocused ? Border.all(
                      color: accessibilityProvider.highContrastMode
                          ? colorScheme.outline
                          : colorScheme.primary,
                      width: accessibilityProvider.highContrastMode ? 3 : 2,
                    ) : null,
                  ),
                  child: DefaultTextStyle(
                    style: textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ) ?? TextStyle(color: foregroundColor),
                    child: buttonChild,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Wrap with semantics for screen readers
    return Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      focusable: true,
      focused: _isFocused,
      onTap: widget.onPressed != null && !widget.isLoading ? _handleTap : null,
      child: widget.tooltip != null
          ? Tooltip(
              message: widget.tooltip!,
              child: button,
            )
          : button,
    );
  }
}



/// Accessible toggle button for boolean states
class AccessibleToggleButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleToggleButton({
    Key? key,
    required this.value,
    this.onChanged,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
  }) : super(key: key);

  @override
  State<AccessibleToggleButton> createState() => _AccessibleToggleButtonState();
}

class _AccessibleToggleButtonState extends State<AccessibleToggleButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTap() {
    if (widget.onChanged != null) {
      widget.onChanged!(!widget.value);
      
      // Announce state change
      final accessibilityProvider = context.read<AccessibilityProvider>();
      if (accessibilityProvider.announceStateChanges) {
        SemanticsService.announce(
          '${widget.semanticLabel} ${widget.value ? 'enabled' : 'disabled'}',
          TextDirection.ltr,
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    final colorScheme = accessibilityProvider.getColorScheme(context);
    
    return Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: true,
      enabled: widget.onChanged != null,
      toggled: widget.value,
      focusable: true,
      focused: _isFocused,
      onTap: _handleTap,
      child: Material(
        color: widget.value ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _handleTap,
          focusNode: _focusNode,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.value 
                    ? colorScheme.primary 
                    : colorScheme.outline,
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

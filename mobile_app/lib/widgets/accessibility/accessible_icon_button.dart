import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';

/// Accessible icon button with enhanced semantics and keyboard navigation
class AccessibleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final String? tooltip;
  final bool isEnabled;
  final bool isDestructive;
  final Color? iconColor;
  final double? iconSize;
  final FocusNode? focusNode;

  const AccessibleIconButton({
    Key? key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.semanticHint,
    this.tooltip,
    this.isEnabled = true,
    this.isDestructive = false,
    this.iconColor,
    this.iconSize,
    this.focusNode,
  }) : super(key: key);

  @override
  State<AccessibleIconButton> createState() => _AccessibleIconButtonState();
}

class _AccessibleIconButtonState extends State<AccessibleIconButton> {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      context.read<AccessibilityProvider>().setCurrentFocus(_focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, child) {
        final colorScheme = accessibilityProvider.getColorScheme(context);
        final constraints = accessibilityProvider.getButtonConstraints();
        final isEnabled = widget.isEnabled && widget.onPressed != null;
        
        Color iconColor = widget.iconColor ??
            (widget.isDestructive
                ? colorScheme.error
                : colorScheme.primary);
        
        if (!isEnabled) {
          iconColor = colorScheme.onSurface.withOpacity(0.38);
        }

        return Semantics(
          label: widget.semanticLabel,
          hint: widget.semanticHint,
          button: true,
          enabled: isEnabled,
          onTap: isEnabled ? widget.onPressed : null,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Focus(
              focusNode: _focusNode,
              child: GestureDetector(
                onTap: isEnabled ? widget.onPressed : null,
                child: Container(
                  constraints: constraints,
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(colorScheme, accessibilityProvider),
                    borderRadius: BorderRadius.circular(8),
                    border: _getFocusBorder(colorScheme, accessibilityProvider),
                  ),
                  child: IconButton(
                    onPressed: isEnabled ? widget.onPressed : null,
                    icon: Icon(
                      widget.icon,
                      color: iconColor,
                      size: widget.iconSize ?? (accessibilityProvider.largeButtons ? 24 : 20),
                      semanticLabel: null, // Already handled by parent Semantics
                    ),
                    tooltip: widget.tooltip,
                    focusNode: FocusNode(skipTraversal: true), // Prevent double focus
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color? _getBackgroundColor(ColorScheme colorScheme, AccessibilityProvider accessibilityProvider) {
    if (!widget.isEnabled) return null;
    
    if (_isFocused || _isHovered) {
      if (accessibilityProvider.highContrastMode) {
        return widget.isDestructive
            ? colorScheme.error.withOpacity(0.2)
            : colorScheme.primary.withOpacity(0.2);
      }
      return colorScheme.surfaceVariant.withOpacity(0.8);
    }
    
    return null;
  }

  Border? _getFocusBorder(ColorScheme colorScheme, AccessibilityProvider accessibilityProvider) {
    if (_isFocused) {
      return Border.all(
        color: widget.isDestructive ? colorScheme.error : colorScheme.primary,
        width: accessibilityProvider.highContrastMode ? 3 : 2,
      );
    }
    return null;
  }
}

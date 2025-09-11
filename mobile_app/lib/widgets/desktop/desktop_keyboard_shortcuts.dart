import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/desktop_platform_service.dart';

/// Widget that provides desktop keyboard shortcuts functionality
class DesktopKeyboardShortcuts extends StatefulWidget {
  final Widget child;
  final Function(String)? onShortcutActivated;
  final bool enabled;

  const DesktopKeyboardShortcuts({
    Key? key,
    required this.child,
    this.onShortcutActivated,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DesktopKeyboardShortcuts> createState() => _DesktopKeyboardShortcutsState();
}

class _DesktopKeyboardShortcutsState extends State<DesktopKeyboardShortcuts> {
  late Map<ShortcutActivator, VoidCallback> _shortcuts;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _buildShortcuts();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _buildShortcuts() {
    _shortcuts = {};
    
    if (!DesktopPlatformService.isDesktopPlatform || !widget.enabled) {
      return;
    }

    final platform = DesktopPlatformService.currentPlatform;
    final isApple = platform == DesktopPlatform.macos;
    final modifier = isApple ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    
    // File operations
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyO)] = 
        () => _handleShortcut('organize');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyE)] = 
        () => _handleShortcut('execute');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyP)] = 
        () => _handleShortcut('pause');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyR)] = 
        () => _handleShortcut('resume');
    
    // Cancel operation (platform-specific)
    if (isApple) {
      _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.period)] = 
          () => _handleShortcut('cancel');
    } else {
      _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyC)] = 
          () => _handleShortcut('cancel');
    }
    
    // Application shortcuts
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.comma)] = 
        () => _handleShortcut('preferences');
    
    // Window management
    if (isApple) {
      _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyM)] = 
          () => _handleShortcut('minimize');
      _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.control, LogicalKeyboardKey.keyF)] = 
          () => _handleShortcut('fullscreen');
      _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyQ)] = 
          () => _handleShortcut('quit');
    } else {
      _shortcuts[LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f9)] = 
          () => _handleShortcut('minimize');
      _shortcuts[LogicalKeySet(LogicalKeyboardKey.f11)] = 
          () => _handleShortcut('fullscreen');
      _shortcuts[LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4)] = 
          () => _handleShortcut('quit');
    }
    
    // Navigation shortcuts
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.escape)] = 
        () => _handleShortcut('escape');
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.f1)] = 
        () => _handleShortcut('help');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyN)] = 
        () => _handleShortcut('new');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyS)] = 
        () => _handleShortcut('save');
    
    // Selection shortcuts
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyA)] = 
        () => _handleShortcut('selectAll');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyD)] = 
        () => _handleShortcut('deselectAll');
    
    // View shortcuts
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.equal)] = 
        () => _handleShortcut('zoomIn');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.minus)] = 
        () => _handleShortcut('zoomOut');
    _shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.digit0)] = 
        () => _handleShortcut('zoomReset');
  }

  void _handleShortcut(String action) {
    debugPrint('Desktop keyboard shortcut activated: $action');
    widget.onShortcutActivated?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatformService.isDesktopPlatform || !widget.enabled) {
      return widget.child;
    }

    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: widget.child,
      ),
    );
  }
}

/// Widget that displays available keyboard shortcuts
class DesktopShortcutsHelp extends StatelessWidget {
  const DesktopShortcutsHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = DesktopPlatformService.getPlatformKeyboardShortcuts();
    
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.keyboard, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShortcutSection(
                      theme,
                      'File Operations',
                      {
                        'organize': shortcuts['organize'] ?? '',
                        'execute': shortcuts['execute'] ?? '',
                        'pause': shortcuts['pause'] ?? '',
                        'resume': shortcuts['resume'] ?? '',
                        'cancel': shortcuts['cancel'] ?? '',
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildShortcutSection(
                      theme,
                      'Window Management',
                      {
                        'minimize': shortcuts['minimize'] ?? '',
                        'fullscreen': shortcuts['fullscreen'] ?? '',
                        'preferences': shortcuts['preferences'] ?? '',
                        'quit': shortcuts['quit'] ?? '',
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildShortcutSection(
                      theme,
                      'General',
                      {
                        'help': 'F1',
                        'selectAll': _getModifierKey() + '+A',
                        'deselectAll': _getModifierKey() + '+D',
                        'escape': 'Escape',
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection(
    ThemeData theme,
    String title,
    Map<String, String> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...shortcuts.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getShortcutDescription(entry.key),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getModifierKey() {
    final platform = DesktopPlatformService.currentPlatform;
    return platform == DesktopPlatform.macos ? 'Cmd' : 'Ctrl';
  }

  String _getShortcutDescription(String key) {
    switch (key) {
      case 'organize':
        return 'Organize Files';
      case 'execute':
        return 'Execute Operations';
      case 'pause':
        return 'Pause Operations';
      case 'resume':
        return 'Resume Operations';
      case 'cancel':
        return 'Cancel Operations';
      case 'preferences':
        return 'Show Preferences';
      case 'quit':
        return 'Quit Application';
      case 'minimize':
        return 'Minimize Window';
      case 'fullscreen':
        return 'Toggle Fullscreen';
      case 'help':
        return 'Show Help';
      case 'selectAll':
        return 'Select All';
      case 'deselectAll':
        return 'Deselect All';
      case 'escape':
        return 'Cancel/Close';
      default:
        return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }
}

/// Mixin for widgets that need desktop keyboard shortcuts
mixin DesktopKeyboardShortcutsMixin<T extends StatefulWidget> on State<T> {
  late Map<String, VoidCallback> _shortcutHandlers;
  
  void initializeDesktopShortcuts(Map<String, VoidCallback> handlers) {
    _shortcutHandlers = handlers;
  }
  
  void handleDesktopShortcut(String action) {
    final handler = _shortcutHandlers[action];
    if (handler != null) {
      handler();
    } else {
      debugPrint('Unhandled desktop shortcut: $action');
    }
  }
  
  Widget wrapWithDesktopShortcuts(Widget child) {
    return DesktopKeyboardShortcuts(
      onShortcutActivated: handleDesktopShortcut,
      child: child,
    );
  }
  
  void showDesktopShortcutsHelp() {
    showDialog(
      context: context,
      builder: (context) => const DesktopShortcutsHelp(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';

/// Intent classes for keyboard shortcuts
class OrganizeIntent extends Intent {
  const OrganizeIntent();
}

class ExecuteIntent extends Intent {
  const ExecuteIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class TogglePreviewIntent extends Intent {
  const TogglePreviewIntent();
}

/// Keyboard shortcuts widget that wraps the entire app
class KeyboardShortcuts extends StatefulWidget {
  final Widget child;
  final VoidCallback? onOrganize;
  final VoidCallback? onExecute;
  final VoidCallback? onCancel;
  final VoidCallback? onHelp;
  final VoidCallback? onRefresh;
  final VoidCallback? onSelectAll;
  final VoidCallback? onTogglePreview;

  const KeyboardShortcuts({
    Key? key,
    required this.child,
    this.onOrganize,
    this.onExecute,
    this.onCancel,
    this.onHelp,
    this.onRefresh,
    this.onSelectAll,
    this.onTogglePreview,
  }) : super(key: key);

  @override
  State<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  late Map<ShortcutActivator, Intent> _shortcuts;
  late Map<Type, Action<Intent>> _actions;

  @override
  void initState() {
    super.initState();
    _initializeShortcuts();
    _initializeActions();
  }

  void _initializeShortcuts() {
    _shortcuts = {
      // File organization shortcuts
      const SingleActivator(LogicalKeyboardKey.keyO, control: true): const OrganizeIntent(),
      const SingleActivator(LogicalKeyboardKey.keyE, control: true): const ExecuteIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const CancelIntent(),
      
      // Help and navigation
      const SingleActivator(LogicalKeyboardKey.f1): const HelpIntent(),
      const SingleActivator(LogicalKeyboardKey.f5): const RefreshIntent(),
      
      // Selection shortcuts
      const SingleActivator(LogicalKeyboardKey.keyA, control: true): const SelectAllIntent(),
      
      // View shortcuts
      const SingleActivator(LogicalKeyboardKey.space): const TogglePreviewIntent(),
    };
  }

  void _initializeActions() {
    _actions = {
      OrganizeIntent: CallbackAction<OrganizeIntent>(
        onInvoke: (intent) {
          widget.onOrganize?.call();
          _announceShortcut('Organize files shortcut activated');
          return null;
        },
      ),
      ExecuteIntent: CallbackAction<ExecuteIntent>(
        onInvoke: (intent) {
          widget.onExecute?.call();
          _announceShortcut('Execute operations shortcut activated');
          return null;
        },
      ),
      CancelIntent: CallbackAction<CancelIntent>(
        onInvoke: (intent) {
          widget.onCancel?.call();
          _announceShortcut('Cancel operation shortcut activated');
          return null;
        },
      ),
      HelpIntent: CallbackAction<HelpIntent>(
        onInvoke: (intent) {
          _showKeyboardShortcutsHelp();
          _announceShortcut('Help shortcut activated');
          return null;
        },
      ),
      RefreshIntent: CallbackAction<RefreshIntent>(
        onInvoke: (intent) {
          widget.onRefresh?.call();
          _announceShortcut('Refresh shortcut activated');
          return null;
        },
      ),
      SelectAllIntent: CallbackAction<SelectAllIntent>(
        onInvoke: (intent) {
          widget.onSelectAll?.call();
          _announceShortcut('Select all shortcut activated');
          return null;
        },
      ),
      TogglePreviewIntent: CallbackAction<TogglePreviewIntent>(
        onInvoke: (intent) {
          widget.onTogglePreview?.call();
          _announceShortcut('Toggle preview shortcut activated');
          return null;
        },
      ),
    };
  }

  void _announceShortcut(String message) {
    final accessibilityProvider = context.read<AccessibilityProvider>();
    if (accessibilityProvider.announceStateChanges) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  void _showKeyboardShortcutsHelp() {
    showDialog(
      context: context,
      builder: (context) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: widget.child,
      ),
    );
  }
}

/// Dialog showing all available keyboard shortcuts
class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    final textTheme = accessibilityProvider.getTextTheme(context);

    return AlertDialog(
      title: Text(
        'Keyboard Shortcuts',
        style: textTheme.headlineSmall,
        semanticsLabel: 'Keyboard shortcuts help dialog',
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutCategory(
              'File Operations',
              [
                _ShortcutItem('Ctrl + O', 'Analyze and organize files'),
                _ShortcutItem('Ctrl + E', 'Execute selected operations'),
                _ShortcutItem('Escape', 'Cancel current operation'),
              ],
              textTheme,
            ),
            const SizedBox(height: 16),
            _buildShortcutCategory(
              'Navigation',
              [
                _ShortcutItem('F1', 'Show this help dialog'),
                _ShortcutItem('F5', 'Refresh file lists and drives'),
                _ShortcutItem('Tab', 'Navigate between elements'),
                _ShortcutItem('Shift + Tab', 'Navigate backwards'),
              ],
              textTheme,
            ),
            const SizedBox(height: 16),
            _buildShortcutCategory(
              'Selection',
              [
                _ShortcutItem('Ctrl + A', 'Select all operations'),
                _ShortcutItem('Space', 'Toggle preview for selected item'),
                _ShortcutItem('Enter', 'Activate focused element'),
              ],
              textTheme,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: textTheme.labelLarge,
            semanticsLabel: 'Close keyboard shortcuts dialog',
          ),
        ),
      ],
      semanticLabel: 'Keyboard shortcuts reference dialog',
    );
  }

  Widget _buildShortcutCategory(
    String title,
    List<_ShortcutItem> items,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          semanticsLabel: '$title category',
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.shortcut,
                  style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  semanticsLabel: 'Keyboard shortcut: ${item.shortcut}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.description,
                  style: textTheme.bodyMedium,
                  semanticsLabel: item.description,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _ShortcutItem {
  final String shortcut;
  final String description;

  const _ShortcutItem(this.shortcut, this.description);
}

/// Focus management widget for better keyboard navigation
class AccessibleFocusScope extends StatefulWidget {
  final Widget child;
  final String? semanticLabel;
  final bool autofocus;
  final VoidCallback? onFocusChange;

  const AccessibleFocusScope({
    Key? key,
    required this.child,
    this.semanticLabel,
    this.autofocus = false,
    this.onFocusChange,
  }) : super(key: key);

  @override
  State<AccessibleFocusScope> createState() => _AccessibleFocusScopeState();
}

class _AccessibleFocusScopeState extends State<AccessibleFocusScope> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    final accessibilityProvider = context.read<AccessibilityProvider>();
    if (_focusNode.hasFocus) {
      accessibilityProvider.setCurrentFocus(_focusNode);
    }
    widget.onFocusChange?.call();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: Focus(
        focusNode: _focusNode,
        child: widget.child,
      ),
    );
  }
}

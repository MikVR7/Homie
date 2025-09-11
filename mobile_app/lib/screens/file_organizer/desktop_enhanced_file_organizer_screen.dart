import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/file_organizer_provider.dart';
import '../../services/desktop_platform_service.dart';
import '../file_organizer/modern_file_organizer_screen.dart';

/// Desktop-enhanced File Organizer Screen with native integrations
class DesktopEnhancedFileOrganizerScreen extends StatefulWidget {
  final bool isStandaloneLaunch;

  const DesktopEnhancedFileOrganizerScreen({
    Key? key,
    this.isStandaloneLaunch = false,
  }) : super(key: key);

  @override
  State<DesktopEnhancedFileOrganizerScreen> createState() => 
      _DesktopEnhancedFileOrganizerScreenState();
}

class _DesktopEnhancedFileOrganizerScreenState 
    extends State<DesktopEnhancedFileOrganizerScreen> {
  late Map<String, String> _platformShortcuts;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize desktop-specific features
    if (DesktopPlatformService.isDesktopPlatform) {
      _initializeDesktopFeatures();
    }
  }

  void _initializeDesktopFeatures() {
    // Get platform-specific keyboard shortcuts
    _platformShortcuts = DesktopPlatformService.getPlatformKeyboardShortcuts();
    
    // Check available desktop features
    final features = DesktopPlatformService.getPlatformFeatures();
    
    if (features['nativeFileDialogs'] == true) {
      debugPrint('Native file dialogs are available');
    }
    
    if (features['systemNotifications'] == true) {
      debugPrint('System notifications are available');
    }
    
    if (features['windowStateManagement'] == true) {
      debugPrint('Window state management is available');
    }
  }

  void _handleKeyboardShortcut(String action) {
    final provider = context.read<FileOrganizerProvider>();
    
    switch (action) {
      case 'organize':
        if (provider.sourcePath.isNotEmpty && provider.destinationPath.isNotEmpty) {
          provider.analyzeFolder();
        }
        break;
      case 'execute':
        if (provider.operations.isNotEmpty) {
          provider.executeOperations();
        }
        break;
      case 'pause':
        if (provider.status == OperationStatus.executing) {
          provider.pauseOperations();
        }
        break;
      case 'resume':
        if (provider.status == OperationStatus.paused) {
          provider.resumeOperations();
        }
        break;
      case 'cancel':
        if (provider.status == OperationStatus.executing || 
            provider.status == OperationStatus.paused) {
          provider.cancelOperations();
        }
        break;
      case 'minimize':
        _setWindowState(WindowState.minimized);
        break;
      case 'fullscreen':
        _toggleFullscreen();
        break;
      case 'preferences':
        _showPreferences();
        break;
    }
  }

  void _setWindowState(WindowState state) async {
    if (DesktopPlatformService.isWindowStateManagementSupported) {
      final success = await DesktopPlatformService.setWindowState(state);
      if (!success) {
        _showDesktopFeatureError('Window state management');
      }
    }
  }

  void _toggleFullscreen() async {
    final currentState = await DesktopPlatformService.getWindowState();
    final newState = currentState == WindowState.fullscreen 
        ? WindowState.normal 
        : WindowState.fullscreen;
    
    final success = await DesktopPlatformService.setWindowState(newState);
    if (success) {
      setState(() {
        _isFullscreen = newState == WindowState.fullscreen;
      });
    }
  }

  void _showNativeFolderPicker({required bool isSource}) async {
    if (!DesktopPlatformService.isNativeFileDialogSupported) {
      _showDesktopFeatureError('Native file dialogs');
      return;
    }

    final provider = context.read<FileOrganizerProvider>();
    final initialDirectory = isSource ? provider.sourcePath : provider.destinationPath;
    
    final selectedPath = await DesktopPlatformService.showFolderPicker(
      initialDirectory: initialDirectory.isNotEmpty ? initialDirectory : null,
      dialogTitle: isSource ? 'Select Source Folder' : 'Select Destination Folder',
    );

    if (selectedPath != null) {
      if (isSource) {
        provider.setSourcePath(selectedPath);
      } else {
        provider.setDestinationPath(selectedPath);
      }
    }
  }

  void _showSystemNotification({
    required String title,
    required String message,
  }) async {
    if (!DesktopPlatformService.isSystemNotificationSupported) {
      return;
    }

    await DesktopPlatformService.showSystemNotification(
      title: title,
      message: message,
      timeout: const Duration(seconds: 5),
    );
  }

  void _showDesktopFeatureError(String feature) {
    final message = DesktopPlatformService.getFeatureAvailabilityMessage(feature);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPreferences() {
    showDialog(
      context: context,
      builder: (context) => _DesktopPreferencesDialog(
        shortcuts: _platformShortcuts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDesktopEnhancedLayout(context);
  }

  Widget _buildDesktopEnhancedLayout(BuildContext context) {
    final child = ModernFileOrganizerScreen(
      isStandaloneLaunch: widget.isStandaloneLaunch,
    );

    // Add desktop-specific enhancements
    if (DesktopPlatformService.isDesktopPlatform) {
      return _buildDesktopContainer(context, child);
    }

    return child;
  }

  Widget _buildDesktopContainer(BuildContext context, Widget child) {
    return CallbackShortcuts(
      bindings: _buildKeyboardShortcuts(),
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            // Desktop platform features banner
            _buildDesktopFeaturesBanner(context),
            
            // Main content
            Expanded(child: child),
            
            // Desktop status bar
            _buildDesktopStatusBar(context),
          ],
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() {
    final shortcuts = <ShortcutActivator, VoidCallback>{};
    final platform = DesktopPlatformService.currentPlatform;
    
    // Platform-specific modifier key
    final isApple = platform == DesktopPlatform.macos;
    final modifier = isApple ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    
    shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyO)] = 
        () => _handleKeyboardShortcut('organize');
    shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyE)] = 
        () => _handleKeyboardShortcut('execute');
    shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyP)] = 
        () => _handleKeyboardShortcut('pause');
    shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyR)] = 
        () => _handleKeyboardShortcut('resume');
    
    if (isApple) {
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.period)] = 
          () => _handleKeyboardShortcut('cancel');
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.comma)] = 
          () => _handleKeyboardShortcut('preferences');
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyM)] = 
          () => _handleKeyboardShortcut('minimize');
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.control, LogicalKeyboardKey.keyF)] = 
          () => _handleKeyboardShortcut('fullscreen');
    } else {
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.keyC)] = 
          () => _handleKeyboardShortcut('cancel');
      shortcuts[LogicalKeySet(modifier, LogicalKeyboardKey.comma)] = 
          () => _handleKeyboardShortcut('preferences');
      shortcuts[LogicalKeySet(LogicalKeyboardKey.f11)] = 
          () => _handleKeyboardShortcut('fullscreen');
    }
    
    return shortcuts;
  }

  Widget _buildDesktopFeaturesBanner(BuildContext context) {
    final theme = Theme.of(context);
    final features = DesktopPlatformService.getPlatformFeatures();
    final platform = DesktopPlatformService.currentPlatform;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getPlatformIcon(platform),
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desktop Platform Features (${platform.name.toUpperCase()})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getFeaturesSummary(features),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showPreferences,
            icon: Icon(
              Icons.settings,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            tooltip: 'Desktop Preferences (${_platformShortcuts['preferences']})',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatusBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Desktop Mode',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Consumer<FileOrganizerProvider>(
            builder: (context, provider, child) {
              return Text(
                _getStatusText(provider.status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(DesktopPlatform platform) {
    switch (platform) {
      case DesktopPlatform.windows:
        return Icons.desktop_windows;
      case DesktopPlatform.macos:
        return Icons.desktop_mac;
      case DesktopPlatform.linux:
        return Icons.computer;
      case DesktopPlatform.none:
        return Icons.device_unknown;
    }
  }

  String _getFeaturesSummary(Map<String, bool> features) {
    final availableFeatures = features.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (availableFeatures.isEmpty) {
      return 'Basic desktop functionality available';
    }
    
    return 'Available: ${availableFeatures.length} features';
  }

  String _getStatusText(OperationStatus status) {
    switch (status) {
      case OperationStatus.idle:
        return 'Ready';
      case OperationStatus.analyzing:
        return 'Analyzing...';
      case OperationStatus.executing:
        return 'Executing...';
      case OperationStatus.paused:
        return 'Paused';
      case OperationStatus.completed:
        return 'Completed';
      case OperationStatus.error:
        return 'Error';
      case OperationStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Desktop preferences dialog
class _DesktopPreferencesDialog extends StatelessWidget {
  final Map<String, String> shortcuts;

  const _DesktopPreferencesDialog({
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = DesktopPlatformService.currentPlatform;
    final features = DesktopPlatformService.getPlatformFeatures();
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('Desktop Preferences'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Keyboard Shortcuts'),
                  Tab(text: 'Platform Features'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildShortcutsTab(theme),
                    _buildFeaturesTab(theme, platform, features),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: shortcuts.entries.map((entry) {
        return ListTile(
          title: Text(_getShortcutDescription(entry.key)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesTab(
    ThemeData theme, 
    DesktopPlatform platform, 
    Map<String, bool> features,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text('Platform'),
          trailing: Text(platform.name.toUpperCase()),
        ),
        const Divider(),
        ...features.entries.map((entry) {
          return ListTile(
            title: Text(_getFeatureDescription(entry.key)),
            trailing: Icon(
              entry.value ? Icons.check_circle : Icons.cancel,
              color: entry.value ? Colors.green : Colors.red,
            ),
          );
        }).toList(),
      ],
    );
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
      default:
        return key;
    }
  }

  String _getFeatureDescription(String key) {
    switch (key) {
      case 'nativeFileDialogs':
        return 'Native File Dialogs';
      case 'systemNotifications':
        return 'System Notifications';
      case 'windowStateManagement':
        return 'Window State Management';
      case 'platformKeyboardShortcuts':
        return 'Platform Keyboard Shortcuts';
      case 'systemTrayIntegration':
        return 'System Tray Integration';
      default:
        return key;
    }
  }
}
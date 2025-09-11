import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/file_organizer_provider.dart';
import '../../services/mobile_platform_service.dart';
import '../file_organizer/modern_file_organizer_screen.dart';

/// Mobile-enhanced File Organizer Screen with touch optimizations and gesture support
class MobileEnhancedFileOrganizerScreen extends StatefulWidget {
  final bool isStandaloneLaunch;

  const MobileEnhancedFileOrganizerScreen({
    Key? key,
    this.isStandaloneLaunch = false,
  }) : super(key: key);

  @override
  State<MobileEnhancedFileOrganizerScreen> createState() => 
      _MobileEnhancedFileOrganizerScreenState();
}

class _MobileEnhancedFileOrganizerScreenState 
    extends State<MobileEnhancedFileOrganizerScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _swipeController;
  bool _isRefreshing = false;
  bool _isTablet = false;
  DeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize mobile-specific features
    if (MobilePlatformService.isMobilePlatform) {
      _initializeMobileFeatures();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _initializeMobileFeatures() async {
    // Apply mobile optimizations
    MobilePlatformService.optimizeForMobile();
    
    // Get device information
    final deviceInfo = await MobilePlatformService.getDeviceInfo();
    setState(() {
      _deviceInfo = deviceInfo;
    });
    
    // Check available mobile features
    final features = MobilePlatformService.getPlatformFeatures();
    
    if (features['hapticFeedback'] == true) {
      debugPrint('Haptic feedback is available');
    }
    
    if (features['nativeFilePicker'] == true) {
      debugPrint('Native file picker is available');
    }
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshController.forward();
    
    // Trigger haptic feedback
    await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.light);
    
    // Refresh data
    final provider = context.read<FileOrganizerProvider>();
    await provider.refreshDrives();
    
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _refreshController.reverse();
    setState(() {
      _isRefreshing = false;
    });
    
    // Success haptic feedback
    await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.selection);
  }

  void _handleSwipeAction(String action) async {
    // Trigger haptic feedback for swipe actions
    await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.medium);
    
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
      case 'cancel':
        if (provider.status == OperationStatus.executing || 
            provider.status == OperationStatus.paused) {
          provider.cancelOperations();
        }
        break;
    }
  }

  void _showNativeFilePicker() async {
    if (!MobilePlatformService.isNativeFilePickerSupported) {
      _showMobileFeatureError('Native file picker');
      return;
    }

    // Trigger haptic feedback
    await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.selection);

    final selectedFiles = await MobilePlatformService.showNativeFilePicker(
      allowMultiple: true,
      allowedExtensions: ['*'],
      dialogTitle: 'Select Files to Organize',
    );

    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      // Handle selected files
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected ${selectedFiles.length} files'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMobileFeatureError(String feature) {
    final message = MobilePlatformService.getFeatureAvailabilityMessage(feature);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isTablet = MobilePlatformService.isTablet(context);
    
    return _buildMobileEnhancedLayout(context);
  }

  Widget _buildMobileEnhancedLayout(BuildContext context) {
    final child = ModernFileOrganizerScreen(
      isStandaloneLaunch: widget.isStandaloneLaunch,
    );

    // Add mobile-specific enhancements
    if (MobilePlatformService.isMobilePlatform) {
      return _buildMobileContainer(context, child);
    }

    return child;
  }

  Widget _buildMobileContainer(BuildContext context, Widget child) {
    return GestureDetector(
      onTap: () async {
        // Light haptic feedback for general taps
        await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.light);
      },
      child: RefreshIndicator(
        onRefresh: () async => _handleRefresh(),
        child: Column(
          children: [
            // Mobile platform features banner
            _buildMobileFeaturesBanner(context),
            
            // Main content with gesture support
            Expanded(
              child: _buildGestureWrapper(context, child),
            ),
            
            // Mobile action bar
            _buildMobileActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureWrapper(BuildContext context, Widget child) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final config = MobilePlatformService.getGestureConfiguration();
        
        if (velocity.abs() > config.swipeVelocityThreshold) {
          if (velocity > 0) {
            // Swipe right - previous action
            _handleSwipeAction('cancel');
          } else {
            // Swipe left - next action
            _handleSwipeAction('organize');
          }
        }
      },
      onLongPress: () async {
        // Heavy haptic feedback for long press
        await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.heavy);
        _showMobileOptionsMenu(context);
      },
      child: child,
    );
  }

  Widget _buildMobileFeaturesBanner(BuildContext context) {
    final theme = Theme.of(context);
    final features = MobilePlatformService.getPlatformFeatures();
    final platform = MobilePlatformService.currentPlatform;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getPlatformIcon(platform),
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobile Platform (${platform.name.toUpperCase()})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getFeaturesSummary(features),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          if (_deviceInfo != null)
            IconButton(
              onPressed: () => _showDeviceInfo(context),
              icon: Icon(
                Icons.info_outline,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              tooltip: 'Device Information',
            ),
        ],
      ),
    );
  }

  Widget _buildMobileActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final touchTargets = MobilePlatformService.getTouchTargetSizes();
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMobileActionButton(
            context,
            icon: Icons.folder_open,
            label: 'Pick Files',
            onPressed: _showNativeFilePicker,
            size: touchTargets.comfortable,
          ),
          _buildMobileActionButton(
            context,
            icon: Icons.auto_awesome,
            label: 'Organize',
            onPressed: () => _handleSwipeAction('organize'),
            size: touchTargets.comfortable,
          ),
          _buildMobileActionButton(
            context,
            icon: Icons.play_arrow,
            label: 'Execute',
            onPressed: () => _handleSwipeAction('execute'),
            size: touchTargets.comfortable,
          ),
          _buildMobileActionButton(
            context,
            icon: Icons.more_vert,
            label: 'More',
            onPressed: () => _showMobileOptionsMenu(context),
            size: touchTargets.comfortable,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required double size,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () async {
        await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.selection);
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: size * 0.4,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: size * 0.15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MobileOptionsSheet(
        onOptionSelected: (option) async {
          await MobilePlatformService.triggerHapticFeedback(HapticFeedbackType.selection);
          Navigator.of(context).pop();
          
          switch (option) {
            case 'refresh':
              _handleRefresh();
              break;
            case 'settings':
              _showMobileSettings(context);
              break;
            case 'help':
              _showMobileHelp(context);
              break;
          }
        },
      ),
    );
  }

  void _showDeviceInfo(BuildContext context) {
    if (_deviceInfo == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _DeviceInfoDialog(deviceInfo: _deviceInfo!),
    );
  }

  void _showMobileSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MobileSettingsDialog(),
    );
  }

  void _showMobileHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MobileHelpDialog(),
    );
  }

  IconData _getPlatformIcon(MobilePlatform platform) {
    switch (platform) {
      case MobilePlatform.android:
        return Icons.android;
      case MobilePlatform.ios:
        return Icons.phone_iphone;
      case MobilePlatform.none:
        return Icons.device_unknown;
    }
  }

  String _getFeaturesSummary(Map<String, bool> features) {
    final availableFeatures = features.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (availableFeatures.isEmpty) {
      return 'Basic mobile functionality available';
    }
    
    return 'Available: ${availableFeatures.length} features';
  }
}

/// Mobile options bottom sheet
class _MobileOptionsSheet extends StatelessWidget {
  final Function(String) onOptionSelected;

  const _MobileOptionsSheet({
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final touchTargets = MobilePlatformService.getTouchTargetSizes();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mobile Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            context,
            icon: Icons.refresh,
            title: 'Refresh',
            subtitle: 'Refresh drives and data',
            onTap: () => onOptionSelected('refresh'),
            minHeight: touchTargets.comfortable,
          ),
          _buildOptionTile(
            context,
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Mobile preferences',
            onTap: () => onOptionSelected('settings'),
            minHeight: touchTargets.comfortable,
          ),
          _buildOptionTile(
            context,
            icon: Icons.help_outline,
            title: 'Help',
            subtitle: 'Mobile gestures and tips',
            onTap: () => onOptionSelected('help'),
            minHeight: touchTargets.comfortable,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double minHeight,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      minTileHeight: minHeight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Device information dialog
class _DeviceInfoDialog extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const _DeviceInfoDialog({
    required this.deviceInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.phone_android, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Device Information'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Platform', deviceInfo.platform.name.toUpperCase()),
          _buildInfoRow('Screen Size', '${deviceInfo.screenSize.width.toInt()} x ${deviceInfo.screenSize.height.toInt()}'),
          _buildInfoRow('Pixel Ratio', deviceInfo.pixelRatio.toString()),
          _buildInfoRow('Device Type', deviceInfo.isTablet ? 'Tablet' : 'Phone'),
          _buildInfoRow('Has Notch', deviceInfo.hasNotch ? 'Yes' : 'No'),
          _buildInfoRow('Safe Area', 'Top: ${deviceInfo.safeAreaInsets.top}, Bottom: ${deviceInfo.safeAreaInsets.bottom}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Mobile settings dialog
class _MobileSettingsDialog extends StatelessWidget {
  const _MobileSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Mobile Settings'),
        ],
      ),
      content: const Text('Mobile-specific settings would be configured here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Mobile help dialog
class _MobileHelpDialog extends StatelessWidget {
  const _MobileHelpDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Mobile Gestures'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGestureHelp('Pull to Refresh', 'Pull down to refresh drives and data'),
          _buildGestureHelp('Swipe Left', 'Swipe left to organize files'),
          _buildGestureHelp('Swipe Right', 'Swipe right to cancel operations'),
          _buildGestureHelp('Long Press', 'Long press to show options menu'),
          _buildGestureHelp('Tap', 'Tap buttons for haptic feedback'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildGestureHelp(String gesture, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              gesture,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
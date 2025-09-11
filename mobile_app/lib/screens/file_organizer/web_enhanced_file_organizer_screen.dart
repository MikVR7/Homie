import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/file_organizer_provider.dart';
import '../../services/web_platform_service.dart';
import '../file_organizer/modern_file_organizer_screen.dart';

/// Web-enhanced File Organizer Screen with drag-and-drop and responsive design
class WebEnhancedFileOrganizerScreen extends StatefulWidget {
  final bool isStandaloneLaunch;

  const WebEnhancedFileOrganizerScreen({
    Key? key,
    this.isStandaloneLaunch = false,
  }) : super(key: key);

  @override
  State<WebEnhancedFileOrganizerScreen> createState() => 
      _WebEnhancedFileOrganizerScreenState();
}

class _WebEnhancedFileOrganizerScreenState 
    extends State<WebEnhancedFileOrganizerScreen> {
  bool _isDragActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize web-specific features
    if (kIsWeb) {
      _initializeWebFeatures();
    }
  }

  void _initializeWebFeatures() {
    // Check available web platform features
    final features = WebPlatformService.getPlatformFeatures();
    
    if (features['dragDrop'] == true) {
      // Enable drag and drop functionality
      debugPrint('Drag and drop is available');
    }
    
    if (features['fileSystemAccess'] == true) {
      // Enable File System Access API
      debugPrint('File System Access API is available');
    }
  }

  void _handleFilesDropped(List<String> filePaths) {
    setState(() {
      _isDragActive = false;
    });

    // Show notification about dropped files
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${filePaths.length} files ready for organization'),
        action: SnackBarAction(
          label: 'Organize',
          onPressed: () => _organizeFiles(filePaths),
        ),
      ),
    );
  }

  void _organizeFiles(List<String> filePaths) {
    final provider = context.read<FileOrganizerProvider>();
    
    // This would integrate with the existing file organization logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing ${filePaths.length} files...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebEnhancedLayout(context);
  }

  Widget _buildWebEnhancedLayout(BuildContext context) {
    final child = ModernFileOrganizerScreen(
      isStandaloneLaunch: widget.isStandaloneLaunch,
    );

    // Add web-specific enhancements
    if (kIsWeb) {
      return _buildWebContainer(context, child);
    }

    return child;
  }

  Widget _buildWebContainer(BuildContext context, Widget child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 1200 ? 1200.0 : screenWidth;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Web platform features banner
          if (WebPlatformService.isWebPlatform)
            _buildWebFeaturesBanner(context),
          
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildWebFeaturesBanner(BuildContext context) {
    final theme = Theme.of(context);
    final features = WebPlatformService.getPlatformFeatures();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.web,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Web Platform Features',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getFeaturesSummary(features),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFeaturesSummary(Map<String, bool> features) {
    final availableFeatures = features.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (availableFeatures.isEmpty) {
      return 'Basic web functionality available';
    }
    
    return 'Available: ${availableFeatures.join(', ')}';
  }
}


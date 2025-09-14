import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/animations/material_motion.dart';
import 'package:homie_app/animations/skeleton_loading.dart';
import 'package:homie_app/animations/micro_interactions.dart';
import 'package:homie_app/animations/animation_controller.dart';
import 'package:homie_app/widgets/file_organizer/modern/modern_file_browser.dart';
import 'package:homie_app/widgets/file_organizer/modern/enhanced_drive_monitor.dart';
import 'package:homie_app/widgets/file_organizer/modern/ai_operations_preview.dart';
import 'package:homie_app/widgets/file_organizer/modern/progress_tracker.dart';
import 'package:homie_app/widgets/file_organizer/modern/organization_assistant.dart';
import 'package:homie_app/widgets/file_organizer/modern/file_insights_dashboard.dart';
import 'package:homie_app/widgets/file_organizer/modern/enhanced_organization_selector.dart';
import 'package:homie_app/config/app_arguments.dart';

/// Modern File Organizer Screen with Material Design 3
/// Task 6.1: Enhanced main screen layout with modern UI
class ModernFileOrganizerScreen extends StatefulWidget {
  final bool isStandaloneLaunch;

  const ModernFileOrganizerScreen({
    super.key,
    this.isStandaloneLaunch = false,
  });

  @override
  State<ModernFileOrganizerScreen> createState() => _ModernFileOrganizerScreenState();
}

class _ModernFileOrganizerScreenState extends State<ModernFileOrganizerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProviders();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileOrganizerProvider = context.read<FileOrganizerProvider>();
      final webSocketProvider = context.read<WebSocketProvider>();
      
      // Use AppArguments configuration for initial paths
      final config = AppArguments.instance.fileOrganizerConfig;
      
      // Initialize paths from arguments or defaults
      if (fileOrganizerProvider.sourcePath.isEmpty) {
        fileOrganizerProvider.setSourcePath(config.getSourcePath());
      }
      if (fileOrganizerProvider.destinationPath.isEmpty) {
        fileOrganizerProvider.setDestinationPath(config.getDestinationPath());
      }

      // Connect WebSocket if not connected
      if (!webSocketProvider.isConnected) {
        webSocketProvider.connect();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimationPresets.quickFadeIn(
        child: _buildResponsiveLayout(),
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          return _buildWideScreenLayout();
        } else if (isMediumScreen) {
          return _buildMediumScreenLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: _buildSidebarNavigation(),
        ),
        
        // Main Content Area
        Expanded(
          flex: 2,
          child: _buildMainContent(),
        ),
        
        // Right Panel (Insights/Progress)
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              left: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: _buildRightPanel(),
        ),
      ],
    );
  }

  Widget _buildMediumScreenLayout() {
    return Column(
      children: [
        _buildModernAppBar(),
        Expanded(
          child: Row(
            children: [
              // Main Content
              Expanded(
                flex: 2,
                child: _buildMainContent(),
              ),
              
              // Side Panel
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildRightPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return AnimationPresets.staggeredList(
      children: [
        _buildModernAppBar(),
        _buildTabNavigation(),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            children: [
              AnimationPresets.quickFadeIn(child: _buildMainContent()),
              AnimationPresets.quickFadeIn(child: _buildRightPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Back Button (if not standalone)
              if (!widget.isStandaloneLaunch) ...[
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.onSurface,
                  ),
                  onPressed: () => GoRouter.of(context).go('/'),
                ),
                const SizedBox(width: 8),
              ],

              // App Icon and Title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI File Organizer',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Consumer<FileOrganizerProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        _getStatusText(provider),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const Spacer(),

              // Connection Status
              Consumer<WebSocketProvider>(
                builder: (context, wsProvider, child) {
                  return _buildConnectionStatus(wsProvider);
                },
              ),

              const SizedBox(width: 16),

              // Settings Button
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: _showSettingsDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(WebSocketProvider wsProvider) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (wsProvider.connectionStatus) {
      case ConnectionStatus.connected:
        statusColor = AppColors.success;
        statusIcon = Icons.wifi_rounded;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = AppColors.warning;
        statusIcon = Icons.wifi_find_rounded;
        statusText = 'Connecting';
        break;
      case ConnectionStatus.disconnected:
        statusColor = AppColors.error;
        statusIcon = Icons.wifi_off_rounded;
        statusText = 'Disconnected';
        break;
      case ConnectionStatus.authenticated:
        statusColor = AppColors.success;
        statusIcon = Icons.verified_rounded;
        statusText = 'Ready';
        break;
      case ConnectionStatus.error:
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        statusText = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.tune_rounded,
            label: 'Organize',
            isSelected: _selectedTabIndex == 0,
          ),
          _buildTabButton(
            index: 1,
            icon: Icons.insights_rounded,
            label: 'Insights',
            isSelected: _selectedTabIndex == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarNavigation() {
    return Column(
      children: [
        // Header
        Container(
          height: 80,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File Organizer',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildNavItem(
                icon: Icons.tune_rounded,
                label: 'Organization',
                isSelected: _selectedTabIndex == 0,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.insights_rounded,
                label: 'Insights',
                isSelected: _selectedTabIndex == 1,
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
              _buildNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isSelected: _selectedTabIndex == 2,
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: false,
                onTap: _showSettingsDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMainContent() {
    // Show different content based on selected tab
    switch (_selectedTabIndex) {
      case 0: // Organization
        return _buildOrganizationTab();
      case 1: // Insights
        return _buildInsightsTab();
      case 2: // History
        return _buildHistoryTab();
      default:
        return _buildOrganizationTab();
    }
  }

  Widget _buildOrganizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(), // Prevent overscroll and limit scrolling to content bounds
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Only take up the space needed by content
        children: [
          // Welcome Section
          _buildWelcomeSection(),
          
          const SizedBox(height: 32),

          // Configuration Panel
          _buildConfigurationPanel(),

          const SizedBox(height: 24),

          // Drive Monitor
          const EnhancedDriveMonitor(),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),

          // Operations Preview
          Consumer<FileOrganizerProvider>(
            builder: (context, provider, child) {
              if (provider.operations.isNotEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 32),
                    Consumer<FileOrganizerProvider>(
                      builder: (context, provider, child) {
                        return AIOperationsPreview(
                          operations: provider.operations,
                          onOperationsModified: (modifiedOps) {
                            provider.updateOperations(modifiedOps);
                          },
                          onExecute: () => provider.executeOperations(),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Progress Tracker
          Consumer<FileOrganizerProvider>(
            builder: (context, provider, child) {
              if (provider.status != OperationStatus.idle) {
                return Column(
                  children: [
                    const SizedBox(height: 32),
                    const ProgressTracker(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered File Organization',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let AI intelligently organize your files based on content, type, and your preferences. Select folders below to get started.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Only take space needed for content
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Organization Configuration',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Only take space needed for content
              children: [
                // Source and Destination Folder Selection
                _buildFolderSelectionSection(),
                
                const SizedBox(height: 24),
                
                // Organization Style Selection
                _buildOrganizationStyleSection(),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                onPressed: provider.status == OperationStatus.idle
                    ? () => provider.analyzeFolder()
                    : null,
                icon: provider.status == OperationStatus.analyzing
                    ? Icons.hourglass_empty_rounded
                    : Icons.psychology_rounded,
                label: provider.status == OperationStatus.analyzing
                    ? 'Analyzing...'
                    : 'Analyze Files',
                isLoading: provider.status == OperationStatus.analyzing,
                backgroundColor: AppColors.primary,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: _buildPrimaryButton(
                onPressed: provider.operations.isNotEmpty &&
                    provider.status == OperationStatus.idle
                    ? () => provider.executeOperations()
                    : null,
                icon: provider.status == OperationStatus.executing
                    ? Icons.hourglass_empty_rounded
                    : Icons.play_arrow_rounded,
                label: provider.status == OperationStatus.executing
                    ? 'Executing...'
                    : 'Execute Operations',
                isLoading: provider.status == OperationStatus.executing,
                backgroundColor: provider.operations.isNotEmpty
                    ? AppColors.success
                    : AppColors.surfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    required Color backgroundColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    onPressed != null ? AppColors.onPrimary : AppColors.textMuted,
                  ),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: onPressed != null
              ? (backgroundColor == AppColors.surfaceVariant
                  ? AppColors.textMuted
                  : AppColors.onPrimary)
              : AppColors.textMuted,
          elevation: onPressed != null ? 2 : 0,
          shadowColor: backgroundColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      physics: ClampingScrollPhysics(), // Prevent overscroll and limit scrolling to content bounds
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Only take up the space needed by content
        children: [
          // File Insights Dashboard
          FileInsightsDashboard(),
        ],
      ),
    );
  }

  String _getStatusText(FileOrganizerProvider provider) {
    switch (provider.status) {
      case OperationStatus.idle:
        return 'Ready to organize files';
      case OperationStatus.analyzing:
        return 'Analyzing files...';
      case OperationStatus.executing:
        return 'Organizing files...';
      case OperationStatus.completed:
        return 'Organization complete';
      case OperationStatus.error:
        return 'Error occurred';
      case OperationStatus.paused:
        return 'Operation paused';
      case OperationStatus.cancelled:
        return 'Operation cancelled';
      default:
        return 'Ready';
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside to close
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // X button in top-right corner
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
        content: Text(
          'Settings panel coming soon...\n\nThis will include preferences for:\n• Default organization styles\n• File type associations\n• Notification settings\n• Performance options',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          // Close button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(), // Prevent overscroll and limit scrolling to content bounds
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Only take up the space needed by content
        children: [
          // Header
          Text(
            'File Insights',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyze your files and get intelligent organization recommendations',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // File Insights Dashboard
          const FileInsightsDashboard(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(), // Prevent overscroll and limit scrolling to content bounds
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Only take up the space needed by content
        children: [
          // Header
          Text(
            'Organization History',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review past organization operations and reuse successful patterns',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Organization History Component
          _buildOrganizationHistory(),
        ],
      ),
    );
  }

  Widget _buildOrganizationHistory() {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, child) {
        // Placeholder for organization history
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Organization History Yet',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start organizing files to see your history here.\nSuccessful patterns will be saved for quick reuse.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderSelectionSection() {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Only take space needed for content
          children: [
            Text(
              'Folder Configuration',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Source Folder
            _buildFolderInput(
              label: 'Source Folder',
              value: provider.sourcePath,
              hint: 'Choose the folder containing files to organize',
              icon: Icons.folder_open_rounded,
              onTap: () => _selectFolder(context, true),
            ),
            
            const SizedBox(height: 16),
            
            // Destination Folder
            _buildFolderInput(
              label: 'Destination Folder',
              value: provider.destinationPath,
              hint: 'Choose where organized files will be placed',
              icon: Icons.folder_special_rounded,
              onTap: () => _selectFolder(context, false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderInput({
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.isNotEmpty ? value : hint,
                        style: TextStyle(
                          color: value.isNotEmpty 
                              ? AppColors.onSurface 
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: value.isNotEmpty 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (value.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectFolder(BuildContext context, bool isSource) async {
    final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
    
    try {
      // Use the native directory picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        print('Selected path: $selectedDirectory');
        if (isSource) {
          provider.setSourcePath(selectedDirectory);
        } else {
          provider.setDestinationPath(selectedDirectory);
        }
      } else {
        print('User cancelled folder selection');
      }
    } catch (e) {
      print('Error selecting folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeFiles() async {
    final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
    
    if (provider.sourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source folder first')),
      );
      return;
    }

    // Debug: Check current paths
    print('DEBUG: Starting analysis with:');
    print('  Source: ${provider.sourcePath}');
    print('  Destination: ${provider.destinationPath}');
    print('  Organization Style: ${provider.organizationStyle}');

    try {
      await provider.analyzeFolder();
      print('DEBUG: Analysis completed. Operations found: ${provider.operations.length}');
      
      if (provider.operations.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis complete! Found ${provider.operations.length} operations to preview.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis complete, but no operations were generated. Check if source folder has files.')),
        );
      }
    } catch (e) {
      print('DEBUG: Analysis failed with error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

  Future<void> _executeOperations() async {
    final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
    
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please analyze files first to see what will be organized')),
      );
      return;
    }

    try {
      await provider.executeOperations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Files organized successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Organization failed: $e')),
      );
    }
  }

  Widget _buildOrganizationStyleSection() {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Only take space needed for content
          children: [
            Text(
              'Organization Style',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how your files should be organized',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // Organization style options
            _buildStyleOption(
              title: 'By File Type',
              description: 'Group files by their extensions (images, documents, etc.)',
              icon: Icons.category_rounded,
              isSelected: provider.organizationStyle == OrganizationStyle.byType,
              onTap: () => provider.setOrganizationStyle(OrganizationStyle.byType),
            ),
            
            const SizedBox(height: 12),
            
            _buildStyleOption(
              title: 'By Date',
              description: 'Organize files by creation or modification date',
              icon: Icons.date_range_rounded,
              isSelected: provider.organizationStyle == OrganizationStyle.byDate,
              onTap: () => provider.setOrganizationStyle(OrganizationStyle.byDate),
            ),
            
            const SizedBox(height: 12),
            
            _buildStyleOption(
              title: 'Smart Categories',
              description: 'AI-powered organization based on content and context',
              icon: Icons.psychology_rounded,
              isSelected: provider.organizationStyle == OrganizationStyle.smartCategories,
              onTap: () => provider.setOrganizationStyle(OrganizationStyle.smartCategories),
            ),
            
            const SizedBox(height: 12),
            
            _buildStyleOption(
              title: 'Custom Pattern',
              description: 'Define your own organization rules',
              icon: Icons.tune_rounded,
              isSelected: provider.organizationStyle == OrganizationStyle.custom,
              onTap: () => provider.setOrganizationStyle(OrganizationStyle.custom),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStyleOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.border.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Only take space needed for content
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                title: 'Preview Changes',
                description: 'See what will happen',
                icon: Icons.preview_rounded,
                color: AppColors.secondary,
                onTap: () => _analyzeFiles(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                title: 'Start Organizing',
                description: 'Apply changes now',
                icon: Icons.play_arrow_rounded,
                color: AppColors.primary,
                onTap: () => _executeOperations(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
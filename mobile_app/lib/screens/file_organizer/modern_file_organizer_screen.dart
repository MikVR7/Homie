import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/animations/material_motion.dart';
import 'package:homie_app/animations/skeleton_loading.dart';
import 'package:homie_app/animations/micro_interactions.dart';
import 'package:homie_app/animations/animation_controller.dart';
import 'package:homie_app/widgets/file_organizer/modern/file_insights_dashboard.dart';
import 'package:homie_app/screens/file_organizer/dialogs/settings_dialog.dart';
import 'package:homie_app/screens/file_organizer/panels/right_insights_panel.dart';
import 'package:homie_app/screens/file_organizer/tabs/organization_tab.dart';
import 'package:homie_app/screens/file_organizer/tabs/insights_tab.dart';
import 'package:homie_app/screens/file_organizer/tabs/history_tab.dart';
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
  late final ScrollController _organizationScrollController; // kept for compatibility with layout but not used by tabs

  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _organizationScrollController = ScrollController();
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
    _organizationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          scrollbars: true,
          physics: const ClampingScrollPhysics(),
        ),
        child: AnimationPresets.quickFadeIn(
          child: _buildResponsiveLayout(),
        ),
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
        return const OrganizationTab();
      case 1: // Insights
        return const InsightsTab();
      case 2: // History
        return const HistoryTab();
      default:
        return const OrganizationTab();
    }
  }

  Widget _buildWelcomeSection() => const SizedBox.shrink();

  Widget _buildConfigurationPanel() => const SizedBox.shrink();

  Widget _buildActionButtons() => const SizedBox.shrink();

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    required Color backgroundColor,
  }) => const SizedBox.shrink();

  Widget _buildRightPanel() => const RightInsightsPanel();

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
    showDialog(context: context, barrierDismissible: true, builder: (_) => const HomieSettingsDialog());
  }

  Widget _buildInsightsTab() => const SizedBox.shrink();

  Widget _buildHistoryTab() => const SizedBox.shrink();

  Widget _buildOrganizationHistory() => const SizedBox.shrink();

  Widget _buildFolderSelectionSection() => const SizedBox.shrink();

  Widget _buildFolderInput({
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) => const SizedBox.shrink();

  Future<void> _selectFolder(BuildContext context, bool isSource) async {}

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

  Widget _buildOrganizationStyleSection() => const SizedBox.shrink();

  Widget _buildStyleOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) => const SizedBox.shrink();

  Widget _buildQuickActionsSection() => const SizedBox.shrink();

  Widget _buildQuickActionButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => const SizedBox.shrink();
}
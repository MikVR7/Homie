import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/widgets/file_organizer/modern/enhanced_drive_monitor.dart';
import 'package:homie_app/widgets/file_organizer/modern/ai_operations_preview.dart';
import 'package:homie_app/widgets/file_organizer/modern/progress_tracker.dart';
import 'package:homie_app/screens/file_organizer/tabs/sections/welcome_header.dart';
import 'package:homie_app/screens/file_organizer/tabs/sections/folder_configuration_section.dart';
import 'package:homie_app/screens/file_organizer/tabs/sections/organization_style_section.dart';
import 'package:homie_app/screens/file_organizer/tabs/sections/quick_actions_section.dart';

class OrganizationTab extends StatefulWidget {
  const OrganizationTab({super.key});

  @override
  State<OrganizationTab> createState() => _OrganizationTabState();
}

class _OrganizationTabState extends State<OrganizationTab> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectFolder(BuildContext context, bool isSource) async {
    final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        if (isSource) {
          provider.setSourcePath(selectedDirectory);
        } else {
          provider.setDestinationPath(selectedDirectory);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      radius: const Radius.circular(6),
      thumbColor: AppColors.primary,
      notificationPredicate: (notification) => true,
      child: CustomScrollView(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const WelcomeHeader(),
                const SizedBox(height: 32),
                _buildConfigurationPanel(context),
                const SizedBox(height: 24),
                const EnhancedDriveMonitor(),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Consumer<FileOrganizerProvider>(
                builder: (context, provider, child) {
                  if (provider.operations.isNotEmpty) {
                    return Column(
                      children: [
                        const SizedBox(height: 32),
                        AIOperationsPreview(
                          operations: provider.operations,
                          onOperationsModified: provider.updateOperations,
                          onExecute: () => provider.executeOperations(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Consumer<FileOrganizerProvider>(
                builder: (context, provider, child) {
                  if (provider.status != OperationStatus.idle) {
                    return const Column(
                      children: [
                        SizedBox(height: 32),
                        ProgressTracker(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  // Welcome header is now in its own widget

  Widget _buildConfigurationPanel(BuildContext context) {
    final provider = context.watch<FileOrganizerProvider>();
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
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FolderConfigurationSection(),
                const SizedBox(height: 24),
                OrganizationStyleSection(),
                const SizedBox(height: 24),
                const QuickActionsSection(),
              ],
            ),
          ),
        ],
      ),
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
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value.isNotEmpty ? AppColors.onSurface : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationStyleSection(BuildContext context, FileOrganizerProvider provider) {
    Widget option(String title, String desc, IconData icon, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border.withOpacity(0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Organization Style', style: TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Choose how your files should be organized', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        option('By File Type', 'Group files by their extensions (images, documents, etc.)', Icons.category_rounded, provider.organizationStyle == OrganizationStyle.byType, () => provider.setOrganizationStyle(OrganizationStyle.byType)),
        const SizedBox(height: 12),
        option('By Date', 'Organize files by creation or modification date', Icons.date_range_rounded, provider.organizationStyle == OrganizationStyle.byDate, () => provider.setOrganizationStyle(OrganizationStyle.byDate)),
        const SizedBox(height: 12),
        option('Smart Categories', 'AI-powered organization based on content and context', Icons.psychology_rounded, provider.organizationStyle == OrganizationStyle.smartCategories, () => provider.setOrganizationStyle(OrganizationStyle.smartCategories)),
        const SizedBox(height: 12),
        option('Custom Pattern', 'Define your own organization rules', Icons.tune_rounded, provider.organizationStyle == OrganizationStyle.custom, () => provider.setOrganizationStyle(OrganizationStyle.custom)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child: _primaryButton(
                onPressed: provider.status == OperationStatus.idle ? () => provider.analyzeFolder() : null,
                icon: provider.status == OperationStatus.analyzing ? Icons.hourglass_empty_rounded : Icons.psychology_rounded,
                label: provider.status == OperationStatus.analyzing ? 'Analyzing...' : 'Analyze Files',
                isLoading: provider.status == OperationStatus.analyzing,
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _primaryButton(
                onPressed: provider.operations.isNotEmpty && provider.status == OperationStatus.idle ? () => provider.executeOperations() : null,
                icon: provider.status == OperationStatus.executing ? Icons.hourglass_empty_rounded : Icons.play_arrow_rounded,
                label: provider.status == OperationStatus.executing ? 'Executing...' : 'Execute Operations',
                isLoading: provider.status == OperationStatus.executing,
                backgroundColor: provider.operations.isNotEmpty ? AppColors.success : AppColors.surfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _primaryButton({
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
                  valueColor: AlwaysStoppedAnimation<Color>(onPressed != null ? AppColors.onPrimary : AppColors.textMuted),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: onPressed != null
              ? (backgroundColor == AppColors.surfaceVariant ? AppColors.textMuted : AppColors.onPrimary)
              : AppColors.textMuted,
          elevation: onPressed != null ? 2 : 0,
          shadowColor: backgroundColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, FileOrganizerProvider provider) {
    Widget action(String title, String description, IconData icon, Color color, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(color: AppColors.onSurface, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Quick Actions', style: TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: action('Preview Changes', 'See what will happen', Icons.preview_rounded, AppColors.secondary, () => provider.analyzeFolder())),
            const SizedBox(width: 12),
            Expanded(child: action('Start Organizing', 'Apply changes now', Icons.play_arrow_rounded, AppColors.primary, () => provider.executeOperations())),
          ],
        ),
      ],
    );
  }
}



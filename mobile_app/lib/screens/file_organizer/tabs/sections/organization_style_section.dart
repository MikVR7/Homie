import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class OrganizationStyleSection extends StatelessWidget {
  const OrganizationStyleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileOrganizerProvider>();

    Widget option(String title, String desc, IconData icon, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border.withOpacity(0.5), width: selected ? 2 : 1),
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
}



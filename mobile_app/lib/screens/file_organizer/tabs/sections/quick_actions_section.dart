import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileOrganizerProvider>();

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



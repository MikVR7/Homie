import 'package:flutter/material.dart';
import 'package:homie_app/models/file_organizer_models.dart';
import 'package:homie_app/theme/app_theme.dart';

class StatsCard extends StatelessWidget {
  final OrganizationStats stats;

  const StatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  'Total Files',
                  stats.totalFiles.toString(),
                  Icons.insert_drive_file_outlined,
                ),
                _buildStatItem(
                  context,
                  'Organized',
                  stats.organizedFiles.toString(),
                  Icons.check_circle_outline,
                ),
                _buildStatItem(
                  context,
                  'Rules',
                  stats.rulesCount.toString(),
                  Icons.rule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'File Types',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: stats.fileTypeBreakdown.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Last organized: ${_formatDate(stats.lastOrganized)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 
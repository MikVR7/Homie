import 'package:flutter/material.dart';
import 'package:homie_app/theme/app_theme.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Organization History',
            style: TextStyle(color: AppColors.onSurface, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Review past organization operations and reuse successful patterns',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _historyPlaceholder(),
        ],
      ),
    );
  }

  Widget _historyPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No Organization History Yet', style: TextStyle(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Start organizing files to see your history here.\nSuccessful patterns will be saved for quick reuse.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}



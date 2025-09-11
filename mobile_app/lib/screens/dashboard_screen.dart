import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/widgets/module_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Homie',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your home efficiently with our integrated tools',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Modules Section Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Modules',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Module Grid
            _buildModuleGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            ModuleCard(
              title: 'File Organizer',
              description: 'Smart file organization with AI',
              icon: Icons.folder_outlined,
              status: 'Active',
              statusColor: AppColors.success,
              onTap: () => context.go('/file-organizer'),
            ),
            ModuleCard(
              title: 'Financial Manager',
              description: 'Track expenses and budgets',
              icon: Icons.account_balance_wallet_outlined,
              status: 'Active',
              statusColor: AppColors.success,
              onTap: () => context.go('/financial'),
            ),
            ModuleCard(
              title: 'Media Manager',
              description: 'Organize photos and videos',
              icon: Icons.perm_media_outlined,
              status: 'Coming Soon',
              statusColor: AppColors.warning,
              onTap: () => _showComingSoonDialog(context),
            ),
            ModuleCard(
              title: 'Document Manager',
              description: 'Digital document storage',
              icon: Icons.description_outlined,
              status: 'Coming Soon',
              statusColor: AppColors.warning,
              onTap: () => _showComingSoonDialog(context),
            ),
          ],
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Coming Soon',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'This module is planned for future development.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
} 
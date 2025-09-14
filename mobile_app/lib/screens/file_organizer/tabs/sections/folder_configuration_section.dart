import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class FolderConfigurationSection extends StatelessWidget {
  const FolderConfigurationSection({super.key});

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
    final provider = context.watch<FileOrganizerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        _buildFolderInput(
          context,
          label: 'Source Folder',
          value: provider.sourcePath,
          hint: 'Choose the folder containing files to organize',
          icon: Icons.folder_open_rounded,
          onTap: () => _selectFolder(context, true),
        ),
        const SizedBox(height: 24),
        _buildFolderInput(
          context,
          label: 'Destination Folder',
          value: provider.destinationPath,
          hint: 'Choose where organized files will be placed',
          icon: Icons.folder_special_rounded,
          onTap: () => _selectFolder(context, false),
        ),
      ],
    );
  }

  Widget _buildFolderInput(
    BuildContext context, {
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
              border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
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
}



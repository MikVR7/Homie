import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class FolderConfigurationSection extends StatelessWidget {
  const FolderConfigurationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileOrganizerProvider>();
    debugPrint('[FolderConfigurationSection] render, sourceCount=' + provider.recentSourceFolders.length.toString() + ', destCount=' + provider.recentDestinationFolders.length.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEBUG: provider loaded', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        Text('Source Folders (' + provider.recentSourceFolders.length.toString() + ')',
            style: TextStyle(color: AppColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
        _buildRecentList(
          title: 'Source Folders',
          items: provider.recentSourceFolders,
          onAdd: () async {
            final providerRW = Provider.of<FileOrganizerProvider>(context, listen: false);
            String? dir = await FilePicker.platform.getDirectoryPath();
            if (dir != null && dir.isNotEmpty) {
              providerRW.setSourcePath(dir);
            }
          },
          onRemove: (path) => provider.removeRecentSourceFolder(path),
          onSelect: (path) => provider.setSourcePath(path),
          emptyLabel: 'No source folders selected yet',
        ),
        const SizedBox(height: 16),
        Text('Destination Folders (' + provider.recentDestinationFolders.length.toString() + ')',
            style: TextStyle(color: AppColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
        _buildRecentList(
          title: 'Destination Folders',
          items: provider.recentDestinationFolders,
          onAdd: () async {
            final providerRW = Provider.of<FileOrganizerProvider>(context, listen: false);
            String? dir = await FilePicker.platform.getDirectoryPath();
            if (dir != null && dir.isNotEmpty) {
              providerRW.setDestinationPath(dir);
            }
          },
          onRemove: (path) => provider.removeRecentDestinationFolder(path),
          onSelect: (path) => provider.setDestinationPath(path),
          emptyLabel: 'No destination folders selected yet',
        ),
      ],
    );
  }

  Widget _buildRecentList({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    required void Function(String) onSelect,
    required String emptyLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              alignment: Alignment.centerLeft,
              color: Colors.white12,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text('DEBUG: list container visible', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Folder'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white10,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(emptyLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              )
            else
              Column(
                children: items.map((path) {
                  return InkWell(
                    onTap: () => onSelect(path),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          IconButton(
                            tooltip: 'Remove from list',
                            onPressed: () => onRemove(path),
                            icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}



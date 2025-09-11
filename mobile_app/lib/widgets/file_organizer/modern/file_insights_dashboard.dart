import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/services/api_service.dart';

/// Comprehensive file insights dashboard with analytics, visualizations,
/// and actionable recommendations for storage optimization
class FileInsightsDashboard extends StatefulWidget {
  final String? folderPath;
  final bool showComparison;
  final VoidCallback? onActionRequired;

  const FileInsightsDashboard({
    Key? key,
    this.folderPath,
    this.showComparison = false,
    this.onActionRequired,
  }) : super(key: key);

  @override
  State<FileInsightsDashboard> createState() => _FileInsightsDashboardState();
}

class _FileInsightsDashboardState extends State<FileInsightsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = false;
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _duplicateFiles = [];
  List<Map<String, dynamic>> _largeFiles = [];
  Map<String, dynamic> _storageAnalysis = {};
  Map<String, dynamic> _beforeAfterComparison = {};
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (widget.folderPath == null) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadFileTypeDistribution(),
        _loadStorageAnalysis(),
        _loadDuplicateFiles(),
        _loadLargeFiles(),
        _loadRecommendations(),
        if (widget.showComparison) _loadBeforeAfterComparison(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load insights: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFileTypeDistribution() async {
    try {
      final apiService = ApiService();
      final result = await apiService.browsePath(widget.folderPath!);

      if (result['success'] == true) {
        setState(() {
          _insights = result['file_analysis'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('Failed to load file type distribution: $e');
    }
  }

  Future<void> _loadStorageAnalysis() async {
    try {
      // Mock storage analysis data
      setState(() {
        _storageAnalysis = {
          'total_size': 2.5 * 1024 * 1024 * 1024, // 2.5 GB
          'used_space': 1.8 * 1024 * 1024 * 1024, // 1.8 GB
          'free_space': 0.7 * 1024 * 1024 * 1024, // 0.7 GB
          'trends': [
            {'month': 'Jan', 'size': 1.2},
            {'month': 'Feb', 'size': 1.4},
            {'month': 'Mar', 'size': 1.6},
            {'month': 'Apr', 'size': 1.8},
          ],
          'growth_rate': 0.15, // 15% monthly growth
          'projected_full': '6 months',
        };
      });
    } catch (e) {
      debugPrint('Failed to load storage analysis: $e');
    }
  }

  Future<void> _loadDuplicateFiles() async {
    try {
      // Mock duplicate files data
      setState(() {
        _duplicateFiles = [
          {
            'id': '1',
            'name': 'vacation-photo.jpg',
            'size': 2.5 * 1024 * 1024, // 2.5 MB
            'count': 3,
            'paths': [
              '/home/user/Downloads/vacation-photo.jpg',
              '/home/user/Pictures/vacation-photo.jpg',
              '/home/user/Desktop/vacation-photo (1).jpg',
            ],
            'hash': 'abc123def456',
            'potential_savings': 5.0 * 1024 * 1024, // 5 MB
          },
          {
            'id': '2',
            'name': 'presentation.pptx',
            'size': 8.2 * 1024 * 1024, // 8.2 MB
            'count': 2,
            'paths': [
              '/home/user/Documents/presentation.pptx',
              '/home/user/Downloads/presentation (2).pptx',
            ],
            'hash': 'def456ghi789',
            'potential_savings': 8.2 * 1024 * 1024, // 8.2 MB
          },
        ];
      });
    } catch (e) {
      debugPrint('Failed to load duplicate files: $e');
    }
  }

  Future<void> _loadLargeFiles() async {
    try {
      // Mock large files data
      setState(() {
        _largeFiles = [
          {
            'id': '1',
            'name': 'old-backup.zip',
            'size': 250 * 1024 * 1024, // 250 MB
            'path': '/home/user/Downloads/old-backup.zip',
            'last_accessed': DateTime.now().subtract(const Duration(days: 180)),
            'type': 'Archive',
            'recommendation': 'Move to external storage or delete',
            'priority': 'high',
          },
          {
            'id': '2',
            'name': 'project-video.mp4',
            'size': 180 * 1024 * 1024, // 180 MB
            'path': '/home/user/Videos/project-video.mp4',
            'last_accessed': DateTime.now().subtract(const Duration(days: 30)),
            'type': 'Video',
            'recommendation': 'Compress or move to archive',
            'priority': 'medium',
          },
          {
            'id': '3',
            'name': 'dataset.csv',
            'size': 95 * 1024 * 1024, // 95 MB
            'path': '/home/user/Documents/dataset.csv',
            'last_accessed': DateTime.now().subtract(const Duration(days: 7)),
            'type': 'Data',
            'recommendation': 'Consider compression',
            'priority': 'low',
          },
        ];
      });
    } catch (e) {
      debugPrint('Failed to load large files: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _recommendations = [
          {
            'id': '1',
            'type': 'storage_optimization',
            'title': 'Remove Duplicate Files',
            'description': 'Found 5 duplicate files that could save 23.2 MB',
            'impact': 'medium',
            'action': 'cleanup_duplicates',
            'potential_savings': '23.2 MB',
          },
          {
            'id': '2',
            'type': 'organization',
            'title': 'Organize Downloads Folder',
            'description': '47 files in Downloads could be better organized',
            'impact': 'high',
            'action': 'organize_downloads',
            'potential_savings': 'Better organization',
          },
          {
            'id': '3',
            'type': 'cleanup',
            'title': 'Archive Old Files',
            'description': '12 files haven\'t been accessed in 6+ months',
            'impact': 'low',
            'action': 'archive_old_files',
            'potential_savings': '145 MB',
          },
        ];
      });
    } catch (e) {
      debugPrint('Failed to load recommendations: $e');
    }
  }

  Future<void> _loadBeforeAfterComparison() async {
    try {
      setState(() {
        _beforeAfterComparison = {
          'before': {
            'total_files': 1250,
            'organized_files': 340,
            'duplicate_files': 45,
            'large_files': 28,
            'total_size': 2.5 * 1024 * 1024 * 1024,
            'wasted_space': 156 * 1024 * 1024,
          },
          'after': {
            'total_files': 1205,
            'organized_files': 1180,
            'duplicate_files': 3,
            'large_files': 15,
            'total_size': 2.3 * 1024 * 1024 * 1024,
            'wasted_space': 12 * 1024 * 1024,
          },
          'improvements': {
            'files_organized': 840,
            'duplicates_removed': 42,
            'space_saved': 200 * 1024 * 1024,
            'organization_score': 0.95,
          },
        };
      });
    } catch (e) {
      debugPrint('Failed to load before/after comparison: $e');
    }
  }

  Widget _buildOverviewTab() {
    final fileTypes = _insights['file_types'] as Map<String, dynamic>? ?? {};
    final totalFiles = _insights['total_files'] ?? 0;
    final totalSize = _insights['total_size'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Files',
                  totalFiles.toString(),
                  Icons.insert_drive_file,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Size',
                  _formatFileSize(totalSize.toDouble()),
                  Icons.storage,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Duplicates',
                  _duplicateFiles.length.toString(),
                  Icons.content_copy,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Large Files',
                  _largeFiles.length.toString(),
                  Icons.folder_zip,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // File Type Distribution
          Text(
            'File Type Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFileTypeChart(fileTypes),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeChart(Map<String, dynamic> fileTypes) {
    if (fileTypes.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text('No file type data available'),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: fileTypes.entries.map((entry) {
                  final index = fileTypes.keys.toList().indexOf(entry.key);
                  final color = colors[index % colors.length];
                  final percentage = (entry.value / fileTypes.values.reduce((a, b) => a + b) * 100);
                  
                  return Expanded(
                    flex: entry.value as int,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${percentage.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: fileTypes.entries.map((entry) {
                final index = fileTypes.keys.toList().indexOf(entry.key);
                final color = colors[index % colors.length];
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDuplicateFiles(),
                icon: const Icon(Icons.content_copy),
                label: const Text('Find Duplicates'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showLargeFiles(),
                icon: const Icon(Icons.folder_zip),
                label: const Text('Large Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _generateRecommendations(),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Get Recommendations'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_copy, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Duplicate Files',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_duplicateFiles.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _cleanupAllDuplicates,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clean All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_duplicateFiles.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No duplicate files found',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your files are well organized!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _duplicateFiles.length,
                itemBuilder: (context, index) {
                  final duplicate = _duplicateFiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          '${duplicate['count']}x',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(duplicate['name'] ?? 'Unknown'),
                      subtitle: Text(
                        'Size: ${_formatFileSize(duplicate['size']?.toDouble() ?? 0)} • '
                        'Potential savings: ${_formatFileSize(duplicate['potential_savings']?.toDouble() ?? 0)}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duplicate locations:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...((duplicate['paths'] as List<dynamic>?) ?? []).map(
                                (path) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.folder, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          path.toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _mergeDuplicates(duplicate),
                                    icon: const Icon(Icons.merge),
                                    label: const Text('Merge'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteDuplicates(duplicate),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete Extras'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLargeFilesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_zip, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Large Files',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _largeFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_satisfied,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No large files found',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your storage is efficiently used!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _largeFiles.length,
                    itemBuilder: (context, index) {
                      final file = _largeFiles[index];
                      final priorityColor = _getPriorityColor(file['priority']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: priorityColor.withOpacity(0.2),
                            child: Icon(
                              _getFileTypeIcon(file['type']),
                              color: priorityColor,
                            ),
                          ),
                          title: Text(file['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Size: ${_formatFileSize(file['size']?.toDouble() ?? 0)}'),
                              Text(
                                'Last accessed: ${_formatDate(file['last_accessed'])}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                file['recommendation'] ?? '',
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'compress',
                                child: Row(
                                  children: [
                                    Icon(Icons.compress),
                                    SizedBox(width: 8),
                                    Text('Compress'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'move',
                                child: Row(
                                  children: [
                                    Icon(Icons.drive_file_move),
                                    SizedBox(width: 8),
                                    Text('Move'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) => _handleLargeFileAction(file, value.toString()),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _recommendations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recommendations',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your files are well organized!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = _recommendations[index];
                      final impactColor = _getImpactColor(recommendation['impact']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: impactColor.withOpacity(0.2),
                            child: Icon(
                              _getRecommendationIcon(recommendation['type']),
                              color: impactColor,
                            ),
                          ),
                          title: Text(recommendation['title'] ?? 'Recommendation'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recommendation['description'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                'Potential savings: ${recommendation['potential_savings']}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _applyRecommendation(recommendation),
                            child: const Text('Apply'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getImpactColor(String? impact) {
    switch (impact) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String? type) {
    switch (type) {
      case 'Video':
        return Icons.videocam;
      case 'Archive':
        return Icons.archive;
      case 'Data':
        return Icons.table_chart;
      case 'Image':
        return Icons.image;
      case 'Document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getRecommendationIcon(String? type) {
    switch (type) {
      case 'storage_optimization':
        return Icons.storage;
      case 'organization':
        return Icons.folder_open;
      case 'cleanup':
        return Icons.cleaning_services;
      default:
        return Icons.lightbulb;
    }
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.round()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) return 'Today';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).round()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).round()} months ago';
    return '${(difference.inDays / 365).round()} years ago';
  }

  void _showDuplicateFiles() {
    _tabController.animateTo(1);
  }

  void _showLargeFiles() {
    _tabController.animateTo(2);
  }

  void _generateRecommendations() {
    _tabController.animateTo(3);
  }

  void _cleanupAllDuplicates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean All Duplicates'),
        content: const Text(
          'This will remove all duplicate files, keeping only one copy of each. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCleanupAllDuplicates();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clean All'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanupAllDuplicates() async {
    // Implementation would integrate with the API service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate cleanup started...')),
    );
  }

  void _mergeDuplicates(Map<String, dynamic> duplicate) {
    // Implementation for merging duplicates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Merging ${duplicate['name']}...')),
    );
  }

  void _deleteDuplicates(Map<String, dynamic> duplicate) {
    // Implementation for deleting duplicates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleting duplicates of ${duplicate['name']}...')),
    );
  }

  void _handleLargeFileAction(Map<String, dynamic> file, String action) {
    switch (action) {
      case 'compress':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compressing ${file['name']}...')),
        );
        break;
      case 'move':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moving ${file['name']}...')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleting ${file['name']}...')),
        );
        break;
    }
  }

  void _applyRecommendation(Map<String, dynamic> recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applying: ${recommendation['title']}')),
    );
    
    if (widget.onActionRequired != null) {
      widget.onActionRequired!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Insights Dashboard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        'Comprehensive file analysis and optimization recommendations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.content_copy), text: 'Duplicates'),
              Tab(icon: Icon(Icons.folder_zip), text: 'Large Files'),
              Tab(icon: Icon(Icons.lightbulb), text: 'Tips'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDuplicatesTab(),
                _buildLargeFilesTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

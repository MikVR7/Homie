import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class DriveAnalyticsWidget extends StatefulWidget {
  const DriveAnalyticsWidget({super.key});

  @override
  State<DriveAnalyticsWidget> createState() => _DriveAnalyticsWidgetState();
}

class _DriveAnalyticsWidgetState extends State<DriveAnalyticsWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _driveStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _startDriveMonitoring();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
      
      // Load folder analytics
      final analytics = await provider.getFolderAnalytics();
      final driveStatus = await provider.getDriveStatus();
      
      setState(() {
        _analyticsData = analytics;
        _driveStatus = driveStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startDriveMonitoring() async {
    try {
      final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
      await provider.startDriveMonitoring();
    } catch (e) {
      print('Error starting drive monitoring: $e');
    }
  }

  void _startPolling() {
    // Poll for drive status updates every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final provider = Provider.of<FileOrganizerProvider>(context, listen: false);
        final driveStatus = await provider.getDriveStatus();
        
        if (mounted && driveStatus != _driveStatus) {
          setState(() {
            _driveStatus = driveStatus;
          });
        }
      } catch (e) {
        // Silently handle polling errors to avoid spam
        // print('Polling error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Drive & Folder Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _loadAnalytics,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Drive Status Section
              _buildDriveStatusSection(),
              const SizedBox(height: 20),
              
              // Folder Usage Section
              _buildFolderUsageSection(),
              const SizedBox(height: 20),
              
              // Recent Activity Section
              _buildRecentActivitySection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriveStatusSection() {
    final driveStatus = _driveStatus;
    if (driveStatus == null) {
      return const Text('No drive status available');
    }

    final connectedDrives = driveStatus['connected_drives'] as List? ?? [];
    final driveHistory = driveStatus['drive_history'] as Map? ?? {};
    final recentEvents = driveStatus['recent_events'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🖥️ Connected Drives',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (connectedDrives.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'No external drives connected',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...connectedDrives.map((drive) => _buildDriveCard(drive)).toList(),
        
        if (recentEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '📝 Recent Drive Events',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...recentEvents.take(3).map((event) => _buildEventCard(event)).toList(),
        ],
      ],
    );
  }

  Widget _buildDriveCard(Map<String, dynamic> drive) {
    final path = drive['path'] as String? ?? 'Unknown';
    final type = drive['type'] as String? ?? 'unknown';
    final info = drive['info'] as Map? ?? {};
    final name = info['name'] as String? ?? 'Unknown Drive';

    IconData driveIcon;
    Color driveColor;
    
    switch (type) {
      case 'usb_drives':
        driveIcon = Icons.usb;
        driveColor = AppColors.success;
        break;
      case 'network_drives':
        driveIcon = Icons.lan;
        driveColor = AppColors.primary;
        break;
      case 'cloud_drives':
        driveIcon = Icons.cloud;
        driveColor = AppColors.accent;
        break;
      default:
        driveIcon = Icons.storage;
        driveColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: driveColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: driveColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(driveIcon, color: driveColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  path,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Connected',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventType = event['event_type'] as String? ?? 'unknown';
    final drivePath = event['drive_path'] as String? ?? 'Unknown';
    final timestamp = event['timestamp'] as String? ?? '';

    final isConnected = eventType == 'connected';
    final eventColor = isConnected ? AppColors.success : AppColors.warning;
    final eventIcon = isConnected ? Icons.power : Icons.eject;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: eventColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(eventIcon, color: eventColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${isConnected ? 'Connected' : 'Disconnected'}: ${drivePath.split('/').last}',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderUsageSection() {
    final analytics = _analyticsData;
    if (analytics == null) {
      return const Text('No analytics data available');
    }

    final categoryStats = analytics['category_stats'] as Map? ?? {};
    final confidenceScores = analytics['confidence_scores'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📁 Folder Usage Patterns',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (categoryStats.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'No folder patterns learned yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...categoryStats.entries.map((entry) => 
            _buildCategoryCard(entry.key, entry.value, confidenceScores[entry.key])
          ).toList(),
      ],
    );
  }

  Widget _buildCategoryCard(String category, Map categoryData, Map? confidence) {
    final totalUsage = categoryData['total_usage'] as int? ?? 0;
    final uniqueDestinations = categoryData['unique_destinations'] as int? ?? 0;
    final mostUsedDest = categoryData['most_used_destination'] as String? ?? 'N/A';
    final destinations = categoryData['destinations'] as Map? ?? {};

    // Get confidence for most used destination
    final mostUsedConfidence = confidence?[mostUsedDest] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalUsage uses',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Primary destination
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mostUsedDest.split('/').last,
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${mostUsedConfidence.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          if (uniqueDestinations > 1) ...[
            const SizedBox(height: 6),
            Text(
              '+${uniqueDestinations - 1} other destination${uniqueDestinations > 2 ? 's' : ''}',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final analytics = _analyticsData;
    if (analytics == null) return const SizedBox();

    final recentActivity = analytics['recent_activity'] as List? ?? [];

    if (recentActivity.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🕒 Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        ...recentActivity.take(5).map((activity) => _buildActivityCard(activity)).toList(),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final destination = activity['destination'] as String? ?? 'Unknown';
    final category = activity['file_category'] as String? ?? 'unknown';
    final timestamp = activity['timestamp'] as String? ?? '';
    final usageCount = activity['usage_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(category),
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.split('/').last,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${usageCount}x',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'videos':
      case 'movies':
        return Icons.video_file;
      case 'images':
      case 'photos':
        return Icons.image;
      case 'documents':
      case 'docs':
        return Icons.description;
      case 'music':
      case 'audio':
        return Icons.audio_file;
      case 'archives':
        return Icons.archive;
      case 'software':
        return Icons.apps;
      default:
        return Icons.folder;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
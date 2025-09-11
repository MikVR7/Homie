import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';

class EnhancedDriveMonitor extends StatefulWidget {
  final Function(DriveInfo)? onDriveSelected;
  final bool showAutoRefresh;
  final Duration refreshInterval;
  final bool showDetails;

  const EnhancedDriveMonitor({
    Key? key,
    this.onDriveSelected,
    this.showAutoRefresh = true,
    this.refreshInterval = const Duration(seconds: 5),
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<EnhancedDriveMonitor> createState() => _EnhancedDriveMonitorState();
}

class _EnhancedDriveMonitorState extends State<EnhancedDriveMonitor>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _driveListController;
  late Animation<double> _refreshAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _driveListController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _driveListController,
      curve: Curves.easeOutCubic,
    ));

    _driveListController.forward();
    
    // Initialize drive refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDrives();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _driveListController.dispose();
    super.dispose();
  }

  Future<void> _refreshDrives() async {
    _refreshController.repeat();
    try {
      await context.read<FileOrganizerProvider>().refreshDrives();
    } finally {
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FileOrganizerProvider, WebSocketProvider>(
      builder: (context, fileProvider, wsProvider, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(fileProvider),
                const SizedBox(height: 16),
                _buildConnectionStatus(wsProvider),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildDriveList(fileProvider),
                ),
                if (widget.showDetails) ...[
                  const SizedBox(height: 16),
                  _buildDriveStatistics(fileProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(FileOrganizerProvider provider) {
    return Row(
      children: [
        Icon(
          Icons.storage,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Drive Monitor',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (provider.drives.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.drives.length} drive${provider.drives.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _refreshAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshAnimation.value * 2 * 3.14159,
              child: IconButton(
                onPressed: provider.isAnalyzing ? null : _refreshDrives,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh drives',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(WebSocketProvider wsProvider) {
    final isConnected = wsProvider.isConnected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Real-time monitoring active' : 'Monitoring disconnected',
            style: TextStyle(
              color: isConnected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveList(FileOrganizerProvider provider) {
    if (provider.isAnalyzing) {
      return _buildLoadingState();
    }

    if (provider.drives.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: provider.drives.map((drive) => _buildDriveCard(drive)).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Scanning for drives...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No drives detected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect a USB drive or external storage',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveCard(DriveInfo drive) {
    final isSelected = context.read<FileOrganizerProvider>().selectedDrive == drive;
    final usagePercentage = drive.totalSpace > 0 
        ? (drive.totalSpace - drive.freeSpace) / drive.totalSpace 
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            context.read<FileOrganizerProvider>().selectDrive(drive);
            widget.onDriveSelected?.call(drive);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDriveIcon(drive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  drive.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                ),
                              ),
                              _buildDriveStatus(drive),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drive.path,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (drive.isConnected)
                      IconButton(
                        onPressed: () => _showDriveOptions(drive),
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Drive options',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSpaceUsage(drive, usagePercentage, isSelected),
                if (widget.showDetails && drive.purpose != null) ...[
                  const SizedBox(height: 8),
                  _buildDrivePurpose(drive, isSelected),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriveIcon(DriveInfo drive) {
    IconData icon;
    Color color;

    switch (drive.type.toLowerCase()) {
      case 'usb':
        icon = Icons.usb;
        color = Colors.blue;
        break;
      case 'ssd':
        icon = Icons.storage;
        color = Colors.purple;
        break;
      case 'hdd':
        icon = Icons.storage;
        color = Colors.orange;
        break;
      case 'network':
        icon = Icons.cloud;
        color = Colors.green;
        break;
      default:
        icon = Icons.storage;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildDriveStatus(DriveInfo drive) {
    if (!drive.isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Disconnected',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Connected',
        style: TextStyle(
          color: Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSpaceUsage(DriveInfo drive, double usagePercentage, bool isSelected) {
    final usedSpace = drive.totalSpace - drive.freeSpace;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Used: ${_formatBytes(usedSpace)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : null,
              ),
            ),
            Text(
              'Free: ${_formatBytes(drive.freeSpace)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: usagePercentage,
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            usagePercentage > 0.9 
                ? Colors.red
                : usagePercentage > 0.7 
                    ? Colors.orange
                    : isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(usagePercentage * 100).toStringAsFixed(1)}% used',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildDrivePurpose(DriveInfo drive, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label,
            size: 12,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            drive.purpose!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveStatistics(FileOrganizerProvider provider) {
    if (provider.drives.isEmpty) return const SizedBox.shrink();

    final connectedDrives = provider.drives.where((d) => d.isConnected).length;
    final totalSpace = provider.drives.fold<int>(0, (sum, drive) => sum + drive.totalSpace);
    final totalFree = provider.drives.fold<int>(0, (sum, drive) => sum + drive.freeSpace);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Connected', '$connectedDrives', Icons.link),
          _buildStatItem('Total Space', _formatBytes(totalSpace), Icons.storage),
          _buildStatItem('Free Space', _formatBytes(totalFree), Icons.storage_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  void _showDriveOptions(DriveInfo drive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Drive Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Set Purpose'),
              onTap: () {
                Navigator.pop(context);
                _showSetPurposeDialog(drive);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Open in File Manager'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open file manager
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Drive Properties'),
              onTap: () {
                Navigator.pop(context);
                _showDriveProperties(drive);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPurposeDialog(DriveInfo drive) {
    final controller = TextEditingController(text: drive.purpose ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Drive Purpose'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Movies, Photos, Backup',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FileOrganizerProvider>()
                  .setDrivePurpose(drive, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDriveProperties(DriveInfo drive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Drive Properties'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyRow('Name', drive.name),
              _buildPropertyRow('Path', drive.path),
              _buildPropertyRow('Type', drive.type),
              _buildPropertyRow('Total Space', _formatBytes(drive.totalSpace)),
              _buildPropertyRow('Free Space', _formatBytes(drive.freeSpace)),
              _buildPropertyRow('Status', drive.isConnected ? 'Connected' : 'Disconnected'),
              if (drive.purpose != null)
                _buildPropertyRow('Purpose', drive.purpose!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }
}

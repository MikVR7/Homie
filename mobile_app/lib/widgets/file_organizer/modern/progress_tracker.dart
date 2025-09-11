import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/providers/accessibility_provider.dart';
import 'package:homie_app/widgets/accessibility/accessible_button.dart';
import 'package:homie_app/widgets/accessibility/screen_reader_announcer.dart';

class ProgressTracker extends StatefulWidget {
  final Stream<ProgressEvent>? progressStream;
  final Function()? onPause;
  final Function()? onResume;
  final Function()? onCancel;
  final bool showDetailedLogs;
  final bool allowControls;

  const ProgressTracker({
    Key? key,
    this.progressStream,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.showDetailedLogs = true,
    this.allowControls = true,
  }) : super(key: key);

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  List<OperationLog> _operationLogs = [];
  bool _showLogs = false;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateProgress(double progress) {
    _progressController.animateTo(progress);
  }

  void _addOperationLog(OperationLog log) {
    setState(() {
      _operationLogs.insert(0, log);
      if (_operationLogs.length > 100) {
        _operationLogs = _operationLogs.take(100).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FileOrganizerProvider, WebSocketProvider, AccessibilityProvider>(
      builder: (context, fileProvider, wsProvider, accessibilityProvider, child) {
        final currentProgress = fileProvider.currentProgress;
        final status = fileProvider.status;
        
        return ScreenReaderAnnouncer(
          announcement: _getProgressAnnouncement(currentProgress, status, accessibilityProvider),
          child: Semantics(
            label: 'Progress Tracker',
            hint: 'Real-time file organization progress and controls',
            liveRegion: true,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(status),
                    const SizedBox(height: 20),
                    if (currentProgress != null) ...[
                      _buildProgressSection(currentProgress, status),
                      const SizedBox(height: 20),
                      _buildOperationDetails(currentProgress, status),
                      if (widget.allowControls) ...[
                        const SizedBox(height: 20),
                        _buildControlButtons(status),
                      ],
                      if (widget.showDetailedLogs) ...[
                        const SizedBox(height: 20),
                        _buildLogsSection(),
                      ],
                    ] else
                      _buildIdleState(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(OperationStatus status) {
    IconData icon;
    Color iconColor;
    String title;
    
    switch (status) {
      case OperationStatus.idle:
        icon = Icons.schedule;
        iconColor = Theme.of(context).colorScheme.outline;
        title = 'Ready to Begin';
        break;
      case OperationStatus.analyzing:
        icon = Icons.analytics;
        iconColor = Colors.blue;
        title = 'Analyzing Files';
        break;
      case OperationStatus.executing:
        icon = Icons.play_arrow;
        iconColor = Colors.green;
        title = 'Processing Files';
        break;
      case OperationStatus.paused:
        icon = Icons.pause;
        iconColor = Colors.orange;
        title = 'Operation Paused';
        break;
      case OperationStatus.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        title = 'Completed Successfully';
        break;
      case OperationStatus.error:
        icon = Icons.error;
        iconColor = Colors.red;
        title = 'Error Occurred';
        break;
      case OperationStatus.cancelled:
        icon = Icons.cancel;
        iconColor = Colors.grey;
        title = 'Operation Cancelled';
        break;
    }
    
    return Row(
      children: [
        AnimatedBuilder(
          animation: status == OperationStatus.executing ? _pulseAnimation : 
                     const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: status == OperationStatus.executing ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getStatusDescription(status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(status),
      ],
    );
  }

  Widget _buildStatusIndicator(OperationStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case OperationStatus.idle:
        color = Theme.of(context).colorScheme.outline;
        text = 'IDLE';
        break;
      case OperationStatus.analyzing:
        color = Colors.blue;
        text = 'ANALYZING';
        break;
      case OperationStatus.executing:
        color = Colors.green;
        text = 'RUNNING';
        break;
      case OperationStatus.paused:
        color = Colors.orange;
        text = 'PAUSED';
        break;
      case OperationStatus.completed:
        color = Colors.green;
        text = 'DONE';
        break;
      case OperationStatus.error:
        color = Colors.red;
        text = 'ERROR';
        break;
      case OperationStatus.cancelled:
        color = Colors.grey;
        text = 'CANCELLED';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgressSection(ProgressUpdate progress, OperationStatus status) {
    final progressDescription = _getProgressDescription(progress);
    
    return Semantics(
      label: 'Progress section',
      hint: progressDescription,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Semantics(
                label: 'Operation count',
                value: '${progress.completedOperations} of ${progress.totalOperations} operations',
                child: Text(
                  '${progress.completedOperations}/${progress.totalOperations}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Progress bar',
            value: '${progress.percentage.toStringAsFixed(1)} percent complete',
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value * (progress.percentage / 100),
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    status == OperationStatus.error
                        ? Colors.red
                        : status == OperationStatus.paused
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Completion percentage',
                child: Text(
                  '${progress.percentage.toStringAsFixed(1)}% Complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (progress.estimated != null)
              Semantics(
                label: 'Estimated time remaining',
                child: Text(
                  'ETA: ${_formatDuration(progress.estimated!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildOperationDetails(ProgressUpdate progress, OperationStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Current File', progress.currentFile),
          const SizedBox(height: 8),
          _buildDetailRow('Elapsed Time', _formatDuration(progress.elapsed)),
          const SizedBox(height: 8),
          _buildDetailRow('Processing Speed', '${progress.filesPerSecond} files/sec'),
          if (progress.recentErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Recent Errors', '${progress.recentErrors.length} errors'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(OperationStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == OperationStatus.executing) ...[
          OutlinedButton.icon(
            onPressed: widget.onPause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.stop),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ] else if (status == OperationStatus.paused) ...[
          ElevatedButton.icon(
            onPressed: widget.onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.stop),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Operation Logs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showLogs = !_showLogs;
                });
              },
              icon: Icon(_showLogs ? Icons.expand_less : Icons.expand_more),
              label: Text(_showLogs ? 'Hide Logs' : 'Show Logs'),
            ),
          ],
        ),
        if (_showLogs) ...[
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: _operationLogs.isEmpty
                ? const Center(
                    child: Text('No logs available'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _operationLogs.length,
                    itemBuilder: (context, index) {
                      final log = _operationLogs[index];
                      return _buildLogEntry(log);
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogEntry(OperationLog log) {
    IconData icon;
    Color color;
    
    switch (log.level) {
      case LogLevel.info:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      case LogLevel.warning:
        icon = Icons.warning_outlined;
        color = Colors.orange;
        break;
      case LogLevel.error:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case LogLevel.success:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No operations in progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start file analysis to see progress here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(OperationStatus status) {
    switch (status) {
      case OperationStatus.idle:
        return 'Waiting for operations to begin';
      case OperationStatus.analyzing:
        return 'AI is analyzing your files';
      case OperationStatus.executing:
        return 'Moving and organizing files';
      case OperationStatus.paused:
        return 'Operation temporarily paused';
      case OperationStatus.completed:
        return 'All operations completed successfully';
      case OperationStatus.error:
        return 'An error occurred during processing';
      case OperationStatus.cancelled:
        return 'Operation was cancelled by user';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getProgressAnnouncement(ProgressUpdate? progress, OperationStatus status, AccessibilityProvider accessibilityProvider) {
    if (!accessibilityProvider.announceStateChanges) return '';
    
    switch (status) {
      case OperationStatus.idle:
        return 'Operations idle';
      case OperationStatus.analyzing:
        return 'Analyzing files';
      case OperationStatus.executing:
        if (progress != null) {
          final percentage = (progress.percentage * 100).round();
          String announcement = 'Operation $percentage percent complete';
          if (accessibilityProvider.verboseDescriptions) {
            announcement += '. ${progress.currentFile}';
            if (progress.currentFile.isNotEmpty) {
              announcement += '. Processing ${progress.currentFile}';
            }
          }
          return announcement;
        }
        return 'Operations running';
      case OperationStatus.paused:
        return 'Operations paused';
      case OperationStatus.completed:
        return 'All operations completed successfully';
      case OperationStatus.error:
        return 'Operations failed with error';
      case OperationStatus.cancelled:
        return 'Operations cancelled';
    }
  }

  String _getProgressDescription(ProgressUpdate progress) {
    final percentage = (progress.percentage * 100).round();
    String description = 'Progress $percentage percent';
    
    if (progress.currentFile.isNotEmpty) {
      final fileName = progress.currentFile.split('/').last;
      description += ', processing $fileName';
    }
    
    if (progress.currentFile.isNotEmpty) {
      description += ', current file: ${progress.currentFile}';
    }
    
    if (progress.completedOperations > 0) {
      description += ', ${progress.completedOperations} of ${progress.totalOperations} operations completed';
    }
    
    return description;
  }
}

class OperationLog {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  OperationLog({
    required this.message,
    required this.level,
    required this.timestamp,
    this.context,
  });
}

enum LogLevel { info, warning, error, success }

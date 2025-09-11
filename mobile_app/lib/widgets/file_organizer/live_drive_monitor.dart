import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homie_app/services/websocket_service.dart';
import 'package:homie_app/services/api_service.dart';
import 'package:homie_app/theme/app_theme.dart';

class LiveDriveMonitor extends StatefulWidget {
  final Function(String)? onDriveSelected;
  final bool showAutoRefresh;
  
  const LiveDriveMonitor({
    super.key,
    this.onDriveSelected,
    this.showAutoRefresh = true,
  });

  @override
  State<LiveDriveMonitor> createState() => _LiveDriveMonitorState();
}

class _LiveDriveMonitorState extends State<LiveDriveMonitor> {
  final WebSocketService _wsService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _drives = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Map<String, dynamic>>? _driveEventsSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }

  @override
  void dispose() {
    _driveEventsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMonitoring() async {
    // Setup WebSocket listeners
    _driveEventsSubscription = _wsService.driveEvents.listen(
      (event) {
        if (mounted) {
          _handleDriveEvent(event);
        }
      },
    );

    // Connect WebSocket if needed
    if (!_wsService.isConnected) {
      await _connectWebSocket();
    }

    // Start automatic refresh timer if enabled
    if (widget.showAutoRefresh) {
      _startRefreshTimer();
    }

    // Initial load
    await _refreshDrives();
  }

  Future<void> _connectWebSocket() async {
    try {
      final connected = await _wsService.connect(
        userId: 'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (connected && _wsService.isConnected) {
        // Switch to file organizer module
        await _wsService.switchModule('file_organizer');
        
        // Request initial drive status
        _wsService.requestDriveStatus();
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection failed: $e');
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _refreshDrives();
      }
    });
  }

  void _handleDriveEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String?;
    
    if (kDebugMode) {
      print('🔥 Drive event received: $eventType');
    }

    switch (eventType) {
      case 'file_organizer_drive_status':
      case 'drive_discovered':
      case 'drive_status':
        final data = event['data'] as Map<String, dynamic>?;
        if (data != null) {
          _updateDrivesFromEvent(data);
        }
        break;
      case 'drive_connected':
      case 'drive_disconnected':
        // Refresh drives list after connection changes
        _refreshDrives();
        break;
    }
  }

  void _updateDrivesFromEvent(Map<String, dynamic> data) {
    try {
      if (data['drives'] != null) {
        setState(() {
          _drives = List<Map<String, dynamic>>.from(data['drives']);
          _errorMessage = null;
        });
      } else if (data['error'] != null) {
        setState(() {
          _errorMessage = data['error'].toString();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating drives from event: $e');
      }
      setState(() {
        _errorMessage = 'Error processing drive event: $e';
      });
    }
  }

  Future<void> _refreshDrives() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDrives();
      
      if (mounted) {
        if (data['success'] == true && data['drives'] != null) {
          setState(() {
            _drives = List<Map<String, dynamic>>.from(data['drives']);
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['error']?.toString() ?? 'Failed to load drives';
            _drives = [];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing drives: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Cannot connect to backend: ${e.toString()}';
          _drives = [];
        });
      }
    }
  }

  void _selectDrive(Map<String, dynamic> drive) {
    final path = drive['path'] as String?;
    if (path != null && widget.onDriveSelected != null) {
      widget.onDriveSelected!(path);
      
      // Visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected drive: ${drive['label'] ?? path}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent taking excessive space
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.storage,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Drives',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.showAutoRefresh)
                      Text(
                        'Auto-refreshing every 3s',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _wsService.isConnected
                      ? AppColors.success
                      : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              IconButton(
                onPressed: _isLoading ? null : _refreshDrives,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(Icons.refresh, color: AppColors.primary, size: 20),
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Connection status
          if (!_wsService.isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time monitoring offline',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_wsService.isConnected) const SizedBox(height: 12),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_errorMessage != null) const SizedBox(height: 12),

          // Drives list - with fixed height
          if (_drives.isEmpty && !_isLoading)
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
                  Expanded(
                    child: Text(
                      'No drives detected. Try plugging in a USB drive.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit maximum height
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDrivesList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDrivesList() {
    // Group drives by type
    final local = _drives.where((d) => d['type'] == 'local').toList();
    final usb = _drives.where((d) => d['type'] == 'usb').toList();
    final network = _drives.where((d) => d['type'] == 'network').toList();

    List<Widget> widgets = [];

    if (local.isNotEmpty) {
      widgets.add(_buildDriveSection('💻 Local Drives', local));
    }

    if (usb.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_buildDriveSection('🔌 USB Drives', usb));
    }

    if (network.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_buildDriveSection('🌐 Network Drives', network));
    }

    return widgets;
  }

  Widget _buildDriveSection(String title, List<Map<String, dynamic>> drives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ...drives.map((drive) => _buildDriveCard(drive)).toList(),
      ],
    );
  }

  Widget _buildDriveCard(Map<String, dynamic> drive) {
    try {
      final path = drive['path'] as String? ?? 'Unknown';
      final type = drive['type'] as String? ?? 'unknown';
      final label = drive['label'] as String? ?? drive['name'] as String? ?? 'Unnamed Drive';
      final size = drive['size'] as int?;

    IconData driveIcon;
    Color driveColor;

    switch (type) {
      case 'usb':
        driveIcon = Icons.usb;
        driveColor = AppColors.success;
        break;
      case 'network':
        driveIcon = Icons.lan;
        driveColor = AppColors.primary;
        break;
      case 'local':
        driveIcon = Icons.storage;
        driveColor = AppColors.accent;
        break;
      default:
        driveIcon = Icons.folder;
        driveColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectDrive(drive),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: driveColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: driveColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(driveIcon, color: driveColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        path,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (size != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatBytes(size),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.touch_app,
                  color: AppColors.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    } catch (e) {
      if (kDebugMode) {
        print('Error building drive card: $e');
      }
      // Return a simple error card
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Error displaying drive: $e',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${sizes[i]}';
  }
}

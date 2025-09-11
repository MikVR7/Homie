import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homie_app/services/api_service.dart';
import 'package:homie_app/services/websocket_service.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/widgets/file_organizer/live_drive_monitor.dart';
import 'package:homie_app/config/app_arguments.dart';

class EnhancedFileOrganizerScreen extends StatefulWidget {
  final bool isStandaloneLaunch;
  final String? initialSourcePath;
  final String? initialDestinationPath;

  const EnhancedFileOrganizerScreen({
    super.key,
    this.isStandaloneLaunch = false,
    this.initialSourcePath,
    this.initialDestinationPath,
  });

  @override
  State<EnhancedFileOrganizerScreen> createState() => _EnhancedFileOrganizerScreenState();
}

class _EnhancedFileOrganizerScreenState extends State<EnhancedFileOrganizerScreen> {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _customIntentController = TextEditingController();

  String _organizationStyle = 'smart_categories';
  bool _isAnalyzing = false;
  bool _isExecuting = false;
  
  List<Map<String, dynamic>> _operations = [];
  List<Map<String, dynamic>> _executionResults = [];
  Map<String, dynamic>? _analysisData;
  
  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _customIntentController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    // Use professional AppArguments configuration
    final config = AppArguments.instance.fileOrganizerConfig;
    
    // Set initial paths using configuration
    _sourceController.text = config.getSourcePath();
    _destinationController.text = config.getDestinationPath();
    
    // Debug output for parameter passing
    if (config.hasCustomPaths && kDebugMode) {
      print('📁 File Organizer initialized with custom paths:');
      if (config.sourcePath != null) {
        print('   Source: ${config.sourcePath}');
      }
      if (config.destinationPath != null) {
        print('   Destination: ${config.destinationPath}');
      }
    }
  }

  void _onDriveSelected(String drivePath) {
    setState(() {
      _sourceController.text = drivePath;
    });
  }

  Future<void> _analyzeFiles() async {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      _showError('Please enter both source and destination folders');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _operations.clear();
      _executionResults.clear();
      _analysisData = null;
    });

    try {
      final result = await _apiService.analyzeFolder(
        sourcePath: _sourceController.text,
        destinationPath: _destinationController.text,
        organizationStyle: _organizationStyle,
        intent: _organizationStyle == 'custom' 
            ? _customIntentController.text.isNotEmpty 
                ? _customIntentController.text 
                : null
            : null,
      );

      if (result['success'] == true && result['operations'] != null) {
        setState(() {
          _operations = List<Map<String, dynamic>>.from(result['operations']);
          _analysisData = result;
        });

        _showSuccess('Analysis complete! Found ${_operations.length} operations to perform.');
      } else {
        throw Exception(result['error'] ?? 'Analysis failed with unknown error');
      }
    } catch (e) {
      _showError(_getFormattedError(e.toString()));
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _executeOperations() async {
    if (_operations.isEmpty) {
      _showError('No operations to execute. Please analyze files first.');
      return;
    }

    setState(() {
      _isExecuting = true;
      _executionResults.clear();
    });

    try {
      final result = await _apiService.executeOperations(
        operations: _operations,
        dryRun: false,
      );

      if (result['success'] == true) {
        setState(() {
          _executionResults = List<Map<String, dynamic>>.from(result['results'] ?? []);
        });

        final successful = _executionResults.where((r) => r['success'] == true).length;
        final failed = _executionResults.length - successful;

        _showSuccess(
          'Execution complete! '
          '${successful} operations successful'
          '${failed > 0 ? ', $failed failed' : ''}.'
        );

        // Clear operations after successful execution
        if (failed == 0) {
          setState(() {
            _operations.clear();
          });
        }
      } else {
        throw Exception(result['error'] ?? 'Execution failed with unknown error');
      }
    } catch (e) {
      _showError('Execution failed: ${_getFormattedError(e.toString())}');
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  String _getFormattedError(String error) {
    if (error.contains('Backend server is not running')) {
      return 'Backend server is not running. Please start the backend server first.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('No files found')) {
      return 'No files found in the selected folder. Please select a folder with files to organize.';
    }
    return error;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.isStandaloneLaunch ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/'),
        ),
        automaticallyImplyLeading: !widget.isStandaloneLaunch,
        title: const Text(
          'AI File Organizer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Configuration Panel
            _buildConfigurationPanel(),

            const SizedBox(height: 24),

            // Live Drive Monitor
            LiveDriveMonitor(
              onDriveSelected: _onDriveSelected,
              showAutoRefresh: true,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),

            // Analysis Results
            if (_operations.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildOperationsPreview(),
            ],

            // Execution Results
            if (_executionResults.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildExecutionResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.tune,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Organization Configuration',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Source Folder
          _buildFolderInput(
            label: 'Source Folder',
            controller: _sourceController,
            hint: 'Folder containing files to organize',
            icon: Icons.folder_open,
          ),

          const SizedBox(height: 16),

          // Destination Folder
          _buildFolderInput(
            label: 'Destination Folder',
            controller: _destinationController,
            hint: 'Where to place organized files',
            icon: Icons.folder_special,
          ),

          const SizedBox(height: 20),

          // Organization Style
          _buildOrganizationStyleSelector(),

          // Custom Intent Field (shown when custom is selected)
          if (_organizationStyle == 'custom') ...[
            const SizedBox(height: 16),
            _buildCustomIntentInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildFolderInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organization Style',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _organizationStyle,
            onChanged: (value) {
              setState(() {
                _organizationStyle = value!;
              });
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.style, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.onSurface),
            items: const [
              DropdownMenuItem(
                value: 'by_type',
                child: Text('By File Type'),
              ),
              DropdownMenuItem(
                value: 'by_date',
                child: Text('By Date'),
              ),
              DropdownMenuItem(
                value: 'smart_categories',
                child: Text('Smart Categories'),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text('Custom Intent'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomIntentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Intent',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customIntentController,
          style: TextStyle(color: AppColors.onSurface),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe exactly how you want to organize the files...\nE.g., "organize movies by year", "group photos by event"',
            hintStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(Icons.edit_note, color: AppColors.textSecondary),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing || _isExecuting ? null : _analyzeFiles,
            icon: _isAnalyzing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                    ),
                  )
                : const Icon(Icons.psychology),
            label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _operations.isNotEmpty && !_isAnalyzing && !_isExecuting
                ? _executeOperations
                : null,
            icon: _isExecuting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isExecuting ? 'Executing...' : 'Execute Operations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _operations.isNotEmpty
                  ? AppColors.success
                  : AppColors.surfaceVariant,
              foregroundColor: _operations.isNotEmpty
                  ? Colors.white
                  : AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Operations Preview (${_operations.length})',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ready to Execute',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Operations List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _operations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildOperationCard(_operations[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> operation, int index) {
    final type = operation['type'] as String? ?? 'unknown';
    final src = operation['src'] as String?;
    final dest = operation['dest'] as String?;
    final path = operation['path'] as String?;

    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (type) {
      case 'move':
        icon = Icons.drive_file_move;
        color = AppColors.primary;
        title = 'Move File';
        subtitle = '${src?.split('/').last ?? 'Unknown'} → ${dest?.split('/').last ?? 'Unknown'}';
        break;
      case 'mkdir':
        icon = Icons.create_new_folder;
        color = AppColors.accent;
        title = 'Create Directory';
        subtitle = path?.split('/').last ?? 'Unknown';
        break;
      case 'delete':
        icon = Icons.delete;
        color = AppColors.error;
        title = 'Delete File';
        subtitle = path?.split('/').last ?? 'Unknown';
        break;
      default:
        icon = Icons.help;
        color = AppColors.textSecondary;
        title = type.toUpperCase();
        subtitle = 'Unknown operation';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. $title',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionResults() {
    final successful = _executionResults.where((r) => r['success'] == true).length;
    final failed = _executionResults.length - successful;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: failed > 0 
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (failed > 0 ? AppColors.warning : AppColors.success).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  failed > 0 ? Icons.warning : Icons.check_circle,
                  color: failed > 0 ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Execution Results',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$successful Success',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (failed > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$failed Failed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _executionResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildResultCard(_executionResults[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, int index) {
    final success = result['success'] == true;
    final operation = result['operation'] as Map<String, dynamic>? ?? {};
    final error = result['error'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (success ? AppColors.success : AppColors.error).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operation ${index + 1}: ${operation['type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error != null)
                  Text(
                    'Error: $error',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    'Completed successfully',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'File Organizer Settings',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: Text(
          'Settings panel coming soon...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}


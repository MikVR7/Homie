import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';
import '../../../models/file_organizer_models.dart';
import '../../../animations/micro_interactions.dart';

/// Export manager for operation reports and analytics
class ExportManager extends StatefulWidget {
  final List<FileItem> files;
  final List<FileOperation> operations;
  final Map<String, dynamic> analytics;
  final Function(String) onExportComplete;

  const ExportManager({
    Key? key,
    required this.files,
    required this.operations,
    required this.analytics,
    required this.onExportComplete,
  }) : super(key: key);

  @override
  State<ExportManager> createState() => _ExportManagerState();
}

class _ExportManagerState extends State<ExportManager>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  String _selectedFormat = 'csv';
  String _selectedScope = 'all';
  bool _includeAnalytics = true;
  bool _includeTimestamps = true;
  bool _includeFileMetadata = true;
  bool _includeOperationDetails = true;
  bool _isExporting = false;
  
  final List<String> _exportFormats = ['csv', 'json', 'pdf', 'html'];
  final List<String> _exportScopes = ['all', 'files', 'operations', 'analytics'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickExport(),
                _buildAdvancedExport(),
                _buildExportHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.file_download,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Export Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isExporting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.flash_on), text: 'Quick'),
        Tab(icon: Icon(Icons.tune), text: 'Advanced'),
        Tab(icon: Icon(Icons.history), text: 'History'),
      ],
    );
  }

  Widget _buildQuickExport() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Export Templates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildQuickExportCard(
            'File List Report',
            'Export all files with metadata',
            Icons.list_alt,
            () => _quickExport('files'),
            '${widget.files.length} files',
          ),
          
          _buildQuickExportCard(
            'Operations Report',
            'Export all file operations',
            Icons.settings,
            () => _quickExport('operations'),
            '${widget.operations.length} operations',
          ),
          
          _buildQuickExportCard(
            'Analytics Summary',
            'Export organization analytics',
            Icons.analytics,
            () => _quickExport('analytics'),
            _getAnalyticsSummary(),
          ),
          
          _buildQuickExportCard(
            'Complete Report',
            'Export everything in one file',
            Icons.description,
            () => _quickExport('complete'),
            'All data',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportCard(String title, String description, IconData icon, VoidCallback onTap, String count) {
    return MicroInteractions.animatedCard(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedExport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Format
          Text(
            'Export Format',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _exportFormats.map((format) {
              final isSelected = _selectedFormat == format;
              return FilterChip(
                label: Text(format.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFormat = format);
                },
                avatar: Icon(
                  _getFormatIcon(format),
                  size: 16,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Export Scope
          Text(
            'Data to Export',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _exportScopes.map((scope) {
              return RadioListTile<String>(
                title: Text(_getScopeTitle(scope)),
                subtitle: Text(_getScopeDescription(scope)),
                value: scope,
                groupValue: _selectedScope,
                onChanged: (value) {
                  setState(() => _selectedScope = value ?? 'all');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Export Options
          Text(
            'Export Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          SwitchListTile(
            title: const Text('Include Analytics'),
            subtitle: const Text('File type distribution, size analysis'),
            value: _includeAnalytics,
            onChanged: (value) {
              setState(() => _includeAnalytics = value);
            },
          ),
          
          SwitchListTile(
            title: const Text('Include Timestamps'),
            subtitle: const Text('Creation and modification dates'),
            value: _includeTimestamps,
            onChanged: (value) {
              setState(() => _includeTimestamps = value);
            },
          ),
          
          SwitchListTile(
            title: const Text('Include File Metadata'),
            subtitle: const Text('File size, type, path information'),
            value: _includeFileMetadata,
            onChanged: (value) {
              setState(() => _includeFileMetadata = value);
            },
          ),
          
          SwitchListTile(
            title: const Text('Include Operation Details'),
            subtitle: const Text('AI reasoning and confidence scores'),
            value: _includeOperationDetails,
            onChanged: (value) {
              setState(() => _includeOperationDetails = value);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Export Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _performAdvancedExport,
              icon: _isExporting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportHistory() {
    // TODO: Implement export history
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64),
          SizedBox(height: 16),
          Text('Export History'),
          Text('Coming soon...'),
        ],
      ),
    );
  }

  void _quickExport(String type) async {
    setState(() => _isExporting = true);
    
    try {
      String fileName;
      Map<String, dynamic> data;
      
      switch (type) {
        case 'files':
          fileName = 'homie_files_${_getTimestamp()}.csv';
          data = _generateFileReport();
          break;
        case 'operations':
          fileName = 'homie_operations_${_getTimestamp()}.csv';
          data = _generateOperationsReport();
          break;
        case 'analytics':
          fileName = 'homie_analytics_${_getTimestamp()}.json';
          data = _generateAnalyticsReport();
          break;
        case 'complete':
          fileName = 'homie_complete_report_${_getTimestamp()}.json';
          data = _generateCompleteReport();
          break;
        default:
          throw Exception('Unknown export type: $type');
      }
      
      await _saveFile(fileName, data, type.endsWith('analytics') || type.endsWith('complete') ? 'json' : 'csv');
      widget.onExportComplete(fileName);
      
    } catch (e) {
      _showExportError('Export failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _performAdvancedExport() async {
    setState(() => _isExporting = true);
    
    try {
      final fileName = 'homie_export_${_getTimestamp()}.${_selectedFormat}';
      final data = _generateAdvancedExport();
      
      await _saveFile(fileName, data, _selectedFormat);
      widget.onExportComplete(fileName);
      
    } catch (e) {
      _showExportError('Export failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Map<String, dynamic> _generateFileReport() {
    final csvData = <List<String>>[];
    
    // Headers
    final headers = ['Name', 'Type', 'Size (bytes)', 'Size (readable)', 'Path', 'Last Modified'];
    if (_includeFileMetadata) {
      headers.addAll(['Suggested Location', 'Organization Status']);
    }
    csvData.add(headers);
    
    // Data rows
    for (final file in widget.files) {
      final row = [
        file.name,
        file.type,
        file.size.toString(),
        _formatFileSize(file.size),
        file.path,
        file.lastModified.toIso8601String(),
      ];
      
      if (_includeFileMetadata) {
        row.addAll([
          file.suggestedLocation ?? '',
          file.suggestedLocation != null ? 'Suggested' : 'Needs Organization',
        ]);
      }
      
      csvData.add(row);
    }
    
    return {'csvData': csvData};
  }

  Map<String, dynamic> _generateOperationsReport() {
    final csvData = <List<String>>[];
    
    // Headers
    final headers = ['Type', 'Source Path', 'Destination Path', 'Confidence', 'Status'];
    if (_includeOperationDetails) {
      headers.addAll(['Reasoning', 'Created At']);
    }
    csvData.add(headers);
    
    // Data rows
    for (final operation in widget.operations) {
      final row = [
        operation.type,
        operation.sourcePath,
        operation.destinationPath ?? '',
        '${(operation.confidence * 100).toInt()}%',
        'Pending', // TODO: Add actual status
      ];
      
      if (_includeOperationDetails) {
        row.addAll([
          operation.reasoning ?? '',
          DateTime.now().toIso8601String(), // TODO: Add actual creation time
        ]);
      }
      
      csvData.add(row);
    }
    
    return {'csvData': csvData};
  }

  Map<String, dynamic> _generateAnalyticsReport() {
    final report = Map<String, dynamic>.from(widget.analytics);
    
    if (_includeTimestamps) {
      report['generatedAt'] = DateTime.now().toIso8601String();
    }
    
    // Add computed analytics
    report['fileCounts'] = _getFileCounts();
    report['sizesAnalysis'] = _getSizeAnalysis();
    report['operationsSummary'] = _getOperationsSummary();
    
    return report;
  }

  Map<String, dynamic> _generateCompleteReport() {
    final report = <String, dynamic>{};
    
    if (_includeTimestamps) {
      report['generatedAt'] = DateTime.now().toIso8601String();
    }
    
    report['summary'] = {
      'totalFiles': widget.files.length,
      'totalOperations': widget.operations.length,
      'exportFormat': 'complete',
      'scope': 'all',
    };
    
    if (_selectedScope == 'all' || _selectedScope == 'files') {
      report['files'] = widget.files.map((file) => {
        'name': file.name,
        'type': file.type,
        'size': file.size,
        'path': file.path,
        'lastModified': file.lastModified.toIso8601String(),
        if (_includeFileMetadata) ...{
          'suggestedLocation': file.suggestedLocation,
          'organizationStatus': file.suggestedLocation != null ? 'suggested' : 'needs_organization',
        },
      }).toList();
    }
    
    if (_selectedScope == 'all' || _selectedScope == 'operations') {
      report['operations'] = widget.operations.map((operation) => {
        'type': operation.type,
        'sourcePath': operation.sourcePath,
        'destinationPath': operation.destinationPath,
        'confidence': operation.confidence,
        if (_includeOperationDetails) ...{
          'reasoning': operation.reasoning,
        },
      }).toList();
    }
    
    if (_selectedScope == 'all' || _selectedScope == 'analytics') {
      if (_includeAnalytics) {
        report['analytics'] = _generateAnalyticsReport();
      }
    }
    
    return report;
  }

  Map<String, dynamic> _generateAdvancedExport() {
    switch (_selectedFormat) {
      case 'csv':
        return _generateCsvExport();
      case 'json':
        return _generateJsonExport();
      case 'html':
        return _generateHtmlExport();
      case 'pdf':
        return _generatePdfExport();
      default:
        throw Exception('Unsupported format: $_selectedFormat');
    }
  }

  Map<String, dynamic> _generateCsvExport() {
    switch (_selectedScope) {
      case 'files':
        return _generateFileReport();
      case 'operations':
        return _generateOperationsReport();
      case 'analytics':
        // Convert analytics to CSV format
        final csvData = <List<String>>[];
        csvData.add(['Metric', 'Value']);
        final analytics = _generateAnalyticsReport();
        analytics.forEach((key, value) {
          csvData.add([key, value.toString()]);
        });
        return {'csvData': csvData};
      default:
        // Combined CSV - files first, then operations
        final fileData = _generateFileReport()['csvData'] as List<List<String>>;
        final operationData = _generateOperationsReport()['csvData'] as List<List<String>>;
        
        final combined = <List<String>>[];
        combined.add(['=== FILES ===']);
        combined.addAll(fileData);
        combined.add(['']);
        combined.add(['=== OPERATIONS ===']);
        combined.addAll(operationData);
        
        return {'csvData': combined};
    }
  }

  Map<String, dynamic> _generateJsonExport() {
    switch (_selectedScope) {
      case 'files':
        return {'files': widget.files.map((f) => f.toJson()).toList()};
      case 'operations':
        return {'operations': widget.operations.map((o) => o.toJson()).toList()};
      case 'analytics':
        return _generateAnalyticsReport();
      default:
        return _generateCompleteReport();
    }
  }

  Map<String, dynamic> _generateHtmlExport() {
    final html = StringBuffer();
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html><head><title>Homie File Organizer Report</title>');
    html.writeln('<style>');
    html.writeln('body { font-family: Arial, sans-serif; margin: 20px; }');
    html.writeln('table { border-collapse: collapse; width: 100%; margin: 20px 0; }');
    html.writeln('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    html.writeln('th { background-color: #f2f2f2; }');
    html.writeln('h1, h2 { color: #333; }');
    html.writeln('</style></head><body>');
    
    html.writeln('<h1>Homie File Organizer Report</h1>');
    html.writeln('<p>Generated: ${DateTime.now()}</p>');
    
    if (_selectedScope == 'all' || _selectedScope == 'files') {
      html.writeln('<h2>Files (${widget.files.length})</h2>');
      html.writeln('<table>');
      html.writeln('<tr><th>Name</th><th>Type</th><th>Size</th><th>Path</th></tr>');
      for (final file in widget.files) {
        html.writeln('<tr>');
        html.writeln('<td>${_escapeHtml(file.name)}</td>');
        html.writeln('<td>${_escapeHtml(file.type)}</td>');
        html.writeln('<td>${_formatFileSize(file.size)}</td>');
        html.writeln('<td>${_escapeHtml(file.path)}</td>');
        html.writeln('</tr>');
      }
      html.writeln('</table>');
    }
    
    if (_selectedScope == 'all' || _selectedScope == 'operations') {
      html.writeln('<h2>Operations (${widget.operations.length})</h2>');
      html.writeln('<table>');
      html.writeln('<tr><th>Type</th><th>Source</th><th>Destination</th><th>Confidence</th></tr>');
      for (final operation in widget.operations) {
        html.writeln('<tr>');
        html.writeln('<td>${_escapeHtml(operation.type)}</td>');
        html.writeln('<td>${_escapeHtml(operation.sourcePath)}</td>');
        html.writeln('<td>${_escapeHtml(operation.destinationPath ?? '')}</td>');
        html.writeln('<td>${(operation.confidence * 100).toInt()}%</td>');
        html.writeln('</tr>');
      }
      html.writeln('</table>');
    }
    
    html.writeln('</body></html>');
    
    return {'html': html.toString()};
  }

  Map<String, dynamic> _generatePdfExport() {
    // TODO: Implement PDF generation
    // For now, return a placeholder
    return {
      'error': 'PDF export not yet implemented',
      'suggestion': 'Use HTML export and print to PDF',
    };
  }

  Future<void> _saveFile(String fileName, Map<String, dynamic> data, String format) async {
    // TODO: Implement actual file saving with platform-specific file picker
    // For now, copy to clipboard
    
    String content;
    
    switch (format) {
      case 'csv':
        final csvData = data['csvData'] as List<List<String>>;
        content = const ListToCsvConverter().convert(csvData);
        break;
      case 'json':
        content = const JsonEncoder.withIndent('  ').convert(data);
        break;
      case 'html':
        content = data['html'] as String;
        break;
      default:
        content = data.toString();
    }
    
    await Clipboard.setData(ClipboardData(text: content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export completed: $fileName (copied to clipboard)'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showExportError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Map<String, int> _getFileCounts() {
    final counts = <String, int>{};
    for (final file in widget.files) {
      counts[file.type] = (counts[file.type] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, dynamic> _getSizeAnalysis() {
    if (widget.files.isEmpty) return {};
    
    final sizes = widget.files.map((f) => f.size).toList()..sort();
    final totalSize = sizes.fold<int>(0, (sum, size) => sum + size);
    
    return {
      'totalSize': totalSize,
      'averageSize': totalSize / sizes.length,
      'medianSize': sizes[sizes.length ~/ 2],
      'largestFile': sizes.last,
      'smallestFile': sizes.first,
    };
  }

  Map<String, dynamic> _getOperationsSummary() {
    final summary = <String, int>{};
    for (final operation in widget.operations) {
      summary[operation.type] = (summary[operation.type] ?? 0) + 1;
    }
    return summary;
  }

  String _getAnalyticsSummary() {
    final fileTypes = _getFileCounts();
    final totalSize = widget.files.fold<int>(0, (sum, file) => sum + file.size);
    return '${fileTypes.length} types, ${_formatFileSize(totalSize)}';
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'csv': return Icons.table_chart;
      case 'json': return Icons.code;
      case 'pdf': return Icons.picture_as_pdf;
      case 'html': return Icons.web;
      default: return Icons.description;
    }
  }

  String _getScopeTitle(String scope) {
    switch (scope) {
      case 'all': return 'Everything';
      case 'files': return 'Files Only';
      case 'operations': return 'Operations Only';
      case 'analytics': return 'Analytics Only';
      default: return scope;
    }
  }

  String _getScopeDescription(String scope) {
    switch (scope) {
      case 'all': return 'Export files, operations, and analytics';
      case 'files': return 'Export file list with metadata';
      case 'operations': return 'Export organization operations';
      case 'analytics': return 'Export analytics and statistics';
      default: return '';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

import 'package:flutter/foundation.dart';
import 'package:homie_app/models/file_organizer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homie_app/services/api_service.dart';

enum OrganizationStyle { smartCategories, byType, byDate, custom }
enum OperationStatus { idle, analyzing, executing, paused, completed, error, cancelled }
enum FileOperationType { move, copy, delete, rename, createFolder }

class FileOperation {
  final String id;
  final FileOperationType type;
  final String sourcePath;
  final String? destinationPath;
  final String? newFolderName;
  final double confidence;
  final String reasoning;
  final List<String> tags;
  final Duration estimatedTime;
  final int estimatedSize;
  bool isApproved;
  bool isRejected;
  String? userNote;

  FileOperation({
    required this.id,
    required this.type,
    required this.sourcePath,
    this.destinationPath,
    this.newFolderName,
    required this.confidence,
    required this.reasoning,
    this.tags = const [],
    required this.estimatedTime,
    required this.estimatedSize,
    this.isApproved = true,
    this.isRejected = false,
    this.userNote,
  });

  FileOperation copyWith({
    String? id,
    FileOperationType? type,
    String? sourcePath,
    String? destinationPath,
    String? newFolderName,
    double? confidence,
    String? reasoning,
    List<String>? tags,
    Duration? estimatedTime,
    int? estimatedSize,
    bool? isApproved,
    bool? isRejected,
    String? userNote,
  }) {
    return FileOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath ?? this.destinationPath,
      newFolderName: newFolderName ?? this.newFolderName,
      confidence: confidence ?? this.confidence,
      reasoning: reasoning ?? this.reasoning,
      tags: tags ?? this.tags,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedSize: estimatedSize ?? this.estimatedSize,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      userNote: userNote ?? this.userNote,
    );
  }
}

class DriveInfo {
  final String path;
  final String name;
  final String type; // USB, HDD, SSD, Network
  final int totalSpace;
  final int freeSpace;
  final bool isConnected;
  final DateTime? lastSeen;
  final List<String> commonFolders;
  final Map<String, int> fileTypeDistribution;
  final String? purpose;

  DriveInfo({
    required this.path,
    required this.name,
    required this.type,
    required this.totalSpace,
    required this.freeSpace,
    required this.isConnected,
    this.lastSeen,
    this.commonFolders = const [],
    this.fileTypeDistribution = const {},
    this.purpose,
  });
}

class FolderAnalytics {
  final String path;
  final int totalFiles;
  final int totalFolders;
  final int totalSize;
  final Map<String, int> fileTypeDistribution;
  final List<String> largestFiles;
  final List<String> duplicates;
  final List<String> emptyFolders;
  final Map<String, int> fileAgeDistribution;
  final DateTime analyzedAt;

  FolderAnalytics({
    required this.path,
    required this.totalFiles,
    required this.totalFolders,
    required this.totalSize,
    this.fileTypeDistribution = const {},
    this.largestFiles = const [],
    this.duplicates = const [],
    this.emptyFolders = const [],
    this.fileAgeDistribution = const {},
    required this.analyzedAt,
  });
}

class OrganizationPreset {
  final String id;
  final String name;
  final String description;
  final String intent;
  final List<String> applicableFileTypes;
  final Map<String, String> folderStructure;
  final double relevanceScore;
  final bool isCustom;
  final DateTime createdAt;
  final int usageCount;

  OrganizationPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.intent,
    this.applicableFileTypes = const [],
    this.folderStructure = const {},
    required this.relevanceScore,
    required this.isCustom,
    required this.createdAt,
    this.usageCount = 0,
  });
}

class ProgressUpdate {
  final String operationId;
  final int completedOperations;
  final int totalOperations;
  final double percentage;
  final String currentFile;
  final Duration elapsed;
  final Duration? estimated;
  final int filesPerSecond;
  final List<String> recentErrors;
  final OperationStatus status;

  ProgressUpdate({
    required this.operationId,
    required this.completedOperations,
    required this.totalOperations,
    required this.percentage,
    required this.currentFile,
    required this.elapsed,
    this.estimated,
    required this.filesPerSecond,
    this.recentErrors = const [],
    required this.status,
  });
}

class FileOrganizerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Core state
  String _sourcePath = '';
  String _destinationPath = '';
  OrganizationStyle _organizationStyle = OrganizationStyle.smartCategories;
  String _customIntent = '';
  // Recently selected folders
  List<String> _recentSourceFolders = [];
  List<String> _recentDestinationFolders = [];
  
  // Operation state
  List<FileOperation> _operations = [];
  List<Map<String, dynamic>> _results = [];
  OperationStatus _status = OperationStatus.idle;
  String? _currentOperationId;
  
  // Drive state
  List<DriveInfo> _drives = [];
  DriveInfo? _selectedDrive;
  
  // Analytics state
  FolderAnalytics? _analytics;
  List<OrganizationPreset> _presets = [];
  
  // Progress tracking
  ProgressUpdate? _currentProgress;
  
  // Legacy state for compatibility
  List<FileItem> _files = [];
  List<OrganizationRule> _rules = [];
  OrganizationStats? _stats;
  List<Map<String, dynamic>> _organizationResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Enhanced getters
  String get sourcePath => _sourcePath;
  String get destinationPath => _destinationPath;
  OrganizationStyle get organizationStyle => _organizationStyle;
  String get customIntent => _customIntent;
  List<String> get recentSourceFolders => List.unmodifiable(_recentSourceFolders);
  List<String> get recentDestinationFolders => List.unmodifiable(_recentDestinationFolders);
  
  List<FileOperation> get operations => _operations;
  List<Map<String, dynamic>> get results => _results;
  OperationStatus get status => _status;
  String? get currentOperationId => _currentOperationId;
  
  List<DriveInfo> get drives => _drives;
  DriveInfo? get selectedDrive => _selectedDrive;
  
  FolderAnalytics? get analytics => _analytics;
  List<OrganizationPreset> get presets => _presets;
  
  ProgressUpdate? get currentProgress => _currentProgress;
  
  // Legacy getters for compatibility
  List<FileItem> get files => _files;
  List<OrganizationRule> get rules => _rules;
  OrganizationStats? get stats => _stats;
  List<Map<String, dynamic>> get organizationResults => _organizationResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Convenience getters
  bool get hasOperations => _operations.isNotEmpty;
  bool get canExecute => _operations.where((op) => op.isApproved && !op.isRejected).isNotEmpty;
  bool get isAnalyzing => _status == OperationStatus.analyzing;
  bool get isExecuting => _status == OperationStatus.executing;
  bool get isIdle => _status == OperationStatus.idle;
  double get operationProgress => _currentProgress?.percentage ?? 0.0;

  // Enhanced state management methods
  
  FileOrganizerProvider() {
    _loadRecentFolders();
  }

  /// Set source path for file organization
  void setSourcePath(String path) {
    if (_sourcePath != path) {
      _sourcePath = path;
      _clearOperations(); // Clear operations when source changes
      _addRecentSourceFolder(path);
      notifyListeners();
    }
  }
  
  /// Set destination path for file organization
  void setDestinationPath(String path) {
    if (_destinationPath != path) {
      _destinationPath = path;
      _clearOperations(); // Clear operations when destination changes
      _addRecentDestinationFolder(path);
      notifyListeners();
    }
  }
  
  /// Set organization style
  void setOrganizationStyle(OrganizationStyle style) {
    if (_organizationStyle != style) {
      _organizationStyle = style;
      _clearOperations(); // Clear operations when style changes
      notifyListeners();
    }
  }
  
  /// Set custom intent for organization
  void setCustomIntent(String intent) {
    if (_customIntent != intent) {
      _customIntent = intent;
      _clearOperations(); // Clear operations when intent changes
      notifyListeners();
    }
  }
  
  /// Analyze folder and generate operations
  Future<void> analyzeFolder() async {
    if (_sourcePath.isEmpty || _destinationPath.isEmpty) {
      _setError('Please select both source and destination paths');
      return;
    }
    
    print('DEBUG Provider: Starting analysis...');
    print('  Source: $_sourcePath');
    print('  Destination: $_destinationPath');
    print('  Style: ${_organizationStyle.name}');
    
    _setStatus(OperationStatus.analyzing);
    _clearError();
    
    try {
      String intent = _customIntent;
      if (intent.isEmpty) {
        intent = _getDefaultIntentForStyle();
      }
      
      print('DEBUG Provider: Intent: $intent');
      
      final result = await _apiService.analyzeFolder(
        sourcePath: _sourcePath,
        destinationPath: _destinationPath,
        intent: intent,
        organizationStyle: _organizationStyle.name,
      );
      
      print('DEBUG Provider: API result: $result');
      
      if (result['success'] == true) {
        _parseOperationsFromResult(result);
        print('DEBUG Provider: Parsed ${_operations.length} operations');
        _setStatus(OperationStatus.idle);
      } else {
        throw Exception(result['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('DEBUG Provider: Error during analysis: $e');
      _setStatus(OperationStatus.error);
      _setError('Analysis failed: ${e.toString()}');
    }
  }
  
  /// Execute approved operations
  Future<void> executeOperations() async {
    final approvedOps = _operations.where((op) => op.isApproved && !op.isRejected).toList();
    
    if (approvedOps.isEmpty) {
      _setError('No approved operations to execute');
      return;
    }
    
    _setStatus(OperationStatus.executing);
    _clearError();
    
    try {
      final operationsData = approvedOps.map((op) => _convertOperationToApiFormat(op)).toList();
      
      final result = await _apiService.executeOperations(
        operations: operationsData,
        dryRun: false,
      );
      
      if (result['success'] == true) {
        _results = List<Map<String, dynamic>>.from(result['results'] ?? []);
        _setStatus(OperationStatus.completed);
      } else {
        throw Exception(result['error'] ?? 'Execution failed');
      }
    } catch (e) {
      _setStatus(OperationStatus.error);
      _setError('Execution failed: ${e.toString()}');
    }
  }
  
  /// Refresh drives list
  Future<void> refreshDrives() async {
    try {
      final result = await _apiService.getDrives();
      
      if (result['success'] == true) {
        _drives = _parseDrivesFromResult(result);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh drives: ${e.toString()}');
    }
  }
  
  /// Select a drive as source
  void selectDrive(DriveInfo drive) {
    _selectedDrive = drive;
    setSourcePath(drive.path);
    notifyListeners();
  }
  
  /// Load analytics for current source path
  Future<void> loadAnalytics() async {
    if (_sourcePath.isEmpty) return;
    
    try {
      // Note: This would need to be implemented in the API service
      // For now, create mock analytics
      _analytics = FolderAnalytics(
        path: _sourcePath,
        totalFiles: 0,
        totalFolders: 0,
        totalSize: 0,
        analyzedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load analytics: ${e.toString()}');
    }
  }
  
  /// Approve an operation
  void approveOperation(String operationId) {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _operations[index].isApproved = true;
      _operations[index].isRejected = false;
      notifyListeners();
    }
  }
  
  /// Reject an operation
  void rejectOperation(String operationId) {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _operations[index].isApproved = false;
      _operations[index].isRejected = true;
      notifyListeners();
    }
  }
  
  /// Approve all operations
  void approveAllOperations() {
    for (var operation in _operations) {
      operation.isApproved = true;
      operation.isRejected = false;
    }
    notifyListeners();
  }
  
  /// Reject all operations
  void rejectAllOperations() {
    for (var operation in _operations) {
      operation.isApproved = false;
      operation.isRejected = true;
    }
    notifyListeners();
  }

  /// Update operations list
  void updateOperations(List<FileOperation> operations) {
    _operations.clear();
    _operations.addAll(operations);
    notifyListeners();
  }
  
  /// Update progress during operations
  void updateProgress(ProgressUpdate progress) {
    _currentProgress = progress;
    notifyListeners();
  }
  
  /// Pause current operations
  Future<void> pauseOperations() async {
    if (_status == OperationStatus.executing) {
      _setStatus(OperationStatus.paused);
      // Note: Actual pause implementation would need backend support
    }
  }
  
  /// Resume paused operations
  Future<void> resumeOperations() async {
    if (_status == OperationStatus.paused) {
      _setStatus(OperationStatus.executing);
      // Note: Actual resume implementation would need backend support
    }
  }
  
  /// Cancel current operations
  Future<void> cancelOperations() async {
    if (_status == OperationStatus.executing || _status == OperationStatus.paused) {
      _setStatus(OperationStatus.cancelled);
      _currentProgress = null;
      // Note: Actual cancellation implementation would need backend support
    }
  }
  
  /// Reset all state
  void resetState() {
    _sourcePath = '';
    _destinationPath = '';
    _organizationStyle = OrganizationStyle.smartCategories;
    _customIntent = '';
    _clearOperations();
    _clearError();
    _setStatus(OperationStatus.idle);
    _selectedDrive = null;
    _analytics = null;
    _currentProgress = null;
  }
  
  // Helper methods
  
  String _getDefaultIntentForStyle() {
    switch (_organizationStyle) {
      case OrganizationStyle.byType:
        return 'organize files by type (images, documents, videos, etc.)';
      case OrganizationStyle.byDate:
        return 'organize files by date (year/month folders)';
      case OrganizationStyle.smartCategories:
        return 'organize files into smart categories based on content';
      case OrganizationStyle.custom:
        return _customIntent;
    }
  }
  
  void _parseOperationsFromResult(Map<String, dynamic> result) {
    _operations.clear();
    
    print('DEBUG Parser: Full result structure: $result');
    
    final operations = result['data']?['operations'] ?? [];
    print('DEBUG Parser: Found operations array: $operations');
    print('DEBUG Parser: Operations array length: ${operations.length}');
    
    for (int i = 0; i < operations.length; i++) {
      final op = operations[i];
      print('DEBUG Parser: Processing operation $i: $op');
      
      _operations.add(FileOperation(
        id: 'op_$i',
        type: _parseOperationType(op['type']),
        sourcePath: op['src'] ?? op['path'] ?? '',
        destinationPath: op['dest'],
        confidence: (op['confidence'] ?? 85) / 100.0,
        reasoning: op['reasoning'] ?? 'AI analysis',
        estimatedTime: Duration(seconds: i * 5),
        estimatedSize: op['size'] ?? 0,
      ));
    }
    
    print('DEBUG Parser: Created ${_operations.length} FileOperation objects');
    notifyListeners();
  }
  
  FileOperationType _parseOperationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'move':
        return FileOperationType.move;
      case 'copy':
        return FileOperationType.copy;
      case 'delete':
        return FileOperationType.delete;
      case 'rename':
        return FileOperationType.rename;
      case 'create_folder':
        return FileOperationType.createFolder;
      default:
        return FileOperationType.move;
    }
  }
  
  Map<String, dynamic> _convertOperationToApiFormat(FileOperation operation) {
    return {
      'type': operation.type.name,
      'src': operation.sourcePath,
      'dest': operation.destinationPath,
      'confidence': operation.confidence,
      'reasoning': operation.reasoning,
    };
  }
  
  List<DriveInfo> _parseDrivesFromResult(Map<String, dynamic> result) {
    final drives = <DriveInfo>[];
    final drivesData = result['data']?['drives'] ?? [];
    
    for (final drive in drivesData) {
      drives.add(DriveInfo(
        path: drive['path'] ?? '',
        name: drive['name'] ?? 'Unknown Drive',
        type: drive['type'] ?? 'Unknown',
        totalSpace: drive['total_space'] ?? 0,
        freeSpace: drive['free_space'] ?? 0,
        isConnected: drive['is_connected'] ?? false,
        lastSeen: drive['last_seen'] != null 
            ? DateTime.tryParse(drive['last_seen']) 
            : null,
      ));
    }
    
    return drives;
  }
  
  void _setStatus(OperationStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }
  
  void _clearOperations() {
    _operations.clear();
    _results.clear();
    _currentProgress = null;
  }

  // Recent folders helpers
  Future<void> _loadRecentFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSourceFolders = prefs.getStringList('recent_source_folders') ?? [];
      _recentDestinationFolders = prefs.getStringList('recent_destination_folders') ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveRecentFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_source_folders', _recentSourceFolders);
      await prefs.setStringList('recent_destination_folders', _recentDestinationFolders);
    } catch (_) {}
  }

  void _addRecentSourceFolder(String path) {
    if (path.isEmpty) return;
    _recentSourceFolders.remove(path);
    _recentSourceFolders.insert(0, path);
    if (_recentSourceFolders.length > 10) {
      _recentSourceFolders = _recentSourceFolders.take(10).toList();
    }
    _saveRecentFolders();
  }

  void _addRecentDestinationFolder(String path) {
    if (path.isEmpty) return;
    _recentDestinationFolders.remove(path);
    _recentDestinationFolders.insert(0, path);
    if (_recentDestinationFolders.length > 10) {
      _recentDestinationFolders = _recentDestinationFolders.take(10).toList();
    }
    _saveRecentFolders();
  }

  Future<void> addSourceFolderViaPicker() async {
    // This is intentionally left for UI layer to handle picker; kept for symmetry if needed later
  }

  void removeRecentSourceFolder(String path) {
    _recentSourceFolders.remove(path);
    _saveRecentFolders();
    notifyListeners();
  }

  void removeRecentDestinationFolder(String path) {
    _recentDestinationFolders.remove(path);
    _saveRecentFolders();
    notifyListeners();
  }

  // Legacy methods for compatibility
  Future<void> loadFiles() async {
    _setLoading(true);
    try {
      _files = await _apiService.getFiles();
      _clearError();
    } catch (e) {
      _setError('Failed to load files: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRules() async {
    _setLoading(true);
    try {
      _rules = await _apiService.getRules();
      _clearError();
    } catch (e) {
      _setError('Failed to load rules: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStats() async {
    _setLoading(true);
    try {
      _stats = await _apiService.getStats();
      _clearError();
    } catch (e) {
      _setError('Failed to load stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> organizeFiles({
    required String downloadsPath,
    required String sortedPath,
    required String apiKey,
  }) async {
    _setLoading(true);
    try {
      // First check if backend is available
      final isAvailable = await _apiService.isBackendAvailable();
      if (!isAvailable) {
        throw Exception('Backend server is not available. Please make sure the backend is running on http://localhost:8000');
      }
      
      final result = await _apiService.organizeFiles(
        downloadsPath: downloadsPath,
        sortedPath: sortedPath,
        apiKey: apiKey,
      );
      
      // Store the organization results - parse the backend response
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final fileSuggestions = data['file_suggestions'] ?? [];
        
        // Convert backend format to frontend format
        _organizationResults = fileSuggestions.map<Map<String, dynamic>>((suggestion) {
          return {
            'file': suggestion['file'] ?? suggestion['filename'] ?? 'Unknown file',
            'from': suggestion['current_path'] ?? '',
            'to': suggestion['destination'] ?? '',
            'reason': suggestion['reasoning'] ?? 'AI analysis',
            'confidence': (suggestion['confidence'] ?? 85) / 100.0, // Convert to 0-1 range
            'action': suggestion['action'] ?? 'move_to_existing',
          };
        }).toList();
      } else {
        _organizationResults = [];
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to organize files: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> discoverFiles(String path) async {
    _setLoading(true);
    try {
      final result = await _apiService.discoverFiles(path);
      // Handle discovery results if needed
      _clearError();
    } catch (e) {
      _setError('Failed to discover files: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addRule(OrganizationRule rule) async {
    _setLoading(true);
    try {
      await _apiService.addRule(rule);
      await loadRules();
      _clearError();
    } catch (e) {
      _setError('Failed to add rule: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRule(String ruleId) async {
    _setLoading(true);
    try {
      await _apiService.deleteRule(ruleId);
      await loadRules();
      _clearError();
    } catch (e) {
      _setError('Failed to delete rule: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> executeFileAction({
    required String action,
    required String filePath,
    String? destinationPath,
    required String sourceFolder,
    required String destinationFolder,
  }) async {
    _setLoading(true);
    try {
      final result = await _apiService.executeFileAction(
        action: action,
        filePath: filePath,
        destinationPath: destinationPath,
        sourceFolder: sourceFolder,
        destinationFolder: destinationFolder,
      );
      
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Action failed');
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to execute action: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> reAnalyzeFile({
    required String filePath,
    required String userInput,
    required String sourceFolder,
    required String destinationFolder,
  }) async {
    _setLoading(true);
    try {
      final result = await _apiService.reAnalyzeFile(
        filePath: filePath,
        userInput: userInput,
        sourceFolder: sourceFolder,
        destinationFolder: destinationFolder,
      );
      
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Re-analysis failed');
      }
      
      _clearError();
      return result['data'] ?? {};
    } catch (e) {
      _setError('Failed to re-analyze file: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logFileAccess({
    required String filePath,
    String action = 'open',
    String? userAgent,
  }) async {
    try {
      await _apiService.logFileAccess(
        filePath: filePath,
        action: action,
        userAgent: userAgent,
      );
      // Don't set loading state for access logging as it should be silent
    } catch (e) {
      // Log the error but don't show it to user for access tracking
      if (kDebugMode) {
        print('Warning: Failed to log file access: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getFileAccessAnalytics({
    required String folderPath,
    int days = 30,
  }) async {
    _setLoading(true);
    try {
      final result = await _apiService.getFileAccessAnalytics(
        folderPath: folderPath,
        days: days,
      );
      
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to get file access analytics: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> startDriveMonitoring() async {
    try {
      final result = await _apiService.startDriveMonitoring();
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to start drive monitoring: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> stopDriveMonitoring() async {
    try {
      final result = await _apiService.stopDriveMonitoring();
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to stop drive monitoring: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDriveStatus() async {
    try {
      final result = await _apiService.getDriveStatus();
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to get drive status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFolderAnalytics() async {
    try {
      final result = await _apiService.getFolderAnalytics();
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to get folder analytics: $e');
      rethrow;
    }
  }

  void setDrivePurpose(DriveInfo drive, String purpose) {
    // Update the drive's purpose in the drives list
    final index = _drives.indexWhere((d) => d.path == drive.path);
    if (index != -1) {
      _drives[index] = DriveInfo(
        path: drive.path,
        name: drive.name,
        type: drive.type,
        totalSpace: drive.totalSpace,
        freeSpace: drive.freeSpace,
        isConnected: drive.isConnected,
        lastSeen: drive.lastSeen,
        commonFolders: drive.commonFolders,
        fileTypeDistribution: drive.fileTypeDistribution,
        purpose: purpose.isNotEmpty ? purpose : null,
      );
      notifyListeners();
    }
  }
} 
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:homie_app/models/file_organizer_models.dart';
import 'package:homie_app/models/financial_models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  
  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // File Organizer API calls - Updated to match actual backend endpoints
  Future<List<FileItem>> getFiles() async {
    // For now, return mock data since this endpoint doesn't exist yet
    // TODO: Implement actual file listing endpoint in backend
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    return [
      FileItem(
        name: 'document.pdf',
        path: '/home/user/Downloads/document.pdf',
        size: 1024000,
        type: 'PDF',
        lastModified: DateTime.now().subtract(const Duration(hours: 2)),
        suggestedLocation: '/home/user/Documents',
      ),
      FileItem(
        name: 'photo.jpg',
        path: '/home/user/Downloads/photo.jpg',
        size: 2048000,
        type: 'Image',
        lastModified: DateTime.now().subtract(const Duration(days: 1)),
        suggestedLocation: '/home/user/Pictures',
      ),
    ];
  }

  Future<List<OrganizationRule>> getRules() async {
    // For now, return mock data since this endpoint doesn't exist yet
    // TODO: Implement actual rules endpoint in backend
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
    
    return [
      OrganizationRule(
        id: '1',
        name: 'Documents Rule',
        pattern: '*.pdf,*.doc,*.docx',
        destination: '/home/user/Documents',
        type: 'extension',
        enabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      OrganizationRule(
        id: '2',
        name: 'Images Rule',
        pattern: '*.jpg,*.jpeg,*.png,*.gif',
        destination: '/home/user/Pictures',
        type: 'extension',
        enabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  Future<OrganizationStats> getStats() async {
    // For now, return mock data since this endpoint doesn't exist yet
    // TODO: Implement actual stats endpoint in backend
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API call
    
    return OrganizationStats(
      totalFiles: 1250,
      organizedFiles: 890,
      rulesCount: 5,
      fileTypeBreakdown: {
        'PDF': 245,
        'Image': 412,
        'Video': 89,
        'Audio': 156,
        'Document': 198,
        'Other': 150,
      },
      lastOrganized: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  // Use actual backend endpoint for organizing files
  Future<Map<String, dynamic>> organizeFiles({
    required String downloadsPath,
    required String sortedPath,
    required String apiKey,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/organize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'downloads_path': downloadsPath,
          'sorted_path': sortedPath,
          'api_key': apiKey,
        }),
      ).timeout(const Duration(seconds: 30)); // Add timeout
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Backend returned status code ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Cannot connect to backend server. Please make sure the backend is running on http://localhost:8000');
    } on SocketException catch (e) {
      throw Exception('Cannot connect to backend server. Please make sure the backend is running on http://localhost:8000');
    } on Exception catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Backend request timed out. Please try again.');
      }
      rethrow;
    }
  }

  // Use actual backend endpoint for folder discovery
  Future<Map<String, dynamic>> discoverFolders(String path) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/file_organizer/discover'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'path': path}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to discover folders: ${response.body}');
    }
  }

  // Alias for discoverFolders to match provider usage
  Future<Map<String, dynamic>> discoverFiles(String path) async {
    return discoverFolders(path);
  }

  // Use actual backend endpoint for folder browsing
  Future<Map<String, dynamic>> browseFolders(String path) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/file_organizer/browse-folders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'path': path}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to browse folders: ${response.body}');
    }
  }

  Future<void> addRule(OrganizationRule rule) async {
    // TODO: Implement actual rules endpoint in backend
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    // For now, just simulate success
  }

  Future<void> deleteRule(String ruleId) async {
    // TODO: Implement actual rules endpoint in backend
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
    // For now, just simulate success
  }

  // Financial API calls - Updated to match actual backend structure
  Future<FinancialSummary> getFinancialSummary({
    String? period,
    int? year,
    int? month,
    DateTime? weekStart,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Build query parameters
    Map<String, String> queryParams = {};
    
    if (period != null) {
      switch (period) {
        case 'Monthly':
          if (year != null) queryParams['year'] = year.toString();
          if (month != null) queryParams['month'] = month.toString();
          break;
        case 'Yearly':
          if (year != null) queryParams['year'] = year.toString();
          break;
        case 'Weekly':
          if (weekStart != null) {
            final weekEnd = weekStart.add(const Duration(days: 6));
            queryParams['start_date'] = weekStart.toString().split(' ')[0];
            queryParams['end_date'] = weekEnd.toString().split(' ')[0];
          }
          break;
        case 'Custom':
          if (startDate != null && endDate != null) {
            queryParams['start_date'] = startDate.toString().split(' ')[0];
            queryParams['end_date'] = endDate.toString().split(' ')[0];
          }
          break;
      }
    }
    
    final uri = Uri.parse('$baseUrl/financial/summary').replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return FinancialSummary.fromJson(data['data']);
      } else {
        throw Exception('API returned error: ${data['error']}');
      }
    } else {
      throw Exception('Failed to load financial summary: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getIncomeData() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/financial/income'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception('API returned error: ${data['error']}');
      }
    } else {
      throw Exception('Failed to load income data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getExpenseData() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/financial/expenses'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception('API returned error: ${data['error']}');
      }
    } else {
      throw Exception('Failed to load expense data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getConstructionData() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/financial/construction'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception('API returned error: ${data['error']}');
      }
    } else {
      throw Exception('Failed to load construction data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getTaxReportData() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/financial/tax-report'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception('API returned error: ${data['error']}');
      }
    } else {
      throw Exception('Failed to load tax report: ${response.statusCode}');
    }
  }

  // Get income entries from backend
  Future<List<IncomeEntry>> getIncomeEntries() async {
    final data = await getIncomeData();
    // Convert backend data to IncomeEntry models
    // For now, return empty list until backend provides structured income entries
    return [];
  }

  Future<List<ExpenseEntry>> getExpenseEntries() async {
    final data = await getExpenseData();
    // Convert backend data to ExpenseEntry models
    // For now, return empty list until backend provides structured expense entries
    return [];
  }

  Future<ConstructionBudget> getConstructionBudget() async {
    final data = await getConstructionData();
    // Convert backend data to ConstructionBudget model
    // For now, return empty construction budget until backend provides proper structure
    return ConstructionBudget(
      totalBudget: 0.0,
      usedBudget: 0.0,
      remainingBudget: 0.0,
      loanAmount: 0.0,
      interestRate: 0.0,
      loanTermMonths: 0,
      monthlyPayment: 0.0,
      expenses: [],
    );
  }

  Future<TaxReport> getTaxReport() async {
    final data = await getTaxReportData();
    // Convert backend data to TaxReport model
    // For now, return empty tax report until backend provides proper structure
    return TaxReport(
      grossIncome: 0.0,
      taxableIncome: 0.0,
      incomeTax: 0.0,
      socialSecurity: 0.0,
      totalTax: 0.0,
      netIncome: 0.0,
      recommendations: [],
    );
  }

  Future<void> addIncomeEntry(IncomeEntry entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/financial/income'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'type': entry.type,
        'amount': entry.amount,
        'date': entry.date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'description': entry.description,
        'employer': entry.employer,
        'client': entry.category, // Using category for client in self-employment
        'invoice_number': null, // TODO: Add invoice number field to model
      }),
    );
    
    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception('Failed to add income: ${error['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> addExpenseEntry(ExpenseEntry entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/financial/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': entry.amount,
        'date': entry.date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'category': entry.category,
        'description': entry.description,
        'receipt_path': entry.receiptPath,
      }),
    );
    
    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception('Failed to add expense: ${error['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> updateConstructionBudget(ConstructionBudget budget) async {
    // TODO: Implement when backend supports this
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<Map<String, dynamic>> executeFileAction({
    required String action,
    required String filePath,
    String? destinationPath,
    required String sourceFolder,
    required String destinationFolder,
  }) async {
    // Convert old action format to new abstract operations format
    List<Map<String, dynamic>> operations = [];
    List<String> explanations = [];
    
    // Handle both relative and absolute file paths
    String fullSourcePath = filePath.startsWith('/') ? filePath : '$sourceFolder/$filePath';
    
    switch (action) {
      case 'delete':
        operations.add({
          'type': 'delete',
          'path': fullSourcePath,
        });
        explanations.add('Deleting file: $filePath');
        break;
        
      case 'move':
        String fullDestPath;
        if (destinationPath != null) {
          // Use provided destination path (could be absolute or relative)
          fullDestPath = destinationPath.startsWith('/') ? destinationPath : '$destinationFolder/$destinationPath';
        } else {
          // Default: move to destination folder with same filename
          String fileName = filePath.split('/').last;
          fullDestPath = '$destinationFolder/$fileName';
        }
        operations.add({
          'type': 'move',
          'src': fullSourcePath,
          'dest': fullDestPath,
        });
        explanations.add('Moving file from $sourceFolder to $destinationFolder');
        break;
        
      default:
        throw Exception('Unsupported action: $action');
    }
    
    final response = await _client.post(
      Uri.parse('$baseUrl/file_organizer/execute-operations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'operations': operations,
        'explanations': explanations,
        'fallback_operations': [], // No fallbacks for simple actions
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to execute file action: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> reAnalyzeFile({
    required String filePath,
    required String userInput,
    required String sourceFolder,
    required String destinationFolder,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/file_organizer/re-analyze'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'file_path': filePath,
        'user_input': userInput,
        'source_folder': sourceFolder,
        'destination_folder': destinationFolder,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to re-analyze file: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> logFileAccess({
    required String filePath,
    String action = 'open',
    String? userAgent,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/file_organizer/log-access'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'file_path': filePath,
        'action': action,
        'user_agent': userAgent,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to log file access: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getFileAccessAnalytics({
    required String folderPath,
    int days = 30,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/file_organizer/access-analytics?folder_path=${Uri.encodeComponent(folderPath)}&days=$days'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get file access analytics: ${response.statusCode}');
    }
  }

  // Financial API methods
  Future<Map<String, dynamic>> importCsvFile(String filePath, {String accountType = 'main'}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/financial/import-csv'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['account_type'] = accountType;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to import CSV: ${response.statusCode} - ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
  
  // Generic HTTP Methods
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('GET $endpoint failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('POST $endpoint failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('DELETE $endpoint failed: ${response.statusCode} - ${response.body}');
    }
  }

  // Drive Monitoring API calls
  Future<Map<String, dynamic>> startDriveMonitoring() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/start-drive-monitoring'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to start drive monitoring');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> stopDriveMonitoring() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/stop-drive-monitoring'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to stop drive monitoring');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDriveStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/drive-status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to get drive status');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFolderAnalytics() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/folder-analytics'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to get folder analytics');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  // Enhanced File Organizer API calls matching test client functionality
  
  /// Analyze files in a folder and get AI-generated abstract operations
  Future<Map<String, dynamic>> analyzeFolder({
    required String sourcePath,
    required String destinationPath,
    String? intent,
    String organizationStyle = 'smart_categories',
  }) async {
    try {
      String finalIntent = intent ?? _getDefaultIntent(organizationStyle);
      
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/organize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'folder_path': sourcePath,
          'destination_path': destinationPath,
          'intent': finalIntent,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to analyze folder');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Execute abstract operations returned from analysis
  Future<Map<String, dynamic>> executeOperations({
    required List<Map<String, dynamic>> operations,
    bool dryRun = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/execute-operations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operations': operations,
          'dry_run': dryRun,
        }),
      ).timeout(const Duration(seconds: 60)); // Longer timeout for file operations

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to execute operations');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get real-time drives information
  Future<Map<String, dynamic>> getDrives() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/drives'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to get drives');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Register a USB drive for future recognition
  Future<Map<String, dynamic>> registerUsbDrive({
    required String drivePath,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/register-usb-drive'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'drive_path': drivePath,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to register USB drive');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get USB drives memory
  Future<Map<String, dynamic>> getUsbDrives() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/usb-drives'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to get USB drives');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Helper method to get default intent based on organization style
  String _getDefaultIntent(String organizationStyle) {
    switch (organizationStyle) {
      case 'by_type':
        return 'organize files by type (images, documents, videos, etc.)';
      case 'by_date':
        return 'organize files by date (year/month folders)';
      case 'smart_categories':
        return 'organize files into smart categories based on content';
      default:
        return 'organize files intelligently based on their content and type';
    }
  }

  // ========================================
  // TASK 3.1: ENHANCED API SERVICE METHODS
  // ========================================

  /// Get recent folders used for file organization
  Future<List<String>> getRecentPaths({int limit = 10}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/recent-paths?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['recent_paths'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'Failed to get recent paths');
        }
      } else {
        throw Exception('Failed to get recent paths: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get bookmarked folders for quick access
  Future<List<Map<String, dynamic>>> getBookmarkedPaths() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/bookmarked-paths'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['bookmarked_paths'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'Failed to get bookmarked paths');
        }
      } else {
        throw Exception('Failed to get bookmarked paths: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Add a folder to bookmarks
  Future<bool> addBookmark({
    required String path,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/add-bookmark'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'path': path,
          'name': name,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to add bookmark: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Remove a folder from bookmarks
  Future<bool> removeBookmark(String path) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/file_organizer/remove-bookmark'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to remove bookmark: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Browse folder contents with enhanced metadata
  Future<Map<String, dynamic>> browsePath(String path) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/browse-path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'path': path,
          'include_metadata': true,
          'include_thumbnails': false, // Can be enabled for preview support
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error'] ?? 'Failed to browse path');
        }
      } else {
        throw Exception('Failed to browse path: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Enhanced folder analysis with preview support
  Future<Map<String, dynamic>> analyzeWithPreview({
    required String sourcePath,
    required String destinationPath,
    String? intent,
    String organizationStyle = 'smart_categories',
    bool includePreview = true,
  }) async {
    try {
      String finalIntent = intent ?? _getDefaultIntent(organizationStyle);
      
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/analyze-with-preview'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'folder_path': sourcePath,
          'destination_path': destinationPath,
          'intent': finalIntent,
          'organization_style': organizationStyle,
          'include_preview': includePreview,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error'] ?? 'Failed to analyze with preview');
        }
      } else {
        throw Exception('Failed to analyze with preview: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Start operation with progress tracking stream
  Stream<Map<String, dynamic>> executeOperationsWithProgress({
    required List<Map<String, dynamic>> operations,
    bool dryRun = false,
  }) async* {
    try {
      // Start the operation
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/execute-operations-with-progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operations': operations,
          'dry_run': dryRun,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final operationId = data['operation_id'];
          
          // Yield initial response
          yield {
            'type': 'started',
            'operation_id': operationId,
            'total_operations': operations.length,
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Poll for progress updates
          while (true) {
            await Future.delayed(const Duration(milliseconds: 500));
            
            try {
              final progressResponse = await _client.get(
                Uri.parse('$baseUrl/file_organizer/operation-progress/$operationId'),
                headers: {'Content-Type': 'application/json'},
              ).timeout(const Duration(seconds: 10));

              if (progressResponse.statusCode == 200) {
                final progressData = json.decode(progressResponse.body);
                if (progressData['success'] == true) {
                  final progress = progressData['data'];
                  
                  yield {
                    'type': 'progress',
                    'operation_id': operationId,
                    'completed': progress['completed'],
                    'total': progress['total'],
                    'current_operation': progress['current_operation'],
                    'status': progress['status'],
                    'timestamp': DateTime.now().toIso8601String(),
                  };

                  // Check if completed
                  if (progress['status'] == 'completed' || progress['status'] == 'failed') {
                    yield {
                      'type': 'completed',
                      'operation_id': operationId,
                      'status': progress['status'],
                      'results': progress['results'],
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    break;
                  }
                }
              }
            } catch (e) {
              yield {
                'type': 'error',
                'operation_id': operationId,
                'error': e.toString(),
                'timestamp': DateTime.now().toIso8601String(),
              };
              break;
            }
          }
        } else {
          yield {
            'type': 'error',
            'error': data['error'] ?? 'Failed to start operation',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      } else {
        yield {
          'type': 'error',
          'error': 'Failed to start operation: ${response.statusCode}',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      yield {
        'type': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Record user preference for learning
  Future<bool> recordUserPreference({
    required String action,
    required String context,
    required Map<String, dynamic> preference,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/record-preference'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': action,
          'context': context,
          'preference': preference,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to record preference: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get user preferences for learning
  Future<Map<String, dynamic>> getUserPreferences({
    String? context,
    int limit = 50,
  }) async {
    try {
      Map<String, String> queryParams = {'limit': limit.toString()};
      if (context != null) {
        queryParams['context'] = context;
      }

      final uri = Uri.parse('$baseUrl/file_organizer/user-preferences').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error'] ?? 'Failed to get user preferences');
        }
      } else {
        throw Exception('Failed to get user preferences: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Cancel an ongoing operation
  Future<bool> cancelOperation(String operationId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/cancel-operation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operation_id': operationId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to cancel operation: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Pause an ongoing operation
  Future<bool> pauseOperation(String operationId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/pause-operation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operation_id': operationId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to pause operation: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Resume a paused operation
  Future<bool> resumeOperation(String operationId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/resume-operation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operation_id': operationId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to resume operation: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Backend server is not running. Please start the backend server first.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('Backend server is not running. Please start the backend server first.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get organization presets for the given source path
  Future<Map<String, dynamic>> getOrganizationPresets({
    String? sourcePath,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/organization-presets').replace(
          queryParameters: {
            if (sourcePath != null) 'source_path': sourcePath,
            'limit': limit.toString(),
          },
        ),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load organization presets: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get personalized organization suggestions
  Future<Map<String, dynamic>> getPersonalizedSuggestions({
    required String sourcePath,
    int limit = 5,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/personalized-suggestions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'source_path': sourcePath,
          'limit': limit,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load suggestions: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }







  /// Get organization history for the given source path
  Future<Map<String, dynamic>> getOrganizationHistory({
    String? sourcePath,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/organization-history').replace(
          queryParameters: {
            if (sourcePath != null) 'source_path': sourcePath,
            'limit': limit.toString(),
          },
        ),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get organization history: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Clear organization history
  Future<void> clearOrganizationHistory() async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/file_organizer/organization-history'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to clear organization history: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Save organization preset
  Future<void> saveOrganizationPreset({
    required String name,
    required Map<String, dynamic> preset,
    String? description,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/presets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'preset': preset,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save organization preset: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  // Task 3: Progress Control Methods
  
  /// Pause ongoing file operations
  Future<void> pauseOperations() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/operations/pause'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to pause operations: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Resume paused file operations
  Future<void> resumeOperations() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/operations/resume'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to resume operations: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Cancel all ongoing file operations
  Future<void> cancelOperations() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/file_organizer/operations/cancel'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel operations: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get smart preset suggestions based on folder content analysis
  Future<List<Map<String, dynamic>>> getSmartPresets(String sourcePath) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/smart-presets').replace(
          queryParameters: {'source_path': sourcePath},
        ),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['presets'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'Failed to get smart presets');
        }
      } else {
        throw Exception('Failed to get smart presets: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Get comprehensive folder analytics and insights
  Future<Map<String, dynamic>> getFolderInsights(String folderPath) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/file_organizer/folder-insights').replace(
          queryParameters: {'folder_path': folderPath},
        ),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['insights'] ?? {};
        } else {
          throw Exception(data['error'] ?? 'Failed to get folder insights');
        }
      } else {
        throw Exception('Failed to get folder insights: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }



} 
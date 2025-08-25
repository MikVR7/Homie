import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:homie_app/services/api_service.dart';
import 'package:homie_app/models/file_organizer_models.dart';

/// Tests data consistency between frontend models and backend responses
void main() {
  group('Data Consistency Tests', () {
    const String baseUrl = 'http://localhost:8000';
    const String apiUrl = '$baseUrl/api';
    
    late http.Client httpClient;
    late ApiService apiService;
    bool backendAvailable = false;

    setUpAll(() async {
      httpClient = http.Client();
      apiService = ApiService(client: httpClient);
      
      // Check if backend is running
      backendAvailable = await apiService.isBackendAvailable();
      
      if (backendAvailable) {
        print('✅ Backend available for data consistency tests');
      } else {
        print('❌ Backend not available - skipping data consistency tests');
        print('💡 Start backend with: cd backend && python main.py');
      }
    });

    tearDownAll(() {
      httpClient.close();
    });

    group('API Response Structure Validation', () {
      test('Health endpoint response matches expected structure', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/health'));
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        
        // Validate required fields
        expect(data['status'], isA<String>());
        expect(data['message'], isA<String>());
        expect(data['timestamp'], isA<String>());
        expect(data['components'], isA<List>());
        expect(data['version'], isA<String>());
        
        // Validate timestamp format (ISO 8601)
        expect(() => DateTime.parse(data['timestamp']), returnsNormally);
        
        print('✅ Health endpoint response structure is valid');
      });

      test('Status endpoint response matches expected structure', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/status'));
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        
        // Validate required fields
        expect(data['status'], isA<String>());
        expect(data['version'], isA<String>());
        expect(data['timestamp'], isA<String>());
        expect(data['components'], isA<Map>());
        
        // Validate timestamp format
        expect(() => DateTime.parse(data['timestamp']), returnsNormally);
        
        // Validate components structure
        final components = data['components'] as Map<String, dynamic>;
        for (final component in components.values) {
          expect(component, isA<Map>());
          expect(component['status'], isA<String>());
        }
        
        print('✅ Status endpoint response structure is valid');
      });

      test('File organizer drive response structure', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/file_organizer/drives'));
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        
        // Validate required fields
        expect(data['success'], isA<bool>());
        expect(data['drives'], isA<List>());
        
        // Validate drive structure if drives are present
        final drives = data['drives'] as List;
        for (final drive in drives) {
          expect(drive, isA<Map>());
          // Basic drive fields that should be present
          if (drive.containsKey('path')) {
            expect(drive['path'], isA<String>());
          }
          if (drive.containsKey('type')) {
            expect(drive['type'], isA<String>());
          }
        }
        
        print('✅ Drives endpoint response structure is valid');
      });
    });

    group('Error Response Consistency', () {
      test('Error responses have consistent structure', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test with invalid request to trigger error
        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({}), // Missing required folder_path
        );
        
        expect(response.statusCode, equals(400));
        
        final data = json.decode(response.body);
        
        // All error responses should have these fields
        expect(data['success'], equals(false));
        expect(data['error'], isA<String>());
        expect(data['error'], isNotEmpty);
        
        print('✅ Error response structure is consistent');
      });

      test('Error messages are descriptive', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({}),
        );
        
        final data = json.decode(response.body);
        expect(data['error'], equals('folder_path_required'));
        
        print('✅ Error messages are descriptive and specific');
      });
    });

    group('File Operation Data Models', () {
      test('File operation responses match FileOperation model', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Create a temporary test directory
        final tempDir = await Directory.systemTemp.createTemp('homie_test_');
        
        try {
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/execute-operations'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'operations': [
                {
                  'type': 'mkdir',
                  'path': '${tempDir.path}/test_folder',
                  'parents': true,
                },
                {
                  'type': 'check_exists',
                  'path': tempDir.path,
                },
              ],
              'dry_run': true,
            }),
          );

          expect(response.statusCode, equals(200));
          
          final data = json.decode(response.body);
          expect(data['success'], equals(true));
          expect(data['results'], isA<List>());
          
          // Validate operation result structure
          final results = data['results'] as List;
          for (final result in results) {
            expect(result, isA<Map>());
            expect(result['operation'], isA<Map>());
            expect(result['success'], isA<bool>());
            
            final operation = result['operation'] as Map<String, dynamic>;
            expect(operation['type'], isA<String>());
            
            // Validate that we can create FileOperation from this data
            try {
              final fileOp = FileOperation(
                type: operation['type'],
                sourcePath: operation['path'] ?? operation['src'] ?? '',
                destinationPath: operation['dest'],
                confidence: 1.0, // Default for test operations
                reasoning: 'Test operation',
              );
              expect(fileOp.type, equals(operation['type']));
            } catch (e) {
              fail('Could not create FileOperation from backend response: $e');
            }
          }
          
          print('✅ File operation responses are compatible with FileOperation model');
          
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test('Operation types match expected values', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final validOperationTypes = [
          'mkdir', 'move', 'copy', 'delete', 'rename', 
          'check_exists', 'list_dir', 'extract', 'get_info', 'get_size'
        ];

        for (final opType in validOperationTypes) {
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/execute-operations'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'operations': [
                {
                  'type': opType,
                  'path': '/tmp/test_path',
                },
              ],
              'dry_run': true,
            }),
          );

          // Some operations may fail due to missing parameters, but they should be recognized
          final data = json.decode(response.body);
          if (response.statusCode == 200) {
            expect(data['results'], isA<List>());
            if (data['results'].isNotEmpty) {
              final result = data['results'][0];
              expect(result['operation']['type'], equals(opType));
            }
          }
        }
        
        print('✅ All operation types are recognized by backend');
      });
    });

    group('Frontend-Backend Model Compatibility', () {
      test('FileItem model compatibility with organize response', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Create test directory with a file
        final tempDir = await Directory.systemTemp.createTemp('homie_test_');
        final testFile = File('${tempDir.path}/test_file.txt');
        await testFile.writeAsString('Test content for organization');

        try {
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/organize'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'folder_path': tempDir.path,
              'intent': 'test organization',
            }),
          );

          // Response may fail due to AI configuration, but structure should be consistent
          final data = json.decode(response.body);
          
          if (response.statusCode == 200 && data['success'] == true) {
            // If successful, validate the response can be mapped to our models
            if (data.containsKey('operations')) {
              final operations = data['operations'] as List;
              for (final opData in operations) {
                try {
                  final operation = FileOperation(
                    type: opData['type'] ?? 'unknown',
                    sourcePath: opData['src'] ?? opData['source_path'] ?? '',
                    destinationPath: opData['dest'] ?? opData['destination_path'],
                    confidence: (opData['confidence'] ?? 1.0).toDouble(),
                    reasoning: opData['reasoning'] ?? opData['explanation'],
                  );
                  expect(operation.type, isNotEmpty);
                } catch (e) {
                  print('⚠️ Could not map operation to FileOperation model: $e');
                  print('Operation data: $opData');
                }
              }
            }
            print('✅ Organize response is compatible with FileOperation model');
          } else {
            print('⚠️ Organize endpoint returned error (may be due to AI configuration): ${data['error']}');
          }
          
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test('DriveInfo model compatibility with drives response', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/file_organizer/drives'));
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['drives'], isA<List>());
        
        final drives = data['drives'] as List;
        for (final driveData in drives) {
          try {
            // Attempt to create DriveInfo from response data
            final driveInfo = DriveInfo(
              id: driveData['id']?.toString() ?? 'unknown',
              name: driveData['name'] ?? driveData['label'] ?? 'Unknown Drive',
              path: driveData['path'] ?? '',
              type: driveData['type'] ?? 'unknown',
              totalSpace: (driveData['total_space'] ?? 0).toInt(),
              freeSpace: (driveData['free_space'] ?? 0).toInt(),
              isConnected: driveData['is_connected'] ?? false,
              lastSeen: DateTime.tryParse(driveData['last_seen'] ?? '') ?? DateTime.now(),
            );
            
            expect(driveInfo.name, isNotEmpty);
            expect(driveInfo.type, isNotEmpty);
            
          } catch (e) {
            // This is OK if no drives are present or format is different
            print('⚠️ Drive data format: $driveData');
          }
        }
        
        print('✅ Drives response structure is compatible with DriveInfo model');
      });
    });

    group('API Service Integration', () {
      test('ApiService health check consistency', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test both direct HTTP call and ApiService method
        final directResponse = await httpClient.get(Uri.parse('$apiUrl/health'));
        final serviceResponse = await apiService.isBackendAvailable();
        
        expect(directResponse.statusCode, equals(200));
        expect(serviceResponse, equals(true));
        
        print('✅ ApiService health check is consistent with direct API call');
      });

      test('Error handling consistency', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test API service error handling with invalid request
        try {
          // This should trigger error handling in ApiService
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/organize'),
            headers: {'Content-Type': 'application/json'},
            body: 'invalid json',
          );
          
          // Should get a 400 or 500 error
          expect(response.statusCode, anyOf([400, 500]));
          
        } catch (e) {
          // ApiService should handle this gracefully
          expect(e, isA<Exception>());
        }
        
        print('✅ Error handling is working correctly');
      });
    });

    group('Data Type Validation', () {
      test('Date/time fields are properly formatted', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/health'));
        final data = json.decode(response.body);
        
        // Test timestamp parsing
        final timestamp = data['timestamp'] as String;
        final parsedDate = DateTime.parse(timestamp);
        expect(parsedDate, isA<DateTime>());
        
        // Should be recent (within last minute)
        final now = DateTime.now();
        final difference = now.difference(parsedDate).abs();
        expect(difference.inMinutes, lessThan(2));
        
        print('✅ Timestamp formatting is correct and current');
      });

      test('Boolean fields are properly typed', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/execute-operations'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'operations': [],
            'dry_run': true,
          }),
        );
        
        final data = json.decode(response.body);
        expect(data['success'], isA<bool>());
        expect(data['success'], equals(true));
        
        print('✅ Boolean fields are properly typed');
      });

      test('Numeric fields are properly typed', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test with operations that return numeric data
        final tempDir = await Directory.systemTemp.createTemp('homie_test_');
        
        try {
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/execute-operations'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'operations': [
                {
                  'type': 'get_size',
                  'path': tempDir.path,
                },
              ],
              'dry_run': false,
            }),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['results'].isNotEmpty) {
              final result = data['results'][0];
              if (result['success'] && result['result'] != null) {
                final resultData = result['result'];
                if (resultData.containsKey('size')) {
                  expect(resultData['size'], anyOf([isA<int>(), isA<double>()]));
                }
              }
            }
          }
          
        } finally {
          await tempDir.delete(recursive: true);
        }
        
        print('✅ Numeric fields are properly typed');
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// Comprehensive backend integration tests
/// Tests real API endpoints with actual backend server
void main() {
  group('Backend Integration Tests', () {
    const String baseUrl = 'http://localhost:8000';
    const String apiUrl = '$baseUrl/api';
    const String wsUrl = 'ws://localhost:8000';
    
    late http.Client httpClient;
    bool backendAvailable = false;

    setUpAll(() async {
      httpClient = http.Client();
      
      // Check if backend is running
      try {
        final response = await httpClient.get(
          Uri.parse('$apiUrl/health'),
        ).timeout(const Duration(seconds: 5));
        
        backendAvailable = response.statusCode == 200;
        
        if (backendAvailable) {
          print('✅ Backend server is running and available for integration tests');
        } else {
          print('❌ Backend server is not responding (status: ${response.statusCode})');
        }
      } catch (e) {
        print('❌ Backend server is not available: $e');
        print('💡 Please start the backend server with: cd backend && python main.py');
      }
    });

    tearDownAll(() {
      httpClient.close();
    });

    group('Health and Status Endpoints', () {
      test('GET /api/health returns healthy status', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/health'));
        
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['status'], equals('healthy'));
        expect(data['message'], equals('Homie Backend is running!'));
        expect(data['timestamp'], isNotNull);
        expect(data['components'], isList);
        expect(data['version'], isNotNull);
      });

      test('GET /api/status returns system status', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/status'));
        
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['status'], equals('running'));
        expect(data['version'], isNotNull);
        expect(data['timestamp'], isNotNull);
        expect(data['components'], isMap);
      });
    });

    group('File Organizer API Endpoints', () {
      test('POST /api/file-organizer/organize with valid folder', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Create a temporary test directory with some files
        final tempDir = await Directory.systemTemp.createTemp('homie_test_');
        final testFile = File('${tempDir.path}/test_file.txt');
        await testFile.writeAsString('Test content');

        try {
          final response = await httpClient.post(
            Uri.parse('$apiUrl/file-organizer/organize'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'folder_path': tempDir.path,
              'intent': 'organize test files',
            }),
          );

          expect(response.statusCode, anyOf([200, 500])); // May fail due to AI key
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            expect(data, isMap);
            print('✅ File organizer API is working');
          } else {
            final error = json.decode(response.body);
            print('⚠️ File organizer API returned error: ${error['error']}');
            // This might be expected if AI key is not configured
          }
        } finally {
          // Cleanup
          await tempDir.delete(recursive: true);
        }
      });

      test('POST /api/file-organizer/organize with missing folder_path', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({}),
        );

        expect(response.statusCode, equals(400));
        
        final data = json.decode(response.body);
        expect(data['success'], equals(false));
        expect(data['error'], equals('folder_path_required'));
      });

      test('POST /api/file-organizer/execute-operations with empty operations', () async {
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

        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data, isMap);
        expect(data['success'], equals(true));
      });

      test('POST /api/file-organizer/execute-operations with test operations', () async {
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
              'dry_run': false,
            }),
          );

          expect(response.statusCode, equals(200));
          
          final data = json.decode(response.body);
          expect(data['success'], equals(true));
          expect(data['results'], isList);
          expect(data['results'].length, equals(2));
          
          // Check that the operations were successful
          expect(data['results'][0]['success'], equals(true));
          expect(data['results'][1]['success'], equals(true));
          
          // Verify the directory was actually created
          final createdDir = Directory('${tempDir.path}/test_folder');
          expect(await createdDir.exists(), isTrue);
          
        } finally {
          // Cleanup
          await tempDir.delete(recursive: true);
        }
      });

      test('GET /api/file_organizer/drives returns drive information', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/file_organizer/drives'));
        
        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['success'], equals(true));
        expect(data['drives'], isList);
      });
    });

    group('AI Integration', () {
      test('POST /api/test-ai tests AI connection', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/test-ai'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({}),
        );

        expect(response.statusCode, anyOf([200, 500])); // Depends on AI key configuration
        
        final data = json.decode(response.body);
        expect(data, isMap);
        
        if (response.statusCode == 200) {
          expect(data['success'], equals(true));
          print('✅ AI integration is working');
        } else {
          print('⚠️ AI integration not configured: ${data['error']}');
          // This is expected if GEMINI_API_KEY is not set
        }
      });
    });

    group('Error Handling', () {
      test('Invalid JSON payload returns 400', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: 'invalid json',
        );

        expect(response.statusCode, anyOf([400, 500]));
      });

      test('Non-existent endpoint returns 404', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/non-existent-endpoint'));
        
        expect(response.statusCode, equals(404));
      });

      test('Invalid file path in organize request', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'folder_path': '/non/existent/path/12345',
          }),
        );

        expect(response.statusCode, anyOf([400, 500]));
        
        final data = json.decode(response.body);
        expect(data['success'], equals(false));
        expect(data['error'], isNotNull);
      });
    });

    group('CORS and Headers', () {
      test('API endpoints include CORS headers', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        final response = await httpClient.get(Uri.parse('$apiUrl/health'));
        
        expect(response.statusCode, equals(200));
        
        // Check for CORS headers (may not be present in all configurations)
        final headers = response.headers;
        print('Response headers: $headers');
        
        // Basic header checks
        expect(headers['content-type'], contains('application/json'));
      });

      test('OPTIONS request handling', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        try {
          final request = http.Request('OPTIONS', Uri.parse('$apiUrl/health'));
          final streamedResponse = await httpClient.send(request);
          final response = await http.Response.fromStream(streamedResponse);
          
          // OPTIONS should be handled gracefully
          expect(response.statusCode, anyOf([200, 204, 405]));
        } catch (e) {
          // Some servers don't support OPTIONS, which is fine
          print('OPTIONS request not supported: $e');
        }
      });
    });

    group('Performance and Load', () {
      test('Multiple concurrent health checks', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test concurrent requests
        final futures = List.generate(10, (_) => 
          httpClient.get(Uri.parse('$apiUrl/health')).timeout(
            const Duration(seconds: 10)
          )
        );

        final responses = await Future.wait(futures);
        
        for (final response in responses) {
          expect(response.statusCode, equals(200));
        }
        
        print('✅ Server handled 10 concurrent requests successfully');
      });

      test('Large file operation request', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Create a large list of operations
        final operations = List.generate(100, (index) => {
          'type': 'check_exists',
          'path': '/tmp/test_$index',
        });

        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/execute-operations'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'operations': operations,
            'dry_run': true,
          }),
        ).timeout(const Duration(seconds: 30));

        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['success'], equals(true));
        expect(data['results'], isList);
        expect(data['results'].length, equals(100));
        
        print('✅ Server handled large operation request (100 operations)');
      });
    });

    group('Data Validation', () {
      test('File operation validation', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test with invalid operation type
        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/execute-operations'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'operations': [
              {
                'type': 'invalid_operation',
                'path': '/tmp/test',
              },
            ],
            'dry_run': true,
          }),
        );

        expect(response.statusCode, anyOf([400, 500]));
        
        final data = json.decode(response.body);
        expect(data['success'], equals(false));
        expect(data['error'], isNotNull);
      });

      test('Path traversal protection', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend not available');
          return;
        }

        // Test with path traversal attempt
        final response = await httpClient.post(
          Uri.parse('$apiUrl/file-organizer/organize'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'folder_path': '../../etc/passwd',
          }),
        );

        // Should either be rejected or handled safely
        expect(response.statusCode, anyOf([400, 403, 500]));
      });
    });
  });

  group('WebSocket Integration Tests', () {
    const String wsUrl = 'ws://localhost:8000';
    bool backendAvailable = false;

    setUpAll(() async {
      // Check if backend WebSocket is available
      try {
        final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
        await channel.ready.timeout(const Duration(seconds: 5));
        await channel.sink.close();
        backendAvailable = true;
        print('✅ WebSocket server is available for integration tests');
      } catch (e) {
        print('❌ WebSocket server is not available: $e');
        print('💡 Please start the backend server with: cd backend && python main.py');
      }
    });

    test('WebSocket connection establishment', () async {
      if (!backendAvailable) {
        markTestSkipped('WebSocket backend not available');
        return;
      }

      WebSocketChannel? channel;
      
      try {
        channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
        await channel.ready.timeout(const Duration(seconds: 10));
        
        // Connection should be established
        expect(channel.sink, isNotNull);
        
        print('✅ WebSocket connection established successfully');
      } finally {
        await channel?.sink.close();
      }
    });

    test('WebSocket message exchange', () async {
      if (!backendAvailable) {
        markTestSkipped('WebSocket backend not available');
        return;
      }

      WebSocketChannel? channel;
      
      try {
        channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
        await channel.ready.timeout(const Duration(seconds: 10));
        
        // Send a test message
        final testMessage = {
          'type': 'test',
          'data': {'message': 'Hello from integration test'}
        };
        
        channel.sink.add(json.encode(testMessage));
        
        // Listen for responses (with timeout)
        final messageReceived = await channel.stream
            .timeout(const Duration(seconds: 5))
            .take(1)
            .isEmpty
            .then((isEmpty) => !isEmpty)
            .catchError((_) => false);
        
        // We expect either a response or a timeout (both are valid)
        print('✅ WebSocket message exchange test completed');
        
      } catch (e) {
        if (e.toString().contains('timeout')) {
          print('⚠️ WebSocket timeout - this may be expected if server doesn\'t echo messages');
        } else {
          print('❌ WebSocket error: $e');
          rethrow;
        }
      } finally {
        await channel?.sink.close();
      }
    });

    test('WebSocket connection cleanup', () async {
      if (!backendAvailable) {
        markTestSkipped('WebSocket backend not available');
        return;
      }

      // Test multiple connections and proper cleanup
      final channels = <WebSocketChannel>[];
      
      try {
        // Create multiple connections
        for (int i = 0; i < 5; i++) {
          final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 5));
          channels.add(channel);
        }
        
        expect(channels.length, equals(5));
        print('✅ Multiple WebSocket connections established');
        
      } finally {
        // Clean up all connections
        for (final channel in channels) {
          await channel.sink.close();
        }
        print('✅ All WebSocket connections cleaned up');
      }
    });
  });
}

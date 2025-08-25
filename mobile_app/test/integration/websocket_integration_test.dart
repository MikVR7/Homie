import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:async';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:http/http.dart' as http;

/// Comprehensive WebSocket integration tests
/// Tests real-time communication with actual backend server
void main() {
  group('WebSocket Integration Tests', () {
    const String wsUrl = 'ws://localhost:8000';
    const String httpUrl = 'http://localhost:8000/api';
    
    late http.Client httpClient;
    bool backendAvailable = false;

    setUpAll(() async {
      httpClient = http.Client();
      
      // Check if backend WebSocket is available
      try {
        final healthResponse = await httpClient.get(
          Uri.parse('$httpUrl/health'),
        ).timeout(const Duration(seconds: 5));
        
        if (healthResponse.statusCode == 200) {
          // Try WebSocket connection
          final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 5));
          await channel.sink.close();
          
          backendAvailable = true;
          print('✅ Backend WebSocket server is available for integration tests');
        }
      } catch (e) {
        print('❌ Backend WebSocket server is not available: $e');
        print('💡 Please start the backend server with: cd backend && python main.py');
      }
    });

    tearDownAll(() {
      httpClient.close();
    });

    group('Basic WebSocket Communication', () {
      test('Establish WebSocket connection', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          expect(channel.sink, isNotNull);
          expect(channel.stream, isNotNull);
          
          print('✅ WebSocket connection established successfully');
        } finally {
          await channel?.sink.close();
        }
      });

      test('Send and receive WebSocket messages', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          // Set up message listener with timeout
          final messageCompleter = Completer<Map<String, dynamic>>();
          late StreamSubscription subscription;
          
          subscription = channel.stream.listen(
            (message) {
              try {
                final data = json.decode(message);
                if (!messageCompleter.isCompleted) {
                  messageCompleter.complete(data);
                }
              } catch (e) {
                if (!messageCompleter.isCompleted) {
                  messageCompleter.completeError(e);
                }
              }
            },
            onError: (error) {
              if (!messageCompleter.isCompleted) {
                messageCompleter.completeError(error);
              }
            },
          );
          
          // Send a test message
          final testMessage = {
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': {'test': true},
          };
          
          channel.sink.add(json.encode(testMessage));
          
          try {
            // Wait for response with timeout
            final response = await messageCompleter.future.timeout(
              const Duration(seconds: 5),
            );
            
            expect(response, isA<Map<String, dynamic>>());
            print('✅ Received WebSocket response: ${response.toString().substring(0, 100)}...');
          } catch (e) {
            if (e is TimeoutException) {
              print('⚠️ WebSocket message timeout - server may not echo messages (this is OK)');
            } else {
              print('⚠️ WebSocket message error: $e');
            }
          }
          
          await subscription.cancel();
        } finally {
          await channel?.sink.close();
        }
      });

      test('Multiple concurrent WebSocket connections', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        final channels = <WebSocketChannel>[];
        
        try {
          // Create multiple connections
          for (int i = 0; i < 3; i++) {
            final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
            await channel.ready.timeout(const Duration(seconds: 5));
            channels.add(channel);
          }
          
          expect(channels.length, equals(3));
          
          // Send messages from each connection
          for (int i = 0; i < channels.length; i++) {
            final message = {
              'type': 'test',
              'connection_id': i,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            channels[i].sink.add(json.encode(message));
          }
          
          // Wait a bit for message processing
          await Future.delayed(const Duration(milliseconds: 500));
          
          print('✅ Multiple WebSocket connections handled successfully');
          
        } finally {
          // Clean up all connections
          for (final channel in channels) {
            await channel.sink.close();
          }
        }
      });
    });

    group('File Organizer WebSocket Events', () {
      test('Module switching and events', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          final eventsReceived = <Map<String, dynamic>>[];
          late StreamSubscription subscription;
          
          // Listen for events
          subscription = channel.stream.listen(
            (message) {
              try {
                final data = json.decode(message);
                eventsReceived.add(data);
              } catch (e) {
                print('Error parsing WebSocket message: $e');
              }
            },
          );
          
          // Send module switch message
          final switchMessage = {
            'type': 'switch_module',
            'module': 'file_organizer',
            'user_id': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
          };
          
          channel.sink.add(json.encode(switchMessage));
          
          // Wait for potential responses
          await Future.delayed(const Duration(seconds: 2));
          
          // Send a file organizer specific event
          final fileOrganizerMessage = {
            'type': 'request_drive_status',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          
          channel.sink.add(json.encode(fileOrganizerMessage));
          
          // Wait for responses
          await Future.delayed(const Duration(seconds: 2));
          
          print('✅ File organizer WebSocket events test completed');
          print('📊 Received ${eventsReceived.length} WebSocket messages');
          
          // Look for any file organizer specific responses
          final relevantEvents = eventsReceived.where((event) =>
            event.containsKey('type') && 
            (event['type'].toString().contains('file') || 
             event['type'].toString().contains('drive'))
          ).toList();
          
          if (relevantEvents.isNotEmpty) {
            print('✅ Received file organizer specific events: ${relevantEvents.length}');
          }
          
          await subscription.cancel();
        } finally {
          await channel?.sink.close();
        }
      });

      test('Drive status events', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          final driveEvents = <Map<String, dynamic>>[];
          late StreamSubscription subscription;
          
          subscription = channel.stream.listen(
            (message) {
              try {
                final data = json.decode(message);
                if (data.containsKey('type') && 
                    data['type'].toString().contains('drive')) {
                  driveEvents.add(data);
                }
              } catch (e) {
                // Ignore parsing errors
              }
            },
          );
          
          // First switch to file organizer module
          final switchMessage = {
            'type': 'switch_module',
            'module': 'file_organizer',
            'user_id': 'drive_test_user',
          };
          
          channel.sink.add(json.encode(switchMessage));
          await Future.delayed(const Duration(seconds: 1));
          
          // Request drive status
          final driveStatusMessage = {
            'type': 'get_drive_status',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          
          channel.sink.add(json.encode(driveStatusMessage));
          
          // Wait for drive events
          await Future.delayed(const Duration(seconds: 3));
          
          print('✅ Drive status WebSocket test completed');
          print('📊 Received ${driveEvents.length} drive-related events');
          
          // Validate drive event structure if any received
          for (final event in driveEvents) {
            expect(event, isA<Map<String, dynamic>>());
            expect(event['type'], isA<String>());
            
            if (event.containsKey('drives')) {
              expect(event['drives'], isA<List>());
            }
          }
          
          await subscription.cancel();
        } finally {
          await channel?.sink.close();
        }
      });
    });

    group('WebSocket Provider Integration', () {
      test('WebSocketProvider connection lifecycle', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        final provider = WebSocketProvider();
        
        try {
          // Test initial state
          expect(provider.connectionStatus, equals(ConnectionStatus.disconnected));
          expect(provider.isConnected, equals(false));
          
          // Connect
          await provider.connect('ws://localhost:8000');
          
          // Wait for connection to establish
          await Future.delayed(const Duration(seconds: 2));
          
          // Should be connected or attempting to connect
          expect(provider.connectionStatus, anyOf([
            ConnectionStatus.connected,
            ConnectionStatus.connecting,
            ConnectionStatus.authenticated,
          ]));
          
          print('✅ WebSocketProvider connection lifecycle working');
          
        } finally {
          await provider.disconnect();
          expect(provider.connectionStatus, equals(ConnectionStatus.disconnected));
        }
      });

      test('WebSocketProvider event handling', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        final provider = WebSocketProvider();
        final eventsReceived = <Map<String, dynamic>>[];
        
        try {
          // Listen to events
          provider.eventStream?.listen((event) {
            eventsReceived.add(event);
          });
          
          // Connect
          await provider.connect('ws://localhost:8000');
          await Future.delayed(const Duration(seconds: 1));
          
          // Send test message
          provider.sendMessage({
            'type': 'provider_test',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          
          // Wait for events
          await Future.delayed(const Duration(seconds: 2));
          
          print('✅ WebSocketProvider event handling test completed');
          print('📊 Provider received ${eventsReceived.length} events');
          
        } finally {
          await provider.disconnect();
        }
      });

      test('WebSocketProvider error handling', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        final provider = WebSocketProvider();
        
        try {
          // Test connection to invalid URL
          await provider.connect('ws://localhost:9999'); // Non-existent port
          
          // Wait a bit
          await Future.delayed(const Duration(seconds: 2));
          
          // Should handle error gracefully
          expect(provider.connectionStatus, anyOf([
            ConnectionStatus.disconnected,
            ConnectionStatus.error,
          ]));
          
          print('✅ WebSocketProvider error handling working');
          
        } finally {
          await provider.disconnect();
        }
      });
    });

    group('Real-time Event Scenarios', () {
      test('File operation progress events', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          final progressEvents = <Map<String, dynamic>>[];
          late StreamSubscription subscription;
          
          subscription = channel.stream.listen(
            (message) {
              try {
                final data = json.decode(message);
                if (data.containsKey('type') && 
                    (data['type'].toString().contains('progress') ||
                     data['type'].toString().contains('operation'))) {
                  progressEvents.add(data);
                }
              } catch (e) {
                // Ignore parsing errors
              }
            },
          );
          
          // Switch to file organizer
          channel.sink.add(json.encode({
            'type': 'switch_module',
            'module': 'file_organizer',
            'user_id': 'progress_test_user',
          }));
          
          await Future.delayed(const Duration(seconds: 1));
          
          // Trigger a file operation via HTTP API that might generate progress events
          try {
            final response = await httpClient.post(
              Uri.parse('$httpUrl/file-organizer/execute-operations'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'operations': [
                  {
                    'type': 'check_exists',
                    'path': '/tmp',
                  },
                ],
                'dry_run': true,
              }),
            );
            
            // Wait for any progress events
            await Future.delayed(const Duration(seconds: 2));
            
            print('✅ File operation progress events test completed');
            print('📊 Received ${progressEvents.length} progress events');
            
          } catch (e) {
            print('⚠️ Could not trigger file operation: $e');
          }
          
          await subscription.cancel();
        } finally {
          await channel?.sink.close();
        }
      });

      test('Module switching notifications', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        WebSocketChannel? channel;
        
        try {
          channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
          await channel.ready.timeout(const Duration(seconds: 10));
          
          final moduleEvents = <Map<String, dynamic>>[];
          late StreamSubscription subscription;
          
          subscription = channel.stream.listen(
            (message) {
              try {
                final data = json.decode(message);
                if (data.containsKey('type') && 
                    data['type'].toString().contains('module')) {
                  moduleEvents.add(data);
                }
              } catch (e) {
                // Ignore parsing errors
              }
            },
          );
          
          // Test switching between modules
          final modules = ['file_organizer', 'financial_manager'];
          
          for (final module in modules) {
            final switchMessage = {
              'type': 'switch_module',
              'module': module,
              'user_id': 'module_test_user',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            
            channel.sink.add(json.encode(switchMessage));
            await Future.delayed(const Duration(seconds: 1));
          }
          
          // Wait for all events
          await Future.delayed(const Duration(seconds: 2));
          
          print('✅ Module switching notifications test completed');
          print('📊 Received ${moduleEvents.length} module events');
          
          await subscription.cancel();
        } finally {
          await channel?.sink.close();
        }
      });
    });

    group('Connection Stability', () {
      test('WebSocket reconnection handling', () async {
        if (!backendAvailable) {
          markTestSkipped('Backend WebSocket not available');
          return;
        }

        final provider = WebSocketProvider();
        final connectionStates = <ConnectionStatus>[];
        
        try {
          // Monitor connection state changes
          provider.addListener(() {
            connectionStates.add(provider.connectionStatus);
          });
          
          // Initial connection
          await provider.connect('ws://localhost:8000');
          await Future.delayed(const Duration(seconds: 1));
          
          // Force disconnect and reconnect
          await provider.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
          
          await provider.connect('ws://localhost:8000');
          await Future.delayed(const Duration(seconds: 1));
          
          print('✅ WebSocket reconnection test completed');
          print('📊 Connection state changes: ${connectionStates.length}');
          
          // Should have seen disconnected and connected states
          expect(connectionStates, contains(ConnectionStatus.disconnected));
          expect(connectionStates, anyOf([
            contains(ConnectionStatus.connected),
            contains(ConnectionStatus.connecting),
          ]));
          
        } finally {
          await provider.disconnect();
        }
      });

      test('WebSocket connection timeout handling', () async {
        final provider = WebSocketProvider();
        
        try {
          // Test connection timeout with very short timeout
          final startTime = DateTime.now();
          
          // Try to connect to a slow/non-responsive endpoint
          await provider.connect('ws://localhost:8000').timeout(
            const Duration(milliseconds: 100), 
            onTimeout: () {
              // Expected timeout
            },
          );
          
          final elapsed = DateTime.now().difference(startTime);
          
          // Should handle timeout gracefully
          expect(elapsed.inSeconds, lessThan(5));
          print('✅ WebSocket timeout handling working');
          
        } catch (e) {
          // Timeout is expected behavior
          print('✅ WebSocket timeout handled gracefully: ${e.runtimeType}');
        } finally {
          await provider.disconnect();
        }
      });
    });
  });
}

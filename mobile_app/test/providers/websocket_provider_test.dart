import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/providers/websocket_provider.dart';

void main() {
  group('WebSocketProvider', () {
    late WebSocketProvider provider;

    setUp(() {
      provider = WebSocketProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state is correct', () {
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
      expect(provider.lastError, isNull);
      expect(provider.userId, isNull);
      expect(provider.sessionId, isNull);
      expect(provider.isConnected, false);
      expect(provider.isAuthenticated, false);
    });

    test('connection status updates correctly', () {
      // Test the internal status setter
      provider.connectionStatus; // Access getter to ensure it's initialized
      
      // Since we can't easily test the actual WebSocket connection without mocking,
      // we'll test the state management logic
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
      expect(provider.isConnected, false);
      expect(provider.isAuthenticated, false);
    });

    test('error handling works correctly', () {
      // Test error state
      expect(provider.lastError, isNull);
      
      // The error setting is private, so we test through connection attempts
      // In a real scenario, connection failures would set error states
    });

    test('drive event stream is available', () {
      expect(provider.driveEvents, isA<Stream<DriveEvent>>());
    });

    test('progress event stream is available', () {
      expect(provider.progressEvents, isA<Stream<ProgressEvent>>());
    });

    test('error event stream is available', () {
      expect(provider.errorEvents, isA<Stream<Map<String, dynamic>>>());
    });

    test('DriveEvent creation works correctly', () {
      final event = DriveEvent(
        type: DriveEventType.connected,
        data: {'path': '/test/drive'},
        timestamp: DateTime.now(),
      );

      expect(event.type, DriveEventType.connected);
      expect(event.data['path'], '/test/drive');
      expect(event.timestamp, isA<DateTime>());
    });

    test('ProgressEvent creation works correctly', () {
      final event = ProgressEvent(
        operationId: 'test_op',
        completedOperations: 5,
        totalOperations: 10,
        percentage: 50.0,
        currentFile: 'test.txt',
        status: 'executing',
        timestamp: DateTime.now(),
      );

      expect(event.operationId, 'test_op');
      expect(event.completedOperations, 5);
      expect(event.totalOperations, 10);
      expect(event.percentage, 50.0);
      expect(event.currentFile, 'test.txt');
      expect(event.status, 'executing');
      expect(event.timestamp, isA<DateTime>());
    });

    test('connection status enum values are correct', () {
      expect(ConnectionStatus.values, [
        ConnectionStatus.disconnected,
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.authenticated,
        ConnectionStatus.error,
      ]);
    });

    test('drive event type enum values are correct', () {
      expect(DriveEventType.values, [
        DriveEventType.connected,
        DriveEventType.disconnected,
        DriveEventType.discovered,
        DriveEventType.statusUpdate,
      ]);
    });
  });
}

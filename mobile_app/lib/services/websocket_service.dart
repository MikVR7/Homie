import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _connected = false;
  bool _authenticated = false;
  String? _userId;
  String? _sessionId;
  String _currentModule = 'main_menu';

  // Stream controllers for real-time events
  final StreamController<Map<String, dynamic>> _driveEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _connectionEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _moduleEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get driveEvents => _driveEventsController.stream;
  Stream<Map<String, dynamic>> get connectionEvents => _connectionEventsController.stream;
  Stream<Map<String, dynamic>> get moduleEvents => _moduleEventsController.stream;

  // Getters
  bool get isConnected => _connected;
  bool get isAuthenticated => _authenticated;
  String? get userId => _userId;
  String? get sessionId => _sessionId;
  String get currentModule => _currentModule;

  Future<bool> connect({
    String serverUrl = 'http://localhost:8000',
    String? userId,
  }) async {
    try {
      if (_socket != null) {
        await disconnect();
      }

      _socket = IO.io(serverUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .setTimeout(5000)
          .build());

      final completer = Completer<bool>();

      _socket!.onConnect((_) {
        _connected = true;
        _connectionEventsController.add({
          'type': 'connected',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('✅ WebSocket connected to $serverUrl');
        }

        // Auto-authenticate if userId provided
        if (userId != null) {
          authenticate(userId);
        }
        
        completer.complete(true);
      });

      _socket!.onDisconnect((reason) {
        _connected = false;
        _authenticated = false;
        _connectionEventsController.add({
          'type': 'disconnected',
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('❌ WebSocket disconnected: $reason');
        }
      });

      _socket!.onConnectError((error) {
        _connectionEventsController.add({
          'type': 'connect_error',
          'error': error.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('❌ WebSocket connection error: $error');
        }
        
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      _setupEventListeners();
      _socket!.connect();

      return await completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket connection failed: $e');
      }
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _connected = false;
    _authenticated = false;
    _userId = null;
    _sessionId = null;
    _currentModule = 'main_menu';
  }

  Future<bool> authenticate(String userId) async {
    if (!_connected || _socket == null) {
      if (kDebugMode) {
        print('❌ Cannot authenticate: not connected');
      }
      return false;
    }

    final completer = Completer<bool>();

    _socket!.once('auth_response', (data) {
      if (data['success'] == true) {
        _authenticated = true;
        _userId = data['user_id'];
        _sessionId = data['session_id'];
        
        _connectionEventsController.add({
          'type': 'authenticated',
          'user_id': _userId,
          'session_id': _sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('✅ Authenticated as: $_userId');
        }
        
        completer.complete(true);
      } else {
        if (kDebugMode) {
          print('❌ Authentication failed: ${data['error']}');
        }
        completer.complete(false);
      }
    });

    _socket!.emit('authenticate', {
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'client_type': 'flutter_app',
    });

    return await completer.future;
  }

  Future<bool> switchModule(String moduleName) async {
    if (!_authenticated || _socket == null) {
      if (kDebugMode) {
        print('❌ Cannot switch module: not authenticated');
      }
      return false;
    }

    final completer = Completer<bool>();

    _socket!.once('module_switch_response', (data) {
      if (data['success'] == true) {
        _currentModule = data['new_module'];
        
        _moduleEventsController.add({
          'type': 'module_switched',
          'new_module': _currentModule,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('✅ Switched to module: $_currentModule');
        }
        
        completer.complete(true);
      } else {
        if (kDebugMode) {
          print('❌ Module switch failed: ${data['error']}');
        }
        completer.complete(false);
      }
    });

    _socket!.emit('switch_module', {'module': moduleName});

    return await completer.future;
  }

  void requestDriveStatus() {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('request_drive_status', {});
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Drive-related events
    final driveEvents = [
      'file_organizer_drive_status',
      'drive_connected',
      'drive_disconnected',
      'drive_discovered',
      'drive_status',
    ];

    for (final eventType in driveEvents) {
      _socket!.on(eventType, (data) {
        _driveEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('📱 Drive event: $eventType');
        }
      });
    }

    // Module events
    final moduleEvents = [
      'file_organizer_user_joining',
      'file_organizer_user_leaving',
      'financial_manager_user_joining',
      'financial_manager_user_leaving',
    ];

    for (final eventType in moduleEvents) {
      _socket!.on(eventType, (data) {
        _moduleEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('📱 Module event: $eventType');
        }
      });
    }

    // General backend events
    final backendEvents = [
      'client_connected',
      'client_disconnected',
      'user_authenticated',
      'module_switched',
      'ai_response',
      'error',
    ];

    for (final eventType in backendEvents) {
      _socket!.on(eventType, (data) {
        _connectionEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('📱 Backend event: $eventType');
        }
      });
    }

    // Catch-all for unknown events
    _socket!.onAny((eventName, data) {
      final knownEvents = [
        ...driveEvents,
        ...moduleEvents,
        ...backendEvents,
        'connect',
        'disconnect',
        'connect_error',
        'auth_response',
        'module_switch_response',
      ];

      if (!knownEvents.contains(eventName)) {
        if (kDebugMode) {
          print('📱 Unknown event: $eventName with data: $data');
        }
        
        _connectionEventsController.add({
          'type': 'unknown_event',
          'event_name': eventName,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void dispose() {
    _driveEventsController.close();
    _connectionEventsController.close();
    _moduleEventsController.close();
    disconnect();
  }

  // ========================================
  // TASK 3.2: ENHANCED WEBSOCKET INTEGRATION
  // ========================================

  // Additional stream controllers for enhanced real-time features
  final StreamController<Map<String, dynamic>> _progressEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  // Enhanced public streams
  Stream<Map<String, dynamic>> get progressEvents => _progressEventsController.stream;
  Stream<Map<String, dynamic>> get errorEvents => _errorEventsController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  // Connection status management
  String _connectionStatus = 'disconnected';
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration baseReconnectDelay = Duration(seconds: 2);

  String get connectionStatus => _connectionStatus;

  // Enhanced connection with retry logic and status management
  Future<bool> connectWithRetry({
    String serverUrl = 'http://localhost:8000',
    String? userId,
    bool autoReconnect = true,
  }) async {
    _updateConnectionStatus('connecting');
    
    for (int attempt = 0; attempt < maxReconnectAttempts; attempt++) {
      try {
        final success = await connect(serverUrl: serverUrl, userId: userId);
        if (success) {
          _reconnectAttempts = 0;
          if (autoReconnect) {
            _startHeartbeat();
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Connection attempt ${attempt + 1} failed: $e');
        }
      }

      if (attempt < maxReconnectAttempts - 1) {
        final delay = Duration(seconds: baseReconnectDelay.inSeconds * (attempt + 1));
        if (kDebugMode) {
          print('⏱️ Retrying connection in ${delay.inSeconds} seconds...');
        }
        await Future.delayed(delay);
      }
    }

    _updateConnectionStatus('failed');
    return false;
  }

  // Auto-reconnect functionality
  void enableAutoReconnect({
    String serverUrl = 'http://localhost:8000',
    String? userId,
  }) {
    _socket?.onDisconnect((reason) {
      _connected = false;
      _authenticated = false;
      _updateConnectionStatus('disconnected');
      
      if (kDebugMode) {
        print('❌ WebSocket disconnected: $reason');
      }

      // Start reconnection attempts
      if (_reconnectAttempts < maxReconnectAttempts) {
        _scheduleReconnect(serverUrl: serverUrl, userId: userId);
      } else {
        _updateConnectionStatus('failed');
        if (kDebugMode) {
          print('❌ Max reconnection attempts reached');
        }
      }
    });
  }

  void _scheduleReconnect({
    String serverUrl = 'http://localhost:8000',
    String? userId,
  }) {
    _reconnectAttempts++;
    final delay = Duration(seconds: baseReconnectDelay.inSeconds * _reconnectAttempts);
    
    _updateConnectionStatus('reconnecting');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (kDebugMode) {
        print('🔄 Attempting to reconnect (attempt $_reconnectAttempts)...');
      }
      
      final success = await connect(serverUrl: serverUrl, userId: userId);
      if (success && userId != null) {
        await authenticate(userId);
      }
    });
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  // Heartbeat mechanism to detect connection issues
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connected && _socket != null) {
        _socket!.emit('heartbeat', {
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Enhanced disconnect with cleanup
  Future<void> disconnectEnhanced() async {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _connected = false;
    _authenticated = false;
    _userId = null;
    _sessionId = null;
    _currentModule = 'main_menu';
    _updateConnectionStatus('disconnected');
  }

  // Subscribe to operation progress updates
  void subscribeToOperationProgress(String operationId) {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('subscribe_operation_progress', {
      'operation_id': operationId,
    });

    if (kDebugMode) {
      print('📊 Subscribed to operation progress: $operationId');
    }
  }

  // Unsubscribe from operation progress updates
  void unsubscribeFromOperationProgress(String operationId) {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('unsubscribe_operation_progress', {
      'operation_id': operationId,
    });

    if (kDebugMode) {
      print('📊 Unsubscribed from operation progress: $operationId');
    }
  }

  // Request real-time drive updates
  void subscribeToRealTimeDriveUpdates() {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('subscribe_drive_updates', {});

    if (kDebugMode) {
      print('💾 Subscribed to real-time drive updates');
    }
  }

  void unsubscribeFromRealTimeDriveUpdates() {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('unsubscribe_drive_updates', {});

    if (kDebugMode) {
      print('💾 Unsubscribed from real-time drive updates');
    }
  }

  // Send operation control commands
  void sendOperationCommand({
    required String operationId,
    required String command, // 'pause', 'resume', 'cancel'
  }) {
    if (!_connected || _socket == null) return;
    
    _socket!.emit('operation_command', {
      'operation_id': operationId,
      'command': command,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) {
      print('🎮 Sent operation command: $command for $operationId');
    }
  }

  // Enhanced event listeners setup
  void _setupEnhancedEventListeners() {
    if (_socket == null) return;

    // Enhanced drive-related events
    final driveEvents = [
      'file_organizer_drive_status',
      'drive_connected',
      'drive_disconnected',
      'drive_discovered',
      'drive_status',
      'drive_health_update',
      'drive_space_warning',
    ];

    for (final eventType in driveEvents) {
      _socket!.on(eventType, (data) {
        _driveEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('💾 Drive event: $eventType');
        }
      });
    }

    // Operation progress events
    final progressEvents = [
      'operation_progress',
      'operation_started',
      'operation_completed',
      'operation_paused',
      'operation_resumed',
      'operation_cancelled',
      'operation_error',
    ];

    for (final eventType in progressEvents) {
      _socket!.on(eventType, (data) {
        _progressEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('📊 Progress event: $eventType');
        }
      });
    }

    // Error handling events
    final errorEvents = [
      'api_error',
      'connection_error',
      'operation_error',
      'permission_error',
      'disk_error',
    ];

    for (final eventType in errorEvents) {
      _socket!.on(eventType, (data) {
        _errorEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('❌ Error event: $eventType');
        }
      });
    }

    // Module events
    final moduleEvents = [
      'file_organizer_user_joining',
      'file_organizer_user_leaving',
      'financial_manager_user_joining',
      'financial_manager_user_leaving',
      'module_status_update',
    ];

    for (final eventType in moduleEvents) {
      _socket!.on(eventType, (data) {
        _moduleEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('📱 Module event: $eventType');
        }
      });
    }

    // Connection management events
    final connectionEvents = [
      'client_connected',
      'client_disconnected',
      'user_authenticated',
      'module_switched',
      'ai_response',
      'heartbeat_response',
      'error',
    ];

    for (final eventType in connectionEvents) {
      _socket!.on(eventType, (data) {
        _connectionEventsController.add({
          'type': eventType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (kDebugMode) {
          print('🌐 Connection event: $eventType');
        }
      });
    }

    // Handle heartbeat responses
    _socket!.on('heartbeat_response', (data) {
      if (kDebugMode) {
        print('💓 Heartbeat response received');
      }
    });

    // Enhanced error handling
    _socket!.on('error', (error) {
      _errorEventsController.add({
        'type': 'socket_error',
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('❌ Socket error: $error');
      }
    });

    // Catch-all for unknown events with enhanced logging
    _socket!.onAny((eventName, data) {
      final knownEvents = [
        ...driveEvents,
        ...progressEvents,
        ...errorEvents,
        ...moduleEvents,
        ...connectionEvents,
        'connect',
        'disconnect',
        'connect_error',
        'auth_response',
        'module_switch_response',
      ];

      if (!knownEvents.contains(eventName)) {
        if (kDebugMode) {
          print('📡 Unknown event: $eventName with data: $data');
        }
        
        _connectionEventsController.add({
          'type': 'unknown_event',
          'event_name': eventName,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // Get current connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'is_connected': _connected,
      'is_authenticated': _authenticated,
      'user_id': _userId,
      'session_id': _sessionId,
      'current_module': _currentModule,
      'connection_status': _connectionStatus,
      'reconnect_attempts': _reconnectAttempts,
      'max_reconnect_attempts': maxReconnectAttempts,
    };
  }

  // Enhanced dispose with proper cleanup
  void disposeEnhanced() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    
    _driveEventsController.close();
    _connectionEventsController.close();
    _moduleEventsController.close();
    _progressEventsController.close();
    _errorEventsController.close();
    _connectionStatusController.close();
    
    disconnect();
  }
}


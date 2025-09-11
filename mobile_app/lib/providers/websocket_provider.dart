import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:homie_app/services/websocket_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, authenticated, error }

enum DriveEventType { connected, disconnected, discovered, statusUpdate }

class DriveEvent {
  final DriveEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  DriveEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class ProgressEvent {
  final String operationId;
  final int completedOperations;
  final int totalOperations;
  final double percentage;
  final String currentFile;
  final String status;
  final DateTime timestamp;

  ProgressEvent({
    required this.operationId,
    required this.completedOperations,
    required this.totalOperations,
    required this.percentage,
    required this.currentFile,
    required this.status,
    required this.timestamp,
  });
}

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  
  // Connection state
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _lastError;
  String? _userId;
  String? _sessionId;
  
  // Real-time events
  final StreamController<DriveEvent> _driveEventsController = 
      StreamController<DriveEvent>.broadcast();
  final StreamController<ProgressEvent> _progressEventsController = 
      StreamController<ProgressEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _errorEventsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Subscriptions
  StreamSubscription? _driveEventsSubscription;
  StreamSubscription? _connectionEventsSubscription;
  StreamSubscription? _moduleEventsSubscription;
  
  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get lastError => _lastError;
  String? get userId => _userId;
  String? get sessionId => _sessionId;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected || 
                         _connectionStatus == ConnectionStatus.authenticated;
  bool get isAuthenticated => _connectionStatus == ConnectionStatus.authenticated;
  
  // Streams
  Stream<DriveEvent> get driveEvents => _driveEventsController.stream;
  Stream<ProgressEvent> get progressEvents => _progressEventsController.stream;
  Stream<Map<String, dynamic>> get errorEvents => _errorEventsController.stream;
  
  // Task 3.2: Enhanced real-time features
  final StreamController<Map<String, dynamic>> _driveStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _systemStatusController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get driveStatusUpdates => _driveStatusController.stream;
  Stream<Map<String, dynamic>> get systemStatusUpdates => _systemStatusController.stream;
  
  // Connection management
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  
  WebSocketProvider() {
    _setupEventListeners();
  }
  
  /// Connect to WebSocket server
  Future<bool> connect({
    String serverUrl = 'http://localhost:8000',
    String? userId,
  }) async {
    if (_connectionStatus == ConnectionStatus.connecting) {
      return false; // Already connecting
    }
    
    _setConnectionStatus(ConnectionStatus.connecting);
    _clearError();
    
    try {
      final success = await _wsService.connect(
        serverUrl: serverUrl,
        userId: userId,
      );
      
      if (success) {
        _setConnectionStatus(ConnectionStatus.connected);
        _userId = userId;
        
        // Auto-authenticate if userId provided
        if (userId != null) {
          await authenticate(userId);
        }
        
        return true;
      } else {
        _setConnectionStatus(ConnectionStatus.error);
        _setError('Failed to connect to WebSocket server');
        return false;
      }
    } catch (e) {
      _setConnectionStatus(ConnectionStatus.error);
      _setError('Connection error: ${e.toString()}');
      return false;
    }
  }
  
  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    await _wsService.disconnect();
    _setConnectionStatus(ConnectionStatus.disconnected);
    _userId = null;
    _sessionId = null;
    _clearError();
  }
  
  /// Authenticate with the server
  Future<bool> authenticate(String userId) async {
    if (_connectionStatus != ConnectionStatus.connected) {
      _setError('Cannot authenticate: not connected');
      return false;
    }
    
    try {
      final success = await _wsService.authenticate(userId);
      
      if (success) {
        _setConnectionStatus(ConnectionStatus.authenticated);
        _userId = userId;
        _sessionId = _wsService.sessionId;
        return true;
      } else {
        _setError('Authentication failed');
        return false;
      }
    } catch (e) {
      _setError('Authentication error: ${e.toString()}');
      return false;
    }
  }
  
  /// Switch to a specific module
  Future<bool> switchModule(String moduleName) async {
    if (!isAuthenticated) {
      _setError('Cannot switch module: not authenticated');
      return false;
    }
    
    try {
      return await _wsService.switchModule(moduleName);
    } catch (e) {
      _setError('Module switch error: ${e.toString()}');
      return false;
    }
  }
  
  /// Request drive status update
  void requestDriveStatus() {
    if (isConnected) {
      _wsService.requestDriveStatus();
    }
  }
  
  /// Setup event listeners for WebSocket events
  void _setupEventListeners() {
    // Listen to drive events
    _driveEventsSubscription = _wsService.driveEvents.listen((event) {
      final eventType = _mapDriveEventType(event['type']);
      if (eventType != null) {
        final driveEvent = DriveEvent(
          type: eventType,
          data: event['data'] ?? {},
          timestamp: DateTime.tryParse(event['timestamp']) ?? DateTime.now(),
        );
        _driveEventsController.add(driveEvent);
      }
    });
    
    // Listen to connection events
    _connectionEventsSubscription = _wsService.connectionEvents.listen((event) {
      _handleConnectionEvent(event);
    });
    
    // Listen to module events
    _moduleEventsSubscription = _wsService.moduleEvents.listen((event) {
      _handleModuleEvent(event);
    });
  }
  
  /// Handle connection events
  void _handleConnectionEvent(Map<String, dynamic> event) {
    final type = event['type'];
    
    switch (type) {
      case 'connected':
        _setConnectionStatus(ConnectionStatus.connected);
        break;
      case 'disconnected':
        _setConnectionStatus(ConnectionStatus.disconnected);
        _userId = null;
        _sessionId = null;
        break;
      case 'authenticated':
        _setConnectionStatus(ConnectionStatus.authenticated);
        _userId = event['user_id'];
        _sessionId = event['session_id'];
        break;
      case 'connect_error':
        _setConnectionStatus(ConnectionStatus.error);
        _setError(event['error']?.toString() ?? 'Connection error');
        break;
      case 'error':
        _errorEventsController.add(event);
        break;
    }
  }
  
  /// Handle module events
  void _handleModuleEvent(Map<String, dynamic> event) {
    // Module events can be used for inter-module communication
    // For now, just log them in debug mode
    if (kDebugMode) {
      print('Module event: ${event['type']}');
    }
  }
  
  /// Map string event types to DriveEventType enum
  DriveEventType? _mapDriveEventType(String? eventType) {
    switch (eventType) {
      case 'drive_connected':
        return DriveEventType.connected;
      case 'drive_disconnected':
        return DriveEventType.disconnected;
      case 'drive_discovered':
        return DriveEventType.discovered;
      case 'drive_status':
      case 'file_organizer_drive_status':
        return DriveEventType.statusUpdate;
      default:
        return null;
    }
  }
  
  /// Set connection status and notify listeners
  void _setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      notifyListeners();
    }
  }
  
  /// Set error message and notify listeners
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }
  
  // Task 3.2: Enhanced connection management with retry logic
  Future<void> connectWithRetry() async {
    if (_connectionStatus == ConnectionStatus.connecting) return;
    
    _reconnectAttempts = 0;
    await _attemptConnection();
  }
  
  Future<void> _attemptConnection() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setConnectionStatus(ConnectionStatus.error);
      _lastError = 'Maximum reconnection attempts reached';
      notifyListeners();
      return;
    }
    
    try {
      _setConnectionStatus(ConnectionStatus.connecting);
      await connect();
      _reconnectAttempts = 0; // Reset on successful connection
    } catch (e) {
      _reconnectAttempts++;
      _lastError = e.toString();
      
      if (_reconnectAttempts < _maxReconnectAttempts) {
        final delay = _baseReconnectDelay * _reconnectAttempts;
        _reconnectTimer = Timer(delay, () => _attemptConnection());
      } else {
        _setConnectionStatus(ConnectionStatus.error);
      }
      notifyListeners();
    }
  }
  
  /// Enhanced event handling for drive status updates
  void _handleDriveStatusUpdate(Map<String, dynamic> data) {
    _driveStatusController.add(data);
    
    // Also emit as DriveEvent for backward compatibility
    final eventType = DriveEventType.statusUpdate;
    final driveEvent = DriveEvent(
      type: eventType,
      data: data,
      timestamp: DateTime.now(),
    );
    _driveEventsController.add(driveEvent);
  }
  
  /// Enhanced system status monitoring
  void _handleSystemStatusUpdate(Map<String, dynamic> data) {
    _systemStatusController.add(data);
    notifyListeners();
  }
  
  /// Operation progress streaming with enhanced details
  void _handleOperationProgress(Map<String, dynamic> data) {
    final progressEvent = ProgressEvent(
      operationId: data['operation_id'] ?? '',
      completedOperations: data['completed_operations'] ?? 0,
      totalOperations: data['total_operations'] ?? 0,
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      currentFile: data['current_file'] ?? '',
      status: data['status'] ?? '',
      timestamp: DateTime.now(),
    );
    _progressEventsController.add(progressEvent);
  }
  
  /// Handle WebSocket disconnections with automatic retry
  void _handleDisconnection() {
    if (_connectionStatus != ConnectionStatus.disconnected) {
      _setConnectionStatus(ConnectionStatus.disconnected);
      
      // Attempt automatic reconnection if not manually disconnected
      if (_reconnectAttempts < _maxReconnectAttempts) {
        Timer(const Duration(seconds: 1), () => _attemptConnection());
      }
    }
  }
  
  /// Cancel any pending reconnection attempts
  void cancelReconnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _driveEventsSubscription?.cancel();
    _connectionEventsSubscription?.cancel();
    _moduleEventsSubscription?.cancel();
    
    _driveEventsController.close();
    _progressEventsController.close();
    _errorEventsController.close();
    _driveStatusController.close();
    _systemStatusController.close();
    
    _wsService.dispose();
    super.dispose();
  }
}

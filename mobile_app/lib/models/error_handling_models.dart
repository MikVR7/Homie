import 'package:flutter/foundation.dart';

/// Enhanced error handling models for file organizer
/// Task 5.2: Comprehensive error handling with user-friendly messages and recovery

// ====================================
// ERROR HANDLING ENUMS
// ====================================

enum FileOrganizerErrorType {
  // File system errors
  fileNotFound,
  fileAccessDenied,
  fileLocked,
  fileCorrupted,
  fileTooBig,
  pathTooLong,
  diskSpaceInsufficient,
  driveNotAvailable,
  invalidPath,
  
  // Network and connectivity errors
  networkTimeout,
  connectionLost,
  serverUnavailable,
  authenticationFailed,
  apiRateLimited,
  
  // Operation errors
  operationCancelled,
  operationTimedOut,
  operationConflict,
  dependencyFailed,
  validationFailed,
  
  // System errors
  memoryInsufficient,
  systemResourceUnavailable,
  platformNotSupported,
  configurationError,
  
  // User errors
  invalidInput,
  missingRequiredField,
  formatNotSupported,
  permissionDenied,
  
  // AI and analysis errors
  analysisTimeout,
  modelUnavailable,
  processingFailed,
  confidenceTooLow,
  
  // Unknown and internal errors
  internalError,
  unexpectedError,
  unknown
}

enum ErrorSeverity {
  info,      // Informational, user can continue
  warning,   // Warning, operation might not work optimally
  error,     // Error, operation failed but system is stable
  critical,  // Critical, operation failed and may affect other operations
  fatal      // Fatal, system may become unstable
}

enum RecoveryStrategy {
  none,           // No recovery possible
  retry,          // Simple retry
  retryWithDelay, // Retry after delay
  userIntervention, // Requires user action
  alternative,    // Use alternative method
  skipAndContinue, // Skip this operation and continue
  rollback,       // Undo previous operations
  restart         // Restart the entire process
}

// ====================================
// ERROR CONTEXT AND METADATA
// ====================================

/// Context information for error occurrence
class ErrorContext {
  final String operationId;
  final String? sessionId;
  final String operationType;
  final String? filePath;
  final String? targetPath;
  final Map<String, dynamic> operationParameters;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> systemInfo;
  final Map<String, dynamic> environmentInfo;

  const ErrorContext({
    required this.operationId,
    this.sessionId,
    required this.operationType,
    this.filePath,
    this.targetPath,
    this.operationParameters = const {},
    required this.timestamp,
    this.userId,
    this.systemInfo = const {},
    this.environmentInfo = const {},
  });

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'session_id': sessionId,
    'operation_type': operationType,
    'file_path': filePath,
    'target_path': targetPath,
    'operation_parameters': operationParameters,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'system_info': systemInfo,
    'environment_info': environmentInfo,
  };

  factory ErrorContext.fromJson(Map<String, dynamic> json) {
    return ErrorContext(
      operationId: json['operation_id'] ?? '',
      sessionId: json['session_id'],
      operationType: json['operation_type'] ?? '',
      filePath: json['file_path'],
      targetPath: json['target_path'],
      operationParameters: Map<String, dynamic>.from(json['operation_parameters'] ?? {}),
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
      userId: json['user_id'],
      systemInfo: Map<String, dynamic>.from(json['system_info'] ?? {}),
      environmentInfo: Map<String, dynamic>.from(json['environment_info'] ?? {}),
    );
  }
}

/// Recovery action that can be taken for an error
class RecoveryAction {
  final String id;
  final String title;
  final String description;
  final RecoveryStrategy strategy;
  final Map<String, dynamic> parameters;
  final bool requiresUserConfirmation;
  final bool isRecommended;
  final Duration? estimatedTime;
  final double successProbability; // 0.0 - 1.0

  const RecoveryAction({
    required this.id,
    required this.title,
    required this.description,
    required this.strategy,
    this.parameters = const {},
    this.requiresUserConfirmation = false,
    this.isRecommended = false,
    this.estimatedTime,
    required this.successProbability,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'strategy': strategy.toString(),
    'parameters': parameters,
    'requires_user_confirmation': requiresUserConfirmation,
    'is_recommended': isRecommended,
    'estimated_time': estimatedTime?.inSeconds,
    'success_probability': successProbability,
  };

  factory RecoveryAction.fromJson(Map<String, dynamic> json) {
    return RecoveryAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      strategy: RecoveryStrategy.values.firstWhere(
        (e) => e.toString() == json['strategy'],
        orElse: () => RecoveryStrategy.none,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      requiresUserConfirmation: json['requires_user_confirmation'] ?? false,
      isRecommended: json['is_recommended'] ?? false,
      estimatedTime: json['estimated_time'] != null 
        ? Duration(seconds: json['estimated_time'])
        : null,
      successProbability: json['success_probability']?.toDouble() ?? 0.0,
    );
  }
}

// ====================================
// MAIN ERROR CLASS HIERARCHY
// ====================================

/// Base class for all file organizer errors
abstract class FileOrganizerError implements Exception {
  final String id;
  final FileOrganizerErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String technicalMessage;
  final String userFriendlyMessage;
  final ErrorContext context;
  final String? originalException;
  final String? stackTrace;
  final List<RecoveryAction> recoveryActions;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const FileOrganizerError({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.technicalMessage,
    required this.userFriendlyMessage,
    required this.context,
    this.originalException,
    this.stackTrace,
    this.recoveryActions = const [],
    this.metadata = const {},
    required this.timestamp,
  });

  /// Convert error to JSON for logging and reporting
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'severity': severity.toString(),
    'message': message,
    'technical_message': technicalMessage,
    'user_friendly_message': userFriendlyMessage,
    'context': context.toJson(),
    'original_exception': originalException,
    'stack_trace': stackTrace,
    'recovery_actions': recoveryActions.map((a) => a.toJson()).toList(),
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'error_class': runtimeType.toString(),
  };

  /// Get the most appropriate message for the user
  String getDisplayMessage() => userFriendlyMessage.isNotEmpty 
    ? userFriendlyMessage 
    : message;

  /// Get recommended recovery action
  RecoveryAction? get recommendedAction {
    try {
      return recoveryActions.firstWhere((action) => action.isRecommended);
    } catch (e) {
      return recoveryActions.isNotEmpty ? recoveryActions.first : null;
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable => recoveryActions.isNotEmpty;

  /// Check if error requires immediate attention
  bool get requiresImmediateAttention => 
    severity == ErrorSeverity.critical || severity == ErrorSeverity.fatal;

  @override
  String toString() => 'FileOrganizerError: $message';
}

// ====================================
// SPECIFIC ERROR IMPLEMENTATIONS
// ====================================

/// File system related errors
class FileSystemError extends FileOrganizerError {
  final String? affectedPath;
  final String? expectedPath;
  final int? errorCode;

  const FileSystemError({
    required super.id,
    required super.type,
    required super.severity,
    required super.message,
    required super.technicalMessage,
    required super.userFriendlyMessage,
    required super.context,
    super.originalException,
    super.stackTrace,
    super.recoveryActions,
    super.metadata,
    required super.timestamp,
    this.affectedPath,
    this.expectedPath,
    this.errorCode,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'affected_path': affectedPath,
      'expected_path': expectedPath,
      'error_code': errorCode,
    });
    return json;
  }
}

/// Network and connectivity errors
class NetworkError extends FileOrganizerError {
  final String? endpoint;
  final int? httpStatusCode;
  final Duration? timeout;
  final int retryCount;

  const NetworkError({
    required super.id,
    required super.type,
    required super.severity,
    required super.message,
    required super.technicalMessage,
    required super.userFriendlyMessage,
    required super.context,
    super.originalException,
    super.stackTrace,
    super.recoveryActions,
    super.metadata,
    required super.timestamp,
    this.endpoint,
    this.httpStatusCode,
    this.timeout,
    this.retryCount = 0,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'endpoint': endpoint,
      'http_status_code': httpStatusCode,
      'timeout': timeout?.inSeconds,
      'retry_count': retryCount,
    });
    return json;
  }
}

/// Operation specific errors
class OperationError extends FileOrganizerError {
  final String? dependentOperationId;
  final String? conflictingOperationId;
  final Map<String, dynamic> operationState;

  const OperationError({
    required super.id,
    required super.type,
    required super.severity,
    required super.message,
    required super.technicalMessage,
    required super.userFriendlyMessage,
    required super.context,
    super.originalException,
    super.stackTrace,
    super.recoveryActions,
    super.metadata,
    required super.timestamp,
    this.dependentOperationId,
    this.conflictingOperationId,
    this.operationState = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'dependent_operation_id': dependentOperationId,
      'conflicting_operation_id': conflictingOperationId,
      'operation_state': operationState,
    });
    return json;
  }
}

/// Validation and user input errors
class ValidationError extends FileOrganizerError {
  final String? fieldName;
  final dynamic providedValue;
  final dynamic expectedValue;
  final List<String> validationRules;

  const ValidationError({
    required super.id,
    required super.type,
    required super.severity,
    required super.message,
    required super.technicalMessage,
    required super.userFriendlyMessage,
    required super.context,
    super.originalException,
    super.stackTrace,
    super.recoveryActions,
    super.metadata,
    required super.timestamp,
    this.fieldName,
    this.providedValue,
    this.expectedValue,
    this.validationRules = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'field_name': fieldName,
      'provided_value': providedValue,
      'expected_value': expectedValue,
      'validation_rules': validationRules,
    });
    return json;
  }
}

/// AI and analysis errors
class AIAnalysisError extends FileOrganizerError {
  final String? modelName;
  final String? analysisType;
  final double? confidenceThreshold;
  final double? actualConfidence;
  final Map<String, dynamic> analysisData;

  const AIAnalysisError({
    required super.id,
    required super.type,
    required super.severity,
    required super.message,
    required super.technicalMessage,
    required super.userFriendlyMessage,
    required super.context,
    super.originalException,
    super.stackTrace,
    super.recoveryActions,
    super.metadata,
    required super.timestamp,
    this.modelName,
    this.analysisType,
    this.confidenceThreshold,
    this.actualConfidence,
    this.analysisData = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'model_name': modelName,
      'analysis_type': analysisType,
      'confidence_threshold': confidenceThreshold,
      'actual_confidence': actualConfidence,
      'analysis_data': analysisData,
    });
    return json;
  }
}

// ====================================
// ERROR MESSAGE PROVIDER
// ====================================

/// Provides user-friendly error messages with localization support
class ErrorMessageProvider {
  static const Map<FileOrganizerErrorType, Map<String, String>> _errorMessages = {
    FileOrganizerErrorType.fileNotFound: {
      'title': 'File Not Found',
      'message': 'The file you\'re trying to organize could not be found.',
      'suggestion': 'Make sure the file exists and try again.',
    },
    FileOrganizerErrorType.fileAccessDenied: {
      'title': 'Access Denied',
      'message': 'You don\'t have permission to access this file.',
      'suggestion': 'Check file permissions or try running as administrator.',
    },
    FileOrganizerErrorType.fileLocked: {
      'title': 'File is Locked',
      'message': 'This file is currently being used by another program.',
      'suggestion': 'Close any programs using this file and try again.',
    },
    FileOrganizerErrorType.diskSpaceInsufficient: {
      'title': 'Not Enough Space',
      'message': 'There isn\'t enough free space on the destination drive.',
      'suggestion': 'Free up some space or choose a different destination.',
    },
    FileOrganizerErrorType.networkTimeout: {
      'title': 'Connection Timeout',
      'message': 'The operation timed out while connecting to the server.',
      'suggestion': 'Check your internet connection and try again.',
    },
    FileOrganizerErrorType.operationCancelled: {
      'title': 'Operation Cancelled',
      'message': 'The file organization was cancelled by the user.',
      'suggestion': 'You can restart the operation whenever you\'re ready.',
    },
    FileOrganizerErrorType.analysisTimeout: {
      'title': 'Analysis Timeout',
      'message': 'The AI analysis took too long to complete.',
      'suggestion': 'Try organizing fewer files at once or check your connection.',
    },
    FileOrganizerErrorType.confidenceTooLow: {
      'title': 'Low Confidence',
      'message': 'The AI isn\'t confident enough about how to organize these files.',
      'suggestion': 'Try providing more specific organization rules or manual input.',
    },
  };

  /// Get user-friendly message for error type
  static Map<String, String> getErrorMessage(FileOrganizerErrorType type) {
    return _errorMessages[type] ?? {
      'title': 'Unknown Error',
      'message': 'An unexpected error occurred.',
      'suggestion': 'Please try again or contact support if the problem persists.',
    };
  }

  /// Generate user-friendly error with context
  static String generateUserFriendlyMessage(
    FileOrganizerErrorType type,
    ErrorContext context, {
    Map<String, dynamic>? substitutions,
  }) {
    final errorInfo = getErrorMessage(type);
    String message = errorInfo['message'] ?? 'An error occurred.';
    
    // Add context-specific information
    if (context.filePath != null) {
      final fileName = context.filePath!.split('/').last;
      message = message.replaceAll('this file', '"$fileName"');
      message = message.replaceAll('The file', 'The file "$fileName"');
    }
    
    // Apply substitutions if provided
    if (substitutions != null) {
      substitutions.forEach((key, value) {
        message = message.replaceAll('{$key}', value.toString());
      });
    }
    
    return message;
  }

  /// Get recovery suggestion for error type
  static String getRecoverySuggestion(FileOrganizerErrorType type) {
    final errorInfo = getErrorMessage(type);
    return errorInfo['suggestion'] ?? 'Please try again later.';
  }

  /// Get error title for display
  static String getErrorTitle(FileOrganizerErrorType type) {
    final errorInfo = getErrorMessage(type);
    return errorInfo['title'] ?? 'Error';
  }
}

// ====================================
// ERROR FACTORY
// ====================================

/// Factory for creating specific error instances
class FileOrganizerErrorFactory {
  static String _generateErrorId() {
    return 'err_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond / 1000000))).round()}';
  }

  /// Create a file system error
  static FileSystemError createFileSystemError({
    required FileOrganizerErrorType type,
    required String technicalMessage,
    required ErrorContext context,
    String? affectedPath,
    String? expectedPath,
    int? errorCode,
    String? originalException,
    String? stackTrace,
    List<RecoveryAction>? recoveryActions,
    Map<String, dynamic>? metadata,
  }) {
    final userMessage = ErrorMessageProvider.generateUserFriendlyMessage(type, context);
    
    return FileSystemError(
      id: _generateErrorId(),
      type: type,
      severity: _determineSeverity(type),
      message: technicalMessage,
      technicalMessage: technicalMessage,
      userFriendlyMessage: userMessage,
      context: context,
      originalException: originalException,
      stackTrace: stackTrace,
      recoveryActions: recoveryActions ?? _generateRecoveryActions(type, context),
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      affectedPath: affectedPath,
      expectedPath: expectedPath,
      errorCode: errorCode,
    );
  }

  /// Create a network error
  static NetworkError createNetworkError({
    required FileOrganizerErrorType type,
    required String technicalMessage,
    required ErrorContext context,
    String? endpoint,
    int? httpStatusCode,
    Duration? timeout,
    int retryCount = 0,
    String? originalException,
    String? stackTrace,
    List<RecoveryAction>? recoveryActions,
    Map<String, dynamic>? metadata,
  }) {
    final userMessage = ErrorMessageProvider.generateUserFriendlyMessage(type, context);
    
    return NetworkError(
      id: _generateErrorId(),
      type: type,
      severity: _determineSeverity(type),
      message: technicalMessage,
      technicalMessage: technicalMessage,
      userFriendlyMessage: userMessage,
      context: context,
      originalException: originalException,
      stackTrace: stackTrace,
      recoveryActions: recoveryActions ?? _generateRecoveryActions(type, context),
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      endpoint: endpoint,
      httpStatusCode: httpStatusCode,
      timeout: timeout,
      retryCount: retryCount,
    );
  }

  /// Create an operation error
  static OperationError createOperationError({
    required FileOrganizerErrorType type,
    required String technicalMessage,
    required ErrorContext context,
    String? dependentOperationId,
    String? conflictingOperationId,
    Map<String, dynamic>? operationState,
    String? originalException,
    String? stackTrace,
    List<RecoveryAction>? recoveryActions,
    Map<String, dynamic>? metadata,
  }) {
    final userMessage = ErrorMessageProvider.generateUserFriendlyMessage(type, context);
    
    return OperationError(
      id: _generateErrorId(),
      type: type,
      severity: _determineSeverity(type),
      message: technicalMessage,
      technicalMessage: technicalMessage,
      userFriendlyMessage: userMessage,
      context: context,
      originalException: originalException,
      stackTrace: stackTrace,
      recoveryActions: recoveryActions ?? _generateRecoveryActions(type, context),
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      dependentOperationId: dependentOperationId,
      conflictingOperationId: conflictingOperationId,
      operationState: operationState ?? {},
    );
  }

  /// Create a validation error
  static ValidationError createValidationError({
    required FileOrganizerErrorType type,
    required String technicalMessage,
    required ErrorContext context,
    String? fieldName,
    dynamic providedValue,
    dynamic expectedValue,
    List<String>? validationRules,
    String? originalException,
    String? stackTrace,
    List<RecoveryAction>? recoveryActions,
    Map<String, dynamic>? metadata,
  }) {
    final userMessage = ErrorMessageProvider.generateUserFriendlyMessage(type, context);
    
    return ValidationError(
      id: _generateErrorId(),
      type: type,
      severity: _determineSeverity(type),
      message: technicalMessage,
      technicalMessage: technicalMessage,
      userFriendlyMessage: userMessage,
      context: context,
      originalException: originalException,
      stackTrace: stackTrace,
      recoveryActions: recoveryActions ?? _generateRecoveryActions(type, context),
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      fieldName: fieldName,
      providedValue: providedValue,
      expectedValue: expectedValue,
      validationRules: validationRules ?? [],
    );
  }

  /// Create an AI analysis error
  static AIAnalysisError createAIAnalysisError({
    required FileOrganizerErrorType type,
    required String technicalMessage,
    required ErrorContext context,
    String? modelName,
    String? analysisType,
    double? confidenceThreshold,
    double? actualConfidence,
    Map<String, dynamic>? analysisData,
    String? originalException,
    String? stackTrace,
    List<RecoveryAction>? recoveryActions,
    Map<String, dynamic>? metadata,
  }) {
    final userMessage = ErrorMessageProvider.generateUserFriendlyMessage(type, context);
    
    return AIAnalysisError(
      id: _generateErrorId(),
      type: type,
      severity: _determineSeverity(type),
      message: technicalMessage,
      technicalMessage: technicalMessage,
      userFriendlyMessage: userMessage,
      context: context,
      originalException: originalException,
      stackTrace: stackTrace,
      recoveryActions: recoveryActions ?? _generateRecoveryActions(type, context),
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      modelName: modelName,
      analysisType: analysisType,
      confidenceThreshold: confidenceThreshold,
      actualConfidence: actualConfidence,
      analysisData: analysisData ?? {},
    );
  }

  /// Determine error severity based on type
  static ErrorSeverity _determineSeverity(FileOrganizerErrorType type) {
    switch (type) {
      case FileOrganizerErrorType.fileNotFound:
      case FileOrganizerErrorType.invalidInput:
      case FileOrganizerErrorType.formatNotSupported:
        return ErrorSeverity.warning;
      
      case FileOrganizerErrorType.fileAccessDenied:
      case FileOrganizerErrorType.permissionDenied:
      case FileOrganizerErrorType.diskSpaceInsufficient:
      case FileOrganizerErrorType.networkTimeout:
        return ErrorSeverity.error;
      
      case FileOrganizerErrorType.fileLocked:
      case FileOrganizerErrorType.operationConflict:
      case FileOrganizerErrorType.systemResourceUnavailable:
        return ErrorSeverity.critical;
      
      case FileOrganizerErrorType.fileCorrupted:
      case FileOrganizerErrorType.driveNotAvailable:
      case FileOrganizerErrorType.internalError:
        return ErrorSeverity.fatal;
      
      default:
        return ErrorSeverity.error;
    }
  }

  /// Generate default recovery actions based on error type
  static List<RecoveryAction> _generateRecoveryActions(
    FileOrganizerErrorType type,
    ErrorContext context,
  ) {
    switch (type) {
      case FileOrganizerErrorType.fileNotFound:
        return [
          RecoveryAction(
            id: 'skip_file',
            title: 'Skip This File',
            description: 'Skip this file and continue with others',
            strategy: RecoveryStrategy.skipAndContinue,
            isRecommended: true,
            successProbability: 1.0,
          ),
          RecoveryAction(
            id: 'locate_file',
            title: 'Locate File',
            description: 'Help locate the missing file',
            strategy: RecoveryStrategy.userIntervention,
            requiresUserConfirmation: true,
            successProbability: 0.5,
          ),
        ];
      
      case FileOrganizerErrorType.networkTimeout:
        return [
          RecoveryAction(
            id: 'retry_operation',
            title: 'Retry',
            description: 'Try the operation again',
            strategy: RecoveryStrategy.retryWithDelay,
            parameters: {'delay_seconds': 5},
            isRecommended: true,
            estimatedTime: Duration(seconds: 10),
            successProbability: 0.7,
          ),
          RecoveryAction(
            id: 'work_offline',
            title: 'Work Offline',
            description: 'Continue without network features',
            strategy: RecoveryStrategy.alternative,
            successProbability: 0.9,
          ),
        ];
      
      case FileOrganizerErrorType.diskSpaceInsufficient:
        return [
          RecoveryAction(
            id: 'free_space',
            title: 'Free Up Space',
            description: 'Delete unnecessary files to make room',
            strategy: RecoveryStrategy.userIntervention,
            requiresUserConfirmation: true,
            successProbability: 0.8,
          ),
          RecoveryAction(
            id: 'choose_different_location',
            title: 'Choose Different Location',
            description: 'Select a drive with more space',
            strategy: RecoveryStrategy.userIntervention,
            requiresUserConfirmation: true,
            isRecommended: true,
            successProbability: 0.9,
          ),
        ];
      
      default:
        return [
          RecoveryAction(
            id: 'retry_simple',
            title: 'Try Again',
            description: 'Retry the operation',
            strategy: RecoveryStrategy.retry,
            isRecommended: true,
            successProbability: 0.5,
          ),
        ];
    }
  }
}

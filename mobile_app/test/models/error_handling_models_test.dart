import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/models/error_handling_models.dart';

void main() {
  group('Error Handling Models Tests', () {
    group('ErrorContext', () {
      test('should create error context with all properties', () {
        final context = ErrorContext(
          operationId: 'op_001',
          sessionId: 'session_001',
          operationType: 'file_move',
          filePath: '/source/file.txt',
          targetPath: '/destination/',
          operationParameters: {'preserve_metadata': true},
          timestamp: DateTime(2024, 1, 1),
          userId: 'user_123',
          systemInfo: {'os': 'linux', 'version': '22.04'},
          environmentInfo: {'disk_space': '50GB'},
        );

        expect(context.operationId, equals('op_001'));
        expect(context.sessionId, equals('session_001'));
        expect(context.operationType, equals('file_move'));
        expect(context.filePath, equals('/source/file.txt'));
        expect(context.targetPath, equals('/destination/'));
        expect(context.operationParameters['preserve_metadata'], isTrue);
        expect(context.userId, equals('user_123'));
      });

      test('should convert to and from JSON', () {
        final original = ErrorContext(
          operationId: 'op_001',
          sessionId: 'session_001',
          operationType: 'file_move',
          filePath: '/source/file.txt',
          targetPath: '/destination/',
          operationParameters: {'preserve_metadata': true, 'overwrite': false},
          timestamp: DateTime(2024, 1, 1),
          userId: 'user_123',
          systemInfo: {'os': 'linux', 'version': '22.04'},
          environmentInfo: {'disk_space': '50GB', 'memory': '16GB'},
        );

        final json = original.toJson();
        final restored = ErrorContext.fromJson(json);

        expect(restored.operationId, equals(original.operationId));
        expect(restored.sessionId, equals(original.sessionId));
        expect(restored.operationType, equals(original.operationType));
        expect(restored.filePath, equals(original.filePath));
        expect(restored.targetPath, equals(original.targetPath));
        expect(restored.operationParameters, equals(original.operationParameters));
        expect(restored.timestamp, equals(original.timestamp));
        expect(restored.userId, equals(original.userId));
        expect(restored.systemInfo, equals(original.systemInfo));
        expect(restored.environmentInfo, equals(original.environmentInfo));
      });
    });

    group('RecoveryAction', () {
      test('should create recovery action with all properties', () {
        final action = RecoveryAction(
          id: 'retry_with_delay',
          title: 'Retry Operation',
          description: 'Retry the operation after a short delay',
          strategy: RecoveryStrategy.retryWithDelay,
          parameters: {'delay_seconds': 5, 'max_retries': 3},
          requiresUserConfirmation: false,
          isRecommended: true,
          estimatedTime: Duration(seconds: 10),
          successProbability: 0.8,
        );

        expect(action.id, equals('retry_with_delay'));
        expect(action.title, equals('Retry Operation'));
        expect(action.description, equals('Retry the operation after a short delay'));
        expect(action.strategy, equals(RecoveryStrategy.retryWithDelay));
        expect(action.parameters['delay_seconds'], equals(5));
        expect(action.requiresUserConfirmation, isFalse);
        expect(action.isRecommended, isTrue);
        expect(action.estimatedTime, equals(Duration(seconds: 10)));
        expect(action.successProbability, equals(0.8));
      });

      test('should convert to and from JSON', () {
        final original = RecoveryAction(
          id: 'skip_file',
          title: 'Skip This File',
          description: 'Skip the problematic file and continue',
          strategy: RecoveryStrategy.skipAndContinue,
          parameters: {'log_skipped': true},
          requiresUserConfirmation: true,
          isRecommended: false,
          estimatedTime: Duration(seconds: 1),
          successProbability: 1.0,
        );

        final json = original.toJson();
        final restored = RecoveryAction.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.title, equals(original.title));
        expect(restored.description, equals(original.description));
        expect(restored.strategy, equals(original.strategy));
        expect(restored.parameters, equals(original.parameters));
        expect(restored.requiresUserConfirmation, equals(original.requiresUserConfirmation));
        expect(restored.isRecommended, equals(original.isRecommended));
        expect(restored.estimatedTime, equals(original.estimatedTime));
        expect(restored.successProbability, equals(original.successProbability));
      });
    });

    group('ErrorMessageProvider', () {
      test('should provide user-friendly messages for known error types', () {
        final fileNotFoundMessage = ErrorMessageProvider.getErrorMessage(
          FileOrganizerErrorType.fileNotFound,
        );

        expect(fileNotFoundMessage['title'], equals('File Not Found'));
        expect(fileNotFoundMessage['message'], isNotEmpty);
        expect(fileNotFoundMessage['suggestion'], isNotEmpty);

        final diskSpaceMessage = ErrorMessageProvider.getErrorMessage(
          FileOrganizerErrorType.diskSpaceInsufficient,
        );

        expect(diskSpaceMessage['title'], equals('Not Enough Space'));
        expect(diskSpaceMessage['message'], contains('space'));
        expect(diskSpaceMessage['suggestion'], contains('space'));
      });

      test('should provide default message for unknown error types', () {
        final unknownMessage = ErrorMessageProvider.getErrorMessage(
          FileOrganizerErrorType.unknown,
        );

        expect(unknownMessage['title'], equals('Unknown Error'));
        expect(unknownMessage['message'], equals('An unexpected error occurred.'));
        expect(unknownMessage['suggestion'], isNotEmpty);
      });

      test('should generate context-specific user-friendly messages', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'file_move',
          filePath: '/downloads/important_document.pdf',
          timestamp: DateTime.now(),
        );

        final message = ErrorMessageProvider.generateUserFriendlyMessage(
          FileOrganizerErrorType.fileNotFound,
          context,
        );

        expect(message, contains('important_document.pdf'));
      });

      test('should apply substitutions in messages', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'file_move',
          timestamp: DateTime.now(),
        );

        // Test the message generation works
        final message = ErrorMessageProvider.generateUserFriendlyMessage(
          FileOrganizerErrorType.diskSpaceInsufficient,
          context,
        );

        expect(message, isNotEmpty);
        expect(message, contains('space'));
      });

      test('should provide recovery suggestions', () {
        final suggestion = ErrorMessageProvider.getRecoverySuggestion(
          FileOrganizerErrorType.networkTimeout,
        );

        expect(suggestion, isNotEmpty);
        expect(suggestion, contains('connection'));
      });

      test('should provide error titles', () {
        final title = ErrorMessageProvider.getErrorTitle(
          FileOrganizerErrorType.fileAccessDenied,
        );

        expect(title, equals('Access Denied'));
      });
    });

    group('FileOrganizerErrorFactory', () {
      group('FileSystemError', () {
        test('should create file system error with correct properties', () {
          final context = ErrorContext(
            operationId: 'op_001',
            operationType: 'file_move',
            filePath: '/source/file.txt',
            timestamp: DateTime.now(),
          );

          final error = FileOrganizerErrorFactory.createFileSystemError(
            type: FileOrganizerErrorType.fileNotFound,
            technicalMessage: 'File not found at specified path',
            context: context,
            affectedPath: '/source/file.txt',
            errorCode: 404,
          );

          expect(error, isA<FileSystemError>());
          expect(error.type, equals(FileOrganizerErrorType.fileNotFound));
          expect(error.severity, equals(ErrorSeverity.warning));
          expect(error.technicalMessage, equals('File not found at specified path'));
          expect(error.userFriendlyMessage, isNotEmpty);
          expect(error.context, equals(context));
          expect(error.affectedPath, equals('/source/file.txt'));
          expect(error.errorCode, equals(404));
          expect(error.recoveryActions, isNotEmpty);
        });

        test('should determine correct severity for file system errors', () {
          final context = ErrorContext(
            operationId: 'op_001',
            operationType: 'file_move',
            timestamp: DateTime.now(),
          );

          final fileNotFoundError = FileOrganizerErrorFactory.createFileSystemError(
            type: FileOrganizerErrorType.fileNotFound,
            technicalMessage: 'File not found',
            context: context,
          );

          expect(fileNotFoundError.severity, equals(ErrorSeverity.warning));

          final diskSpaceError = FileOrganizerErrorFactory.createFileSystemError(
            type: FileOrganizerErrorType.diskSpaceInsufficient,
            technicalMessage: 'Insufficient disk space',
            context: context,
          );

          expect(diskSpaceError.severity, equals(ErrorSeverity.error));

          final fileLockedError = FileOrganizerErrorFactory.createFileSystemError(
            type: FileOrganizerErrorType.fileLocked,
            technicalMessage: 'File is locked',
            context: context,
          );

          expect(fileLockedError.severity, equals(ErrorSeverity.critical));
        });
      });

      group('NetworkError', () {
        test('should create network error with correct properties', () {
          final context = ErrorContext(
            operationId: 'op_001',
            operationType: 'api_call',
            timestamp: DateTime.now(),
          );

          final error = FileOrganizerErrorFactory.createNetworkError(
            type: FileOrganizerErrorType.networkTimeout,
            technicalMessage: 'Request timed out after 30 seconds',
            context: context,
            endpoint: 'https://api.example.com/organize',
            httpStatusCode: 408,
            timeout: Duration(seconds: 30),
            retryCount: 2,
          );

          expect(error, isA<NetworkError>());
          expect(error.type, equals(FileOrganizerErrorType.networkTimeout));
          expect(error.endpoint, equals('https://api.example.com/organize'));
          expect(error.httpStatusCode, equals(408));
          expect(error.timeout, equals(Duration(seconds: 30)));
          expect(error.retryCount, equals(2));
        });
      });

      group('OperationError', () {
        test('should create operation error with correct properties', () {
          final context = ErrorContext(
            operationId: 'op_002',
            operationType: 'file_move',
            timestamp: DateTime.now(),
          );

          final error = FileOrganizerErrorFactory.createOperationError(
            type: FileOrganizerErrorType.operationConflict,
            technicalMessage: 'Operation conflicts with existing operation',
            context: context,
            dependentOperationId: 'op_001',
            conflictingOperationId: 'op_003',
            operationState: {'status': 'blocked', 'reason': 'dependency_failed'},
          );

          expect(error, isA<OperationError>());
          expect(error.type, equals(FileOrganizerErrorType.operationConflict));
          expect(error.dependentOperationId, equals('op_001'));
          expect(error.conflictingOperationId, equals('op_003'));
          expect(error.operationState['status'], equals('blocked'));
        });
      });

      group('ValidationError', () {
        test('should create validation error with correct properties', () {
          final context = ErrorContext(
            operationId: 'op_001',
            operationType: 'input_validation',
            timestamp: DateTime.now(),
          );

          final error = FileOrganizerErrorFactory.createValidationError(
            type: FileOrganizerErrorType.invalidInput,
            technicalMessage: 'Invalid file path format',
            context: context,
            fieldName: 'destination_path',
            providedValue: 'invalid//path',
            expectedValue: '/valid/path',
            validationRules: ['no_double_slashes', 'absolute_path'],
          );

          expect(error, isA<ValidationError>());
          expect(error.type, equals(FileOrganizerErrorType.invalidInput));
          expect(error.fieldName, equals('destination_path'));
          expect(error.providedValue, equals('invalid//path'));
          expect(error.expectedValue, equals('/valid/path'));
          expect(error.validationRules, contains('no_double_slashes'));
        });
      });

      group('AIAnalysisError', () {
        test('should create AI analysis error with correct properties', () {
          final context = ErrorContext(
            operationId: 'op_001',
            operationType: 'ai_analysis',
            timestamp: DateTime.now(),
          );

          final error = FileOrganizerErrorFactory.createAIAnalysisError(
            type: FileOrganizerErrorType.confidenceTooLow,
            technicalMessage: 'AI confidence below threshold',
            context: context,
            modelName: 'file_classifier_v2',
            analysisType: 'content_classification',
            confidenceThreshold: 0.8,
            actualConfidence: 0.65,
            analysisData: {'categories': ['document', 'image'], 'scores': [0.65, 0.35]},
          );

          expect(error, isA<AIAnalysisError>());
          expect(error.type, equals(FileOrganizerErrorType.confidenceTooLow));
          expect(error.modelName, equals('file_classifier_v2'));
          expect(error.analysisType, equals('content_classification'));
          expect(error.confidenceThreshold, equals(0.8));
          expect(error.actualConfidence, equals(0.65));
          expect(error.analysisData['categories'], equals(['document', 'image']));
        });
      });

      test('should generate appropriate recovery actions', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'file_move',
          timestamp: DateTime.now(),
        );

        // Test file not found recovery actions
        final fileNotFoundError = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found',
          context: context,
        );

        expect(fileNotFoundError.recoveryActions, hasLength(2));
        expect(
          fileNotFoundError.recoveryActions.any((action) => 
            action.strategy == RecoveryStrategy.skipAndContinue),
          isTrue,
        );
        expect(
          fileNotFoundError.recoveryActions.any((action) => 
            action.strategy == RecoveryStrategy.userIntervention),
          isTrue,
        );

        // Test network timeout recovery actions
        final networkError = FileOrganizerErrorFactory.createNetworkError(
          type: FileOrganizerErrorType.networkTimeout,
          technicalMessage: 'Network timeout',
          context: context,
        );

        expect(networkError.recoveryActions, hasLength(2));
        expect(
          networkError.recoveryActions.any((action) => 
            action.strategy == RecoveryStrategy.retryWithDelay),
          isTrue,
        );
        expect(
          networkError.recoveryActions.any((action) => 
            action.strategy == RecoveryStrategy.alternative),
          isTrue,
        );
      });
    });

    group('Error Base Class Functionality', () {
      test('should provide correct display message', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          timestamp: DateTime.now(),
        );

        final error = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'Technical: File not found at /path',
          context: context,
        );

        // Should prefer user-friendly message over technical message
        final displayMessage = error.getDisplayMessage();
        expect(displayMessage, isNot(contains('Technical:')));
        expect(displayMessage, isNotEmpty);
      });

      test('should identify recommended recovery action', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          timestamp: DateTime.now(),
        );

        final error = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found',
          context: context,
        );

        final recommendedAction = error.recommendedAction;
        expect(recommendedAction, isNotNull);
        expect(recommendedAction!.isRecommended, isTrue);
      });

      test('should identify if error is recoverable', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          timestamp: DateTime.now(),
        );

        final recoverableError = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found',
          context: context,
        );

        expect(recoverableError.isRecoverable, isTrue);

        final nonRecoverableError = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found',
          context: context,
          recoveryActions: [], // No recovery actions
        );

        expect(nonRecoverableError.isRecoverable, isFalse);
      });

      test('should identify if error requires immediate attention', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          timestamp: DateTime.now(),
        );

        final criticalError = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileLocked, // This maps to critical severity
          technicalMessage: 'File is locked',
          context: context,
        );

        expect(criticalError.requiresImmediateAttention, isTrue);

        final warningError = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound, // This maps to warning severity
          technicalMessage: 'File not found',
          context: context,
        );

        expect(warningError.requiresImmediateAttention, isFalse);
      });

      test('should convert error to JSON with all information', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          filePath: '/test/file.txt',
          timestamp: DateTime.now(),
        );

        final error = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found',
          context: context,
          affectedPath: '/test/file.txt',
          originalException: 'FileNotFoundException',
          stackTrace: 'Stack trace here...',
          metadata: {'additional_info': 'test'},
        );

        final json = error.toJson();

        expect(json['id'], isNotEmpty);
        expect(json['type'], equals('FileOrganizerErrorType.fileNotFound'));
        expect(json['severity'], equals('ErrorSeverity.warning'));
        expect(json['message'], equals('File not found'));
        expect(json['technical_message'], equals('File not found'));
        expect(json['user_friendly_message'], isNotEmpty);
        expect(json['context'], isA<Map<String, dynamic>>());
        expect(json['original_exception'], equals('FileNotFoundException'));
        expect(json['stack_trace'], equals('Stack trace here...'));
        expect(json['recovery_actions'], isA<List>());
        expect(json['metadata']['additional_info'], equals('test'));
        expect(json['timestamp'], isNotEmpty);
        expect(json['error_class'], equals('FileSystemError'));
      });

      test('should provide meaningful toString representation', () {
        final context = ErrorContext(
          operationId: 'op_001',
          operationType: 'test',
          timestamp: DateTime.now(),
        );

        final error = FileOrganizerErrorFactory.createFileSystemError(
          type: FileOrganizerErrorType.fileNotFound,
          technicalMessage: 'File not found at specified location',
          context: context,
        );

        final stringRepresentation = error.toString();
        expect(stringRepresentation, contains('FileOrganizerError'));
        expect(stringRepresentation, contains('File not found at specified location'));
      });
    });
  });
}

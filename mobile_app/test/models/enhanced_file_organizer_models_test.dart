import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/models/enhanced_file_organizer_models.dart';

void main() {
  group('Enhanced File Organizer Models Tests', () {
    group('ConfidenceMetrics', () {
      test('should create from simple confidence value', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        
        expect(confidence.overall, equals(0.8));
        expect(confidence.patternMatch, equals(0.8));
        expect(confidence.userHistoryAlignment, equals(0.8));
        expect(confidence.contextualRelevance, equals(0.8));
        expect(confidence.aiCertainty, equals(0.8));
      });

      test('should convert to and from JSON', () {
        final original = ConfidenceMetrics(
          overall: 0.85,
          patternMatch: 0.9,
          userHistoryAlignment: 0.7,
          contextualRelevance: 0.8,
          aiCertainty: 0.95,
          contributingFactors: ['pattern_match', 'recent_usage'],
          uncertaintyFactors: ['limited_data'],
        );

        final json = original.toJson();
        final restored = ConfidenceMetrics.fromJson(json);

        expect(restored.overall, equals(original.overall));
        expect(restored.patternMatch, equals(original.patternMatch));
        expect(restored.contributingFactors, equals(original.contributingFactors));
        expect(restored.uncertaintyFactors, equals(original.uncertaintyFactors));
      });
    });

    group('RiskAssessment', () {
      test('should create low risk assessment', () {
        final risk = RiskAssessment.low();
        
        expect(risk.level, equals(RiskLevel.low));
        expect(risk.score, equals(0.2));
        expect(risk.requiresConfirmation, isFalse);
        expect(risk.isReversible, isTrue);
      });

      test('should create medium risk assessment', () {
        final risk = RiskAssessment.medium();
        
        expect(risk.level, equals(RiskLevel.medium));
        expect(risk.score, equals(0.5));
        expect(risk.requiresConfirmation, isTrue);
        expect(risk.isReversible, isTrue);
      });

      test('should create high risk assessment', () {
        final risk = RiskAssessment.high();
        
        expect(risk.level, equals(RiskLevel.high));
        expect(risk.score, equals(0.8));
        expect(risk.requiresConfirmation, isTrue);
        expect(risk.isReversible, isFalse);
      });

      test('should convert to JSON', () {
        final risk = RiskAssessment(
          level: RiskLevel.medium,
          score: 0.6,
          risks: ['data_loss', 'performance_impact'],
          mitigations: ['backup_created', 'rollback_available'],
          requiresConfirmation: true,
          isReversible: true,
          estimatedRecoveryTime: Duration(minutes: 5),
        );

        final json = risk.toJson();
        
        expect(json['level'], equals('RiskLevel.medium'));
        expect(json['score'], equals(0.6));
        expect(json['risks'], equals(['data_loss', 'performance_impact']));
        expect(json['requires_confirmation'], isTrue);
        expect(json['estimated_recovery_time'], equals(300));
      });
    });

    group('EnhancedFileOperation', () {
      test('should create enhanced file operation with all properties', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        final risk = RiskAssessment.low();
        final reasoning = AIReasoning(
          primaryReason: 'File matches pattern for documents',
          reasoningConfidence: 0.8,
        );

        final operation = EnhancedFileOperation(
          id: 'op_001',
          type: FileOperationType.move,
          sourcePath: '/downloads/document.pdf',
          destinationPath: '/documents/',
          confidence: confidence,
          risk: risk,
          reasoning: reasoning,
          estimatedSize: 1024 * 1024, // 1MB
          estimatedTime: Duration(seconds: 5),
        );

        expect(operation.id, equals('op_001'));
        expect(operation.type, equals(FileOperationType.move));
        expect(operation.sourcePath, equals('/downloads/document.pdf'));
        expect(operation.destinationPath, equals('/documents/'));
        expect(operation.confidence.overall, equals(0.8));
        expect(operation.risk.level, equals(RiskLevel.low));
        expect(operation.estimatedSize, equals(1024 * 1024));
      });

      test('should calculate complexity score correctly', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        final risk = RiskAssessment.high(); // Higher risk should increase complexity
        final reasoning = AIReasoning(
          primaryReason: 'Test operation',
          reasoningConfidence: 0.8,
        );

        final operation = EnhancedFileOperation(
          id: 'op_001',
          type: FileOperationType.compress, // More complex operation
          sourcePath: '/test/file.txt',
          confidence: confidence,
          risk: risk,
          reasoning: reasoning,
          estimatedSize: 10 * 1024 * 1024, // 10MB
          estimatedTime: Duration(seconds: 30),
          dependsOn: ['op_000'], // Has dependencies
        );

        final complexity = operation.complexityScore;
        
        // Should be higher than base score due to:
        // - Compress operation (+3.0)
        // - Large size (+10.0 clamped to +5.0)
        // - High risk (+1.6)
        // - Dependencies (+0.5)
        expect(complexity, greaterThan(5.0));
      });

      test('should determine if ready to execute', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        final risk = RiskAssessment.low();
        final reasoning = AIReasoning(
          primaryReason: 'Test operation',
          reasoningConfidence: 0.8,
        );

        // Operation that is ready
        final readyOperation = EnhancedFileOperation(
          id: 'op_001',
          type: FileOperationType.move,
          sourcePath: '/test/file.txt',
          confidence: confidence,
          risk: risk,
          reasoning: reasoning,
          estimatedSize: 1024,
          estimatedTime: Duration(seconds: 1),
          isApproved: true,
          status: OperationStatus.queued,
          dependsOn: [], // No dependencies
        );

        expect(readyOperation.isReadyToExecute, isTrue);

        // Operation that is not ready (has dependencies)
        final notReadyOperation = readyOperation.copyWith(
          dependsOn: ['op_000'],
        );

        expect(notReadyOperation.isReadyToExecute, isFalse);
      });

      test('should generate correct description', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        final risk = RiskAssessment.low();
        final reasoning = AIReasoning(
          primaryReason: 'Test operation',
          reasoningConfidence: 0.8,
        );

        final moveOperation = EnhancedFileOperation(
          id: 'op_001',
          type: FileOperationType.move,
          sourcePath: '/downloads/document.pdf',
          destinationPath: '/documents/',
          confidence: confidence,
          risk: risk,
          reasoning: reasoning,
          estimatedSize: 1024,
          estimatedTime: Duration(seconds: 1),
        );

        expect(moveOperation.description, equals('Move document.pdf to /documents/'));

        final deleteOperation = moveOperation.copyWith(
          type: FileOperationType.delete,
          destinationPath: null,
        );

        expect(deleteOperation.description, equals('Delete document.pdf'));
      });

      test('should convert to and from JSON', () {
        final confidence = ConfidenceMetrics.fromSimple(0.8);
        final risk = RiskAssessment.medium();
        final reasoning = AIReasoning(
          primaryReason: 'File type analysis',
          supportingReasons: ['extension_match', 'content_analysis'],
          reasoningConfidence: 0.85,
        );

        final original = EnhancedFileOperation(
          id: 'op_001',
          type: FileOperationType.move,
          sourcePath: '/downloads/document.pdf',
          destinationPath: '/documents/',
          confidence: confidence,
          risk: risk,
          reasoning: reasoning,
          dependsOn: ['op_000'],
          enables: ['op_002'],
          priority: 3,
          estimatedSize: 1024 * 1024,
          estimatedTime: Duration(seconds: 10),
          tags: ['document', 'work'],
        );

        final json = original.toJson();
        final restored = EnhancedFileOperation.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.sourcePath, equals(original.sourcePath));
        expect(restored.destinationPath, equals(original.destinationPath));
        expect(restored.dependsOn, equals(original.dependsOn));
        expect(restored.enables, equals(original.enables));
        expect(restored.priority, equals(original.priority));
        expect(restored.estimatedSize, equals(original.estimatedSize));
        expect(restored.estimatedTime, equals(original.estimatedTime));
        expect(restored.tags, equals(original.tags));
      });
    });

    group('DriveHealthMetrics', () {
      test('should create unknown health metrics', () {
        final health = DriveHealthMetrics.unknown();
        
        expect(health.overall, equals(DriveHealth.unknown));
        expect(health.temperature, equals(0.0));
        expect(health.powerOnHours, equals(0));
        expect(health.errorCount, equals(0));
        expect(health.readWriteSpeed, equals(0.0));
        expect(health.smartWarnings, isEmpty);
      });

      test('should convert to and from JSON', () {
        final original = DriveHealthMetrics(
          overall: DriveHealth.good,
          temperature: 42.5,
          powerOnHours: 8760, // 1 year
          errorCount: 2,
          readWriteSpeed: 120.5,
          smartWarnings: ['temperature_warning'],
          lastHealthCheck: DateTime(2024, 1, 1),
          smartData: {'bad_sectors': 0, 'reallocated_sectors': 1},
        );

        final json = original.toJson();
        final restored = DriveHealthMetrics.fromJson(json);

        expect(restored.overall, equals(original.overall));
        expect(restored.temperature, equals(original.temperature));
        expect(restored.powerOnHours, equals(original.powerOnHours));
        expect(restored.errorCount, equals(original.errorCount));
        expect(restored.readWriteSpeed, equals(original.readWriteSpeed));
        expect(restored.smartWarnings, equals(original.smartWarnings));
        expect(restored.smartData, equals(original.smartData));
      });
    });

    group('EnhancedDriveInfo', () {
      test('should create enhanced drive info with all properties', () {
        final health = DriveHealthMetrics(
          overall: DriveHealth.excellent,
          temperature: 35.0,
          powerOnHours: 1000,
          errorCount: 0,
          readWriteSpeed: 150.0,
          lastHealthCheck: DateTime.now(),
        );

        final usagePatterns = DriveUsagePatterns(
          averageUtilization: 0.65,
          fileTypeDistribution: {'pdf': 120, 'jpg': 300, 'txt': 50},
          commonFolders: ['/Documents', '/Pictures', '/Downloads'],
          analysisDate: DateTime.now(),
        );

        final drive = EnhancedDriveInfo(
          path: '/dev/sda1',
          name: 'Primary SSD',
          type: 'SSD',
          model: 'Samsung 980 PRO',
          serialNumber: 'S6J2NX0R123456',
          totalSpace: 1024 * 1024 * 1024 * 1024, // 1TB
          freeSpace: 512 * 1024 * 1024 * 1024, // 512GB
          usedSpace: 512 * 1024 * 1024 * 1024, // 512GB
          utilizationPercentage: 0.5,
          isConnected: true,
          health: health,
          usagePatterns: usagePatterns,
          organizationScore: 0.85,
          lastAnalyzed: DateTime.now(),
        );

        expect(drive.path, equals('/dev/sda1'));
        expect(drive.name, equals('Primary SSD'));
        expect(drive.type, equals('SSD'));
        expect(drive.model, equals('Samsung 980 PRO'));
        expect(drive.utilizationPercentage, equals(0.5));
        expect(drive.organizationScore, equals(0.85));
        expect(drive.health.overall, equals(DriveHealth.excellent));
      });

      test('should determine space status correctly', () {
        final health = DriveHealthMetrics.unknown();
        final usagePatterns = DriveUsagePatterns(
          averageUtilization: 0.0,
          analysisDate: DateTime.now(),
        );

        // Test different utilization levels
        final lowUsageDrive = EnhancedDriveInfo(
          path: '/test',
          name: 'Test Drive',
          type: 'HDD',
          totalSpace: 1000,
          freeSpace: 800,
          usedSpace: 200,
          utilizationPercentage: 0.2,
          isConnected: true,
          health: health,
          usagePatterns: usagePatterns,
          organizationScore: 0.5,
          lastAnalyzed: DateTime.now(),
        );

        expect(lowUsageDrive.spaceStatus, equals('Plenty of space'));

        final highUsageDrive = lowUsageDrive.copyWith(
          utilizationPercentage: 0.92,
        );

        expect(highUsageDrive.spaceStatus, equals('Nearly full'));

        final fullDrive = lowUsageDrive.copyWith(
          utilizationPercentage: 0.98,
        );

        expect(fullDrive.spaceStatus, equals('Critical - drive full'));
      });

      test('should determine if drive needs attention', () {
        final goodHealth = DriveHealthMetrics(
          overall: DriveHealth.excellent,
          temperature: 35.0,
          powerOnHours: 1000,
          errorCount: 0,
          readWriteSpeed: 150.0,
          lastHealthCheck: DateTime.now(),
        );

        final usagePatterns = DriveUsagePatterns(
          averageUtilization: 0.5,
          analysisDate: DateTime.now(),
        );

        // Healthy drive
        final healthyDrive = EnhancedDriveInfo(
          path: '/test',
          name: 'Healthy Drive',
          type: 'SSD',
          totalSpace: 1000,
          freeSpace: 500,
          usedSpace: 500,
          utilizationPercentage: 0.5,
          isConnected: true,
          health: goodHealth,
          usagePatterns: usagePatterns,
          organizationScore: 0.8,
          lastAnalyzed: DateTime.now(),
        );

        expect(healthyDrive.needsAttention, isFalse);

        // Drive with high utilization
        final fullDrive = healthyDrive.copyWith(
          utilizationPercentage: 0.95,
        );

        expect(fullDrive.needsAttention, isTrue);

        // Drive with poor health
        final unhealthyDrive = healthyDrive.copyWith(
          health: DriveHealthMetrics(
            overall: DriveHealth.critical,
            temperature: 35.0,
            powerOnHours: 1000,
            errorCount: 0,
            readWriteSpeed: 150.0,
            lastHealthCheck: DateTime.now(),
          ),
        );

        expect(unhealthyDrive.needsAttention, isTrue);
      });

      test('should provide appropriate recommendations', () {
        final health = DriveHealthMetrics.unknown();
        final usagePatterns = DriveUsagePatterns(
          averageUtilization: 0.0,
          analysisDate: DateTime.now(),
        );

        // Nearly full drive
        final fullDrive = EnhancedDriveInfo(
          path: '/test',
          name: 'Full Drive',
          type: 'HDD',
          totalSpace: 1000,
          freeSpace: 20,
          usedSpace: 980,
          utilizationPercentage: 0.98,
          isConnected: true,
          health: health,
          usagePatterns: usagePatterns,
          organizationScore: 0.5,
          lastAnalyzed: DateTime.now(),
        );

        expect(
          fullDrive.primaryRecommendation,
          equals('Free up space - drive is nearly full'),
        );

        // Drive with critical health
        final criticalDrive = fullDrive.copyWith(
          utilizationPercentage: 0.5,
          health: DriveHealthMetrics(
            overall: DriveHealth.critical,
            temperature: 35.0,
            powerOnHours: 1000,
            errorCount: 0,
            readWriteSpeed: 150.0,
            lastHealthCheck: DateTime.now(),
          ),
        );

        expect(
          criticalDrive.primaryRecommendation,
          equals('Backup data immediately - drive health critical'),
        );
      });
    });

    group('EnhancedOrganizationPreset', () {
      test('should calculate overall relevance score correctly', () {
        final preset = EnhancedOrganizationPreset(
          id: 'preset_001',
          name: 'Work Documents',
          description: 'Organize work documents',
          intent: 'organize_by_project',
          staticRelevanceScore: 0.8,
          dynamicRelevanceScore: 0.7,
          successRate: 0.9,
          usageCount: 10,
          successCount: 9,
          userRating: 4.5,
          isCustom: false,
          createdAt: DateTime.now(),
          lastUsed: DateTime.now().subtract(Duration(days: 3)),
        );

        final relevanceScore = preset.overallRelevanceScore;
        
        // Base: (0.8 + 0.7) / 2 = 0.75
        // Success boost: 0.9 * 0.2 = 0.18
        // Rating boost: (4.5 / 5.0) * 0.1 = 0.09
        // Recency boost: 0.1 (used within 7 days)
        // Expected: 0.75 + 0.18 + 0.09 + 0.1 = 1.12, clamped to 1.0
        expect(relevanceScore, equals(1.0));
      });

      test('should check if suitable for context', () {
        final preset = EnhancedOrganizationPreset(
          id: 'preset_001',
          name: 'Work Documents',
          description: 'Organize work documents',
          intent: 'organize_by_project',
          applicableFileTypes: ['pdf', 'docx', 'txt'],
          contextTags: ['work', 'professional'],
          targetCriteria: {'folder_type': 'documents'},
          staticRelevanceScore: 0.8,
          dynamicRelevanceScore: 0.8,
          successRate: 0.9,
          isCustom: false,
          createdAt: DateTime.now(),
        );

        // Matching context
        final matchingContext = {
          'file_types': ['pdf', 'docx'],
          'tags': ['work', 'business'],
          'folder_type': 'documents',
        };

        expect(preset.isSuitableFor(matchingContext), isTrue);

        // Non-matching context (wrong file types)
        final nonMatchingContext = {
          'file_types': ['jpg', 'png'],
          'tags': ['work'],
          'folder_type': 'documents',
        };

        expect(preset.isSuitableFor(nonMatchingContext), isFalse);
      });

      test('should record usage correctly', () {
        final original = EnhancedOrganizationPreset(
          id: 'preset_001',
          name: 'Test Preset',
          description: 'Test preset',
          intent: 'test',
          staticRelevanceScore: 0.8,
          dynamicRelevanceScore: 0.8,
          successRate: 0.8,
          usageCount: 5,
          successCount: 4,
          userRating: 4.0,
          isCustom: false,
          createdAt: DateTime.now(),
        );

        final updated = original.recordUsage(
          wasSuccessful: true,
          modifications: {'folder_structure': 'modified'},
          feedback: 'Worked well',
          rating: 5.0,
        );

        expect(updated.usageCount, equals(6));
        expect(updated.successCount, equals(5));
        expect(updated.successRate, equals(5.0 / 6.0));
        expect(updated.userModifications['folder_structure'], equals(1));
        expect(updated.userFeedback.last, equals('Worked well'));
        // Rating: ((4.0 * 5) + 5.0) / 6 = 25/6 ≈ 4.17
        expect(updated.userRating, closeTo(4.17, 0.01));
        expect(updated.usageHistory, hasLength(1));
      });
    });

    group('EnhancedFolderAnalytics', () {
      test('should calculate overall health score', () {
        final analytics = EnhancedFolderAnalytics(
          path: '/test/folder',
          analyzedAt: DateTime.now(),
          totalFiles: 100,
          totalFolders: 10,
          totalSize: 1024 * 1024,
          depth: 3,
          organizationScore: 0.8,
          spaceEfficiency: 0.9,
          accessEfficiency: 0.7,
        );

        final healthScore = analytics.overallHealthScore;
        // (0.8 + 0.9 + 0.7) / 3 = 0.8
        expect(healthScore, closeTo(0.8, 0.01));
      });

      test('should identify priority issues', () {
        final analytics = EnhancedFolderAnalytics(
          path: '/test/folder',
          analyzedAt: DateTime.now(),
          totalFiles: 100,
          totalFolders: 10,
          totalSize: 1024 * 1024,
          depth: 10, // Very deep
          duplicates: List.generate(15, (i) => 'duplicate_$i'), // 15% duplicates
          organizationScore: 0.2, // Poor organization
          spaceEfficiency: 0.3, // Low efficiency
          accessEfficiency: 0.7,
        );

        final issues = analytics.priorityIssues;
        
        expect(issues, hasLength(4)); // Should have all 4 types of issues
        
        // Check for organization issue
        expect(
          issues.any((issue) => issue['type'] == 'organization'),
          isTrue,
        );
        
        // Check for duplicates issue
        expect(
          issues.any((issue) => issue['type'] == 'duplicates'),
          isTrue,
        );
        
        // Check for space efficiency issue
        expect(
          issues.any((issue) => issue['type'] == 'space'),
          isTrue,
        );
        
        // Check for structure issue (deep nesting)
        expect(
          issues.any((issue) => issue['type'] == 'structure'),
          isTrue,
        );
      });

      test('should return top optimizations', () {
        final analytics = EnhancedFolderAnalytics(
          path: '/test/folder',
          analyzedAt: DateTime.now(),
          totalFiles: 100,
          totalFolders: 10,
          totalSize: 1024 * 1024,
          depth: 3,
          organizationScore: 0.8,
          spaceEfficiency: 0.9,
          accessEfficiency: 0.7,
          optimizationSuggestions: [
            {'title': 'High Impact', 'impact_score': 0.9},
            {'title': 'Low Impact', 'impact_score': 0.3},
          ],
          organizationSuggestions: [
            {'title': 'Medium Impact', 'impact_score': 0.6},
          ],
          cleanupSuggestions: [
            {'title': 'Very High Impact', 'impact_score': 0.95},
          ],
        );

        final topOptimizations = analytics.topOptimizations;
        
        expect(topOptimizations, hasLength(4));
        
        // Should be sorted by impact score (descending)
        expect(topOptimizations.first['title'], equals('Very High Impact'));
        expect(topOptimizations.last['title'], equals('Low Impact'));
      });
    });

    group('EnhancedProgressUpdate', () {
      test('should calculate operation health score correctly', () {
        final progress = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: DateTime.now(),
          completedOperations: 80,
          totalOperations: 100,
          percentage: 0.8,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 10),
          operationsPerSecond: 2.0,
          bytesPerSecond: 1024 * 1024, // 1MB/s
          processedBytes: 80 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.95,
          errorCount: 2,
          cpuUsage: 0.5,
          memoryUsage: 0.6,
          diskIOUsage: 0.7,
          isOptimized: true,
          currentStage: 'executing',
        );

        final healthScore = progress.operationHealthScore;
        
        // Base: 0.95
        // Error penalty: (2 / 81) * 0.3 ≈ 0.007
        // No resource penalty (all < 0.9)
        // Optimization boost: 0.1
        // Expected: 0.95 - 0.007 + 0.1 ≈ 1.043, clamped to 1.0
        expect(healthScore, equals(1.0));
      });

      test('should detect when operation needs attention', () {
        final progress = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: DateTime.now(),
          completedOperations: 50,
          totalOperations: 100,
          percentage: 0.5,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 5),
          operationsPerSecond: 2.0,
          bytesPerSecond: 1024 * 1024,
          processedBytes: 50 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.9,
          errorCount: 0,
          cpuUsage: 0.97, // High CPU usage
          memoryUsage: 0.5,
          diskIOUsage: 0.5,
          isOptimized: true,
          currentStage: 'executing',
        );

        expect(progress.needsAttention, isTrue);

        final healthyProgress = progress.copyWith(
          cpuUsage: 0.5,
          errorCount: 0,
          status: OperationStatus.executing,
          isOptimized: true,
        );

        expect(healthyProgress.needsAttention, isFalse);
      });

      test('should provide appropriate status descriptions', () {
        final baseProgress = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: DateTime.now(),
          completedOperations: 50,
          totalOperations: 100,
          percentage: 0.5,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 5),
          operationsPerSecond: 2.0,
          bytesPerSecond: 1024 * 1024,
          processedBytes: 50 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.9,
          currentStage: 'executing',
        );

        expect(
          baseProgress.statusDescription,
          equals('Organizing files (50/100)...'),
        );

        final analyzingProgress = baseProgress.copyWith(
          status: OperationStatus.analyzing,
        );

        expect(
          analyzingProgress.statusDescription,
          equals('Analyzing files and planning operations...'),
        );

        final completedProgress = baseProgress.copyWith(
          status: OperationStatus.completed,
        );

        expect(
          completedProgress.statusDescription,
          equals('File organization completed successfully'),
        );
      });

      test('should calculate estimated completion time', () {
        final now = DateTime.now();
        final progress = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: now,
          completedOperations: 50,
          totalOperations: 100,
          percentage: 0.5,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 5),
          estimatedRemaining: Duration(minutes: 10),
          operationsPerSecond: 2.0,
          bytesPerSecond: 1024 * 1024,
          processedBytes: 50 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.9,
          currentStage: 'executing',
        );

        final completionTime = progress.estimatedCompletionTime;
        expect(completionTime, equals(now.add(Duration(minutes: 10))));

        final progressWithoutEstimate = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: now,
          completedOperations: 50,
          totalOperations: 100,
          percentage: 0.5,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 5),
          estimatedRemaining: null, // No estimate
          operationsPerSecond: 2.0,
          bytesPerSecond: 1024 * 1024,
          processedBytes: 50 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.9,
          currentStage: 'executing',
        );

        expect(progressWithoutEstimate.estimatedCompletionTime, isNull);
      });

      test('should generate performance summary', () {
        final progress = EnhancedProgressUpdate(
          operationId: 'op_001',
          sessionId: 'session_001',
          timestamp: DateTime.now(),
          completedOperations: 80,
          totalOperations: 100,
          percentage: 0.8,
          currentFile: 'current.txt',
          currentOperation: 'Moving file',
          status: OperationStatus.executing,
          elapsed: Duration(minutes: 10),
          operationsPerSecond: 2.5,
          bytesPerSecond: 2 * 1024 * 1024, // 2MB/s
          processedBytes: 80 * 1024 * 1024,
          totalBytes: 100 * 1024 * 1024,
          successRate: 0.95,
          errorCount: 1,
          cpuUsage: 0.6,
          memoryUsage: 0.4,
          diskIOUsage: 0.8,
          currentStage: 'executing',
        );

        final summary = progress.performanceSummary;

        expect(summary['operations_per_second'], equals(2.5));
        expect(summary['transfer_rate'], equals('2.0 MB/s'));
        expect(summary['cpu_usage'], equals('60%'));
        expect(summary['memory_usage'], equals('40%'));
        expect(summary['disk_io_usage'], equals('80%'));
        expect(summary['success_rate'], equals('95%'));
        expect(summary['error_rate'], equals('1%')); // 1/81 ≈ 1%
        expect(summary['health_score'], isA<double>());
      });
    });
  });
}

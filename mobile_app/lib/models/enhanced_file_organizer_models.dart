import 'package:flutter/foundation.dart';

/// Enhanced data models for intelligent file organization
/// Task 5.1: Comprehensive data models with advanced features

// ====================================
// ENHANCED ENUMS
// ====================================

enum OrganizationStyle { 
  smartCategories, 
  byType, 
  byDate, 
  custom, 
  byProject,
  byPriority,
  hybrid
}

enum OperationStatus { 
  idle, 
  analyzing, 
  executing, 
  paused, 
  completed, 
  error, 
  cancelled,
  queued,
  preparing,
  verifying,
  rollback
}

enum FileOperationType { 
  move, 
  copy, 
  delete, 
  rename, 
  createFolder,
  compress,
  decompress,
  merge,
  split
}

enum RiskLevel {
  veryLow,
  low,
  medium,
  high,
  critical
}

enum DriveHealth {
  excellent,
  good,
  fair,
  poor,
  critical,
  unknown
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
  fatal
}

enum ConflictType {
  nameCollision,
  permissionDenied,
  diskSpaceInsufficient,
  pathTooLong,
  fileInUse,
  typeNotSupported
}

// ====================================
// ENHANCED CONFIDENCE AND RISK MODELS
// ====================================

/// Multi-factor confidence assessment for AI operations
class ConfidenceMetrics {
  final double overall; // 0.0 - 1.0
  final double patternMatch; // How well it matches learned patterns
  final double userHistoryAlignment; // Alignment with user's past choices
  final double contextualRelevance; // Relevance to current context
  final double aiCertainty; // AI model's internal confidence
  final List<String> contributingFactors;
  final List<String> uncertaintyFactors;

  const ConfidenceMetrics({
    required this.overall,
    required this.patternMatch,
    required this.userHistoryAlignment,
    required this.contextualRelevance,
    required this.aiCertainty,
    this.contributingFactors = const [],
    this.uncertaintyFactors = const [],
  });

  factory ConfidenceMetrics.fromSimple(double confidence) {
    return ConfidenceMetrics(
      overall: confidence,
      patternMatch: confidence,
      userHistoryAlignment: confidence,
      contextualRelevance: confidence,
      aiCertainty: confidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'pattern_match': patternMatch,
    'user_history_alignment': userHistoryAlignment,
    'contextual_relevance': contextualRelevance,
    'ai_certainty': aiCertainty,
    'contributing_factors': contributingFactors,
    'uncertainty_factors': uncertaintyFactors,
  };

  factory ConfidenceMetrics.fromJson(Map<String, dynamic> json) {
    return ConfidenceMetrics(
      overall: json['overall']?.toDouble() ?? 0.0,
      patternMatch: json['pattern_match']?.toDouble() ?? 0.0,
      userHistoryAlignment: json['user_history_alignment']?.toDouble() ?? 0.0,
      contextualRelevance: json['contextual_relevance']?.toDouble() ?? 0.0,
      aiCertainty: json['ai_certainty']?.toDouble() ?? 0.0,
      contributingFactors: List<String>.from(json['contributing_factors'] ?? []),
      uncertaintyFactors: List<String>.from(json['uncertainty_factors'] ?? []),
    );
  }
}

/// Risk assessment for file operations
class RiskAssessment {
  final RiskLevel level;
  final double score; // 0.0 (safe) - 1.0 (dangerous)
  final List<String> risks;
  final List<String> mitigations;
  final bool requiresConfirmation;
  final bool isReversible;
  final Duration estimatedRecoveryTime;

  const RiskAssessment({
    required this.level,
    required this.score,
    this.risks = const [],
    this.mitigations = const [],
    required this.requiresConfirmation,
    required this.isReversible,
    required this.estimatedRecoveryTime,
  });

  factory RiskAssessment.low() {
    return const RiskAssessment(
      level: RiskLevel.low,
      score: 0.2,
      requiresConfirmation: false,
      isReversible: true,
      estimatedRecoveryTime: Duration(seconds: 5),
    );
  }

  factory RiskAssessment.medium() {
    return const RiskAssessment(
      level: RiskLevel.medium,
      score: 0.5,
      requiresConfirmation: true,
      isReversible: true,
      estimatedRecoveryTime: Duration(minutes: 2),
    );
  }

  factory RiskAssessment.high() {
    return const RiskAssessment(
      level: RiskLevel.high,
      score: 0.8,
      requiresConfirmation: true,
      isReversible: false,
      estimatedRecoveryTime: Duration(minutes: 30),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level.toString(),
    'score': score,
    'risks': risks,
    'mitigations': mitigations,
    'requires_confirmation': requiresConfirmation,
    'is_reversible': isReversible,
    'estimated_recovery_time': estimatedRecoveryTime.inSeconds,
  };

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      level: RiskLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => RiskLevel.medium,
      ),
      score: json['score']?.toDouble() ?? 0.5,
      risks: List<String>.from(json['risks'] ?? []),
      mitigations: List<String>.from(json['mitigations'] ?? []),
      requiresConfirmation: json['requires_confirmation'] ?? false,
      isReversible: json['is_reversible'] ?? true,
      estimatedRecoveryTime: Duration(seconds: json['estimated_recovery_time'] ?? 0),
    );
  }
}

/// Enhanced AI reasoning with detailed explanations
class AIReasoning {
  final String primaryReason;
  final List<String> supportingReasons;
  final List<String> alternativeOptions;
  final Map<String, dynamic> analysisData;
  final List<String> userBenefits;
  final double reasoningConfidence;

  const AIReasoning({
    required this.primaryReason,
    this.supportingReasons = const [],
    this.alternativeOptions = const [],
    this.analysisData = const {},
    this.userBenefits = const [],
    required this.reasoningConfidence,
  });

  Map<String, dynamic> toJson() => {
    'primary_reason': primaryReason,
    'supporting_reasons': supportingReasons,
    'alternative_options': alternativeOptions,
    'analysis_data': analysisData,
    'user_benefits': userBenefits,
    'reasoning_confidence': reasoningConfidence,
  };

  factory AIReasoning.fromJson(Map<String, dynamic> json) {
    return AIReasoning(
      primaryReason: json['primary_reason'] ?? '',
      supportingReasons: List<String>.from(json['supporting_reasons'] ?? []),
      alternativeOptions: List<String>.from(json['alternative_options'] ?? []),
      analysisData: Map<String, dynamic>.from(json['analysis_data'] ?? {}),
      userBenefits: List<String>.from(json['user_benefits'] ?? []),
      reasoningConfidence: json['reasoning_confidence']?.toDouble() ?? 0.0,
    );
  }
}

// ====================================
// ENHANCED FILE OPERATION MODEL
// ====================================

/// Enhanced file operation with advanced capabilities
class EnhancedFileOperation {
  final String id;
  final FileOperationType type;
  final String sourcePath;
  final String? destinationPath;
  final String? newFolderName;
  
  // Enhanced confidence and risk assessment
  final ConfidenceMetrics confidence;
  final RiskAssessment risk;
  final AIReasoning reasoning;
  
  // Operation dependencies and relationships
  final List<String> dependsOn; // IDs of operations this depends on
  final List<String> enables; // IDs of operations this enables
  final int priority; // 1 (highest) to 10 (lowest)
  
  // Progress and status tracking
  final OperationStatus status;
  final double progressPercentage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? actualDuration;
  
  // User interaction
  final bool isApproved;
  final bool isRejected;
  final String? userNote;
  final Map<String, dynamic> userModifications;
  
  // Rollback and recovery
  final bool supportsRollback;
  final Map<String, dynamic>? rollbackData;
  final List<String> rollbackInstructions;
  
  // File metadata and impact
  final Map<String, dynamic> sourceMetadata;
  final Map<String, dynamic>? destinationMetadata;
  final int estimatedSize;
  final Duration estimatedTime;
  final Map<String, dynamic> impactAnalysis;
  
  // Tags and categorization
  final List<String> tags;
  final List<String> categories;
  final Map<String, dynamic> customProperties;

  const EnhancedFileOperation({
    required this.id,
    required this.type,
    required this.sourcePath,
    this.destinationPath,
    this.newFolderName,
    required this.confidence,
    required this.risk,
    required this.reasoning,
    this.dependsOn = const [],
    this.enables = const [],
    this.priority = 5,
    this.status = OperationStatus.queued,
    this.progressPercentage = 0.0,
    this.startedAt,
    this.completedAt,
    this.actualDuration,
    this.isApproved = false,
    this.isRejected = false,
    this.userNote,
    this.userModifications = const {},
    this.supportsRollback = true,
    this.rollbackData,
    this.rollbackInstructions = const [],
    this.sourceMetadata = const {},
    this.destinationMetadata,
    required this.estimatedSize,
    required this.estimatedTime,
    this.impactAnalysis = const {},
    this.tags = const [],
    this.categories = const [],
    this.customProperties = const {},
  });

  /// Create a copy with modified fields
  EnhancedFileOperation copyWith({
    String? id,
    FileOperationType? type,
    String? sourcePath,
    String? destinationPath,
    String? newFolderName,
    ConfidenceMetrics? confidence,
    RiskAssessment? risk,
    AIReasoning? reasoning,
    List<String>? dependsOn,
    List<String>? enables,
    int? priority,
    OperationStatus? status,
    double? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? actualDuration,
    bool? isApproved,
    bool? isRejected,
    String? userNote,
    Map<String, dynamic>? userModifications,
    bool? supportsRollback,
    Map<String, dynamic>? rollbackData,
    List<String>? rollbackInstructions,
    Map<String, dynamic>? sourceMetadata,
    Map<String, dynamic>? destinationMetadata,
    int? estimatedSize,
    Duration? estimatedTime,
    Map<String, dynamic>? impactAnalysis,
    List<String>? tags,
    List<String>? categories,
    Map<String, dynamic>? customProperties,
  }) {
    return EnhancedFileOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath ?? this.destinationPath,
      newFolderName: newFolderName ?? this.newFolderName,
      confidence: confidence ?? this.confidence,
      risk: risk ?? this.risk,
      reasoning: reasoning ?? this.reasoning,
      dependsOn: dependsOn ?? this.dependsOn,
      enables: enables ?? this.enables,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      actualDuration: actualDuration ?? this.actualDuration,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      userNote: userNote ?? this.userNote,
      userModifications: userModifications ?? this.userModifications,
      supportsRollback: supportsRollback ?? this.supportsRollback,
      rollbackData: rollbackData ?? this.rollbackData,
      rollbackInstructions: rollbackInstructions ?? this.rollbackInstructions,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      destinationMetadata: destinationMetadata ?? this.destinationMetadata,
      estimatedSize: estimatedSize ?? this.estimatedSize,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      impactAnalysis: impactAnalysis ?? this.impactAnalysis,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      customProperties: customProperties ?? this.customProperties,
    );
  }

  /// Convert to JSON for API communication
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'source_path': sourcePath,
    'destination_path': destinationPath,
    'new_folder_name': newFolderName,
    'confidence': confidence.toJson(),
    'risk': risk.toJson(),
    'reasoning': reasoning.toJson(),
    'depends_on': dependsOn,
    'enables': enables,
    'priority': priority,
    'status': status.toString(),
    'progress_percentage': progressPercentage,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'actual_duration': actualDuration?.inSeconds,
    'is_approved': isApproved,
    'is_rejected': isRejected,
    'user_note': userNote,
    'user_modifications': userModifications,
    'supports_rollback': supportsRollback,
    'rollback_data': rollbackData,
    'rollback_instructions': rollbackInstructions,
    'source_metadata': sourceMetadata,
    'destination_metadata': destinationMetadata,
    'estimated_size': estimatedSize,
    'estimated_time': estimatedTime.inSeconds,
    'impact_analysis': impactAnalysis,
    'tags': tags,
    'categories': categories,
    'custom_properties': customProperties,
  };

  /// Create from JSON
  factory EnhancedFileOperation.fromJson(Map<String, dynamic> json) {
    return EnhancedFileOperation(
      id: json['id'] ?? '',
      type: FileOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => FileOperationType.move,
      ),
      sourcePath: json['source_path'] ?? '',
      destinationPath: json['destination_path'],
      newFolderName: json['new_folder_name'],
      confidence: json['confidence'] != null 
        ? ConfidenceMetrics.fromJson(json['confidence'])
        : ConfidenceMetrics.fromSimple(0.5),
      risk: json['risk'] != null 
        ? RiskAssessment.fromJson(json['risk'])
        : RiskAssessment.low(),
      reasoning: json['reasoning'] != null 
        ? AIReasoning.fromJson(json['reasoning'])
        : const AIReasoning(primaryReason: '', reasoningConfidence: 0.5),
      dependsOn: List<String>.from(json['depends_on'] ?? []),
      enables: List<String>.from(json['enables'] ?? []),
      priority: json['priority'] ?? 5,
      status: OperationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OperationStatus.queued,
      ),
      progressPercentage: json['progress_percentage']?.toDouble() ?? 0.0,
      startedAt: json['started_at'] != null 
        ? DateTime.parse(json['started_at'])
        : null,
      completedAt: json['completed_at'] != null 
        ? DateTime.parse(json['completed_at'])
        : null,
      actualDuration: json['actual_duration'] != null 
        ? Duration(seconds: json['actual_duration'])
        : null,
      isApproved: json['is_approved'] ?? false,
      isRejected: json['is_rejected'] ?? false,
      userNote: json['user_note'],
      userModifications: Map<String, dynamic>.from(json['user_modifications'] ?? {}),
      supportsRollback: json['supports_rollback'] ?? true,
      rollbackData: json['rollback_data'] != null 
        ? Map<String, dynamic>.from(json['rollback_data'])
        : null,
      rollbackInstructions: List<String>.from(json['rollback_instructions'] ?? []),
      sourceMetadata: Map<String, dynamic>.from(json['source_metadata'] ?? {}),
      destinationMetadata: json['destination_metadata'] != null 
        ? Map<String, dynamic>.from(json['destination_metadata'])
        : null,
      estimatedSize: json['estimated_size'] ?? 0,
      estimatedTime: Duration(seconds: json['estimated_time'] ?? 0),
      impactAnalysis: Map<String, dynamic>.from(json['impact_analysis'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      customProperties: Map<String, dynamic>.from(json['custom_properties'] ?? {}),
    );
  }

  /// Get operation complexity score (for scheduling and estimation)
  double get complexityScore {
    double score = 1.0;
    
    // Type complexity
    switch (type) {
      case FileOperationType.move:
        score += 1.0;
        break;
      case FileOperationType.copy:
        score += 1.5;
        break;
      case FileOperationType.delete:
        score += 0.5;
        break;
      case FileOperationType.compress:
        score += 3.0;
        break;
      case FileOperationType.merge:
        score += 2.5;
        break;
      default:
        score += 1.0;
    }
    
    // Size complexity
    score += (estimatedSize / (1024 * 1024)).clamp(0.0, 5.0); // MB to complexity
    
    // Risk complexity
    score += risk.score * 2.0;
    
    // Dependencies complexity
    score += dependsOn.length * 0.5;
    
    return score;
  }

  /// Check if operation is ready to execute
  bool get isReadyToExecute {
    return isApproved && 
           !isRejected && 
           status == OperationStatus.queued &&
           dependsOn.isEmpty; // All dependencies resolved
  }

  /// Get human-readable description
  String get description {
    switch (type) {
      case FileOperationType.move:
        return 'Move ${sourcePath.split('/').last} to ${destinationPath ?? 'destination'}';
      case FileOperationType.copy:
        return 'Copy ${sourcePath.split('/').last} to ${destinationPath ?? 'destination'}';
      case FileOperationType.delete:
        return 'Delete ${sourcePath.split('/').last}';
      case FileOperationType.rename:
        return 'Rename ${sourcePath.split('/').last} to ${newFolderName ?? 'new name'}';
      case FileOperationType.createFolder:
        return 'Create folder ${newFolderName ?? 'new folder'}';
      case FileOperationType.compress:
        return 'Compress ${sourcePath.split('/').last}';
      case FileOperationType.decompress:
        return 'Decompress ${sourcePath.split('/').last}';
      case FileOperationType.merge:
        return 'Merge files into ${destinationPath ?? 'destination'}';
      case FileOperationType.split:
        return 'Split ${sourcePath.split('/').last}';
    }
  }
}

// ====================================
// ENHANCED DRIVE INFO MODEL
// ====================================

/// Drive health metrics and monitoring
class DriveHealthMetrics {
  final DriveHealth overall;
  final double temperature; // Celsius
  final int powerOnHours;
  final int errorCount;
  final double readWriteSpeed; // MB/s
  final List<String> smartWarnings;
  final DateTime lastHealthCheck;
  final Map<String, dynamic> smartData;

  const DriveHealthMetrics({
    required this.overall,
    required this.temperature,
    required this.powerOnHours,
    required this.errorCount,
    required this.readWriteSpeed,
    this.smartWarnings = const [],
    required this.lastHealthCheck,
    this.smartData = const {},
  });

  factory DriveHealthMetrics.unknown() {
    return DriveHealthMetrics(
      overall: DriveHealth.unknown,
      temperature: 0.0,
      powerOnHours: 0,
      errorCount: 0,
      readWriteSpeed: 0.0,
      lastHealthCheck: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'overall': overall.toString(),
    'temperature': temperature,
    'power_on_hours': powerOnHours,
    'error_count': errorCount,
    'read_write_speed': readWriteSpeed,
    'smart_warnings': smartWarnings,
    'last_health_check': lastHealthCheck.toIso8601String(),
    'smart_data': smartData,
  };

  factory DriveHealthMetrics.fromJson(Map<String, dynamic> json) {
    return DriveHealthMetrics(
      overall: DriveHealth.values.firstWhere(
        (e) => e.toString() == json['overall'],
        orElse: () => DriveHealth.unknown,
      ),
      temperature: json['temperature']?.toDouble() ?? 0.0,
      powerOnHours: json['power_on_hours'] ?? 0,
      errorCount: json['error_count'] ?? 0,
      readWriteSpeed: json['read_write_speed']?.toDouble() ?? 0.0,
      smartWarnings: List<String>.from(json['smart_warnings'] ?? []),
      lastHealthCheck: json['last_health_check'] != null 
        ? DateTime.parse(json['last_health_check'])
        : DateTime.now(),
      smartData: Map<String, dynamic>.from(json['smart_data'] ?? {}),
    );
  }
}

/// Drive usage patterns and analytics
class DriveUsagePatterns {
  final List<Map<String, dynamic>> hourlyUsage; // Usage by hour of day
  final List<Map<String, dynamic>> dailyUsage; // Usage by day of week
  final List<Map<String, dynamic>> monthlyTrends; // Usage trends over months
  final double averageUtilization; // 0.0 - 1.0
  final Map<String, int> fileTypeDistribution;
  final List<String> commonFolders;
  final DateTime analysisDate;
  final Map<String, dynamic> recommendations;

  const DriveUsagePatterns({
    this.hourlyUsage = const [],
    this.dailyUsage = const [],
    this.monthlyTrends = const [],
    required this.averageUtilization,
    this.fileTypeDistribution = const {},
    this.commonFolders = const [],
    required this.analysisDate,
    this.recommendations = const {},
  });

  Map<String, dynamic> toJson() => {
    'hourly_usage': hourlyUsage,
    'daily_usage': dailyUsage,
    'monthly_trends': monthlyTrends,
    'average_utilization': averageUtilization,
    'file_type_distribution': fileTypeDistribution,
    'common_folders': commonFolders,
    'analysis_date': analysisDate.toIso8601String(),
    'recommendations': recommendations,
  };

  factory DriveUsagePatterns.fromJson(Map<String, dynamic> json) {
    return DriveUsagePatterns(
      hourlyUsage: List<Map<String, dynamic>>.from(json['hourly_usage'] ?? []),
      dailyUsage: List<Map<String, dynamic>>.from(json['daily_usage'] ?? []),
      monthlyTrends: List<Map<String, dynamic>>.from(json['monthly_trends'] ?? []),
      averageUtilization: json['average_utilization']?.toDouble() ?? 0.0,
      fileTypeDistribution: Map<String, int>.from(json['file_type_distribution'] ?? {}),
      commonFolders: List<String>.from(json['common_folders'] ?? []),
      analysisDate: json['analysis_date'] != null 
        ? DateTime.parse(json['analysis_date'])
        : DateTime.now(),
      recommendations: Map<String, dynamic>.from(json['recommendations'] ?? {}),
    );
  }
}

/// Enhanced drive information with health monitoring and usage patterns
class EnhancedDriveInfo {
  final String path;
  final String name;
  final String type; // USB, HDD, SSD, Network, Cloud
  final String? model;
  final String? serialNumber;
  
  // Space and capacity
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;
  final double utilizationPercentage;
  
  // Connection and availability
  final bool isConnected;
  final DateTime? lastSeen;
  final Duration? averageConnectionTime;
  final int connectionCount;
  
  // Health and performance
  final DriveHealthMetrics health;
  final DriveUsagePatterns usagePatterns;
  
  // Organization and purpose
  final String? purpose; // backup, work, media, archive, temp
  final List<String> purposes; // Multiple purposes
  final Map<String, String> folderPurposes; // folder -> purpose mapping
  
  // Intelligence and recommendations
  final double organizationScore; // 0.0 (messy) - 1.0 (well organized)
  final List<String> optimizationSuggestions;
  final Map<String, dynamic> insights;
  final DateTime lastAnalyzed;
  
  // User preferences and settings
  final bool autoOrganizeEnabled;
  final Map<String, dynamic> organizationRules;
  final List<String> favoriteLocations;
  final Map<String, dynamic> userPreferences;

  const EnhancedDriveInfo({
    required this.path,
    required this.name,
    required this.type,
    this.model,
    this.serialNumber,
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
    required this.utilizationPercentage,
    required this.isConnected,
    this.lastSeen,
    this.averageConnectionTime,
    this.connectionCount = 0,
    required this.health,
    required this.usagePatterns,
    this.purpose,
    this.purposes = const [],
    this.folderPurposes = const {},
    required this.organizationScore,
    this.optimizationSuggestions = const [],
    this.insights = const {},
    required this.lastAnalyzed,
    this.autoOrganizeEnabled = false,
    this.organizationRules = const {},
    this.favoriteLocations = const [],
    this.userPreferences = const {},
  });

  /// Create a copy with modified fields
  EnhancedDriveInfo copyWith({
    String? path,
    String? name,
    String? type,
    String? model,
    String? serialNumber,
    int? totalSpace,
    int? freeSpace,
    int? usedSpace,
    double? utilizationPercentage,
    bool? isConnected,
    DateTime? lastSeen,
    Duration? averageConnectionTime,
    int? connectionCount,
    DriveHealthMetrics? health,
    DriveUsagePatterns? usagePatterns,
    String? purpose,
    List<String>? purposes,
    Map<String, String>? folderPurposes,
    double? organizationScore,
    List<String>? optimizationSuggestions,
    Map<String, dynamic>? insights,
    DateTime? lastAnalyzed,
    bool? autoOrganizeEnabled,
    Map<String, dynamic>? organizationRules,
    List<String>? favoriteLocations,
    Map<String, dynamic>? userPreferences,
  }) {
    return EnhancedDriveInfo(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      totalSpace: totalSpace ?? this.totalSpace,
      freeSpace: freeSpace ?? this.freeSpace,
      usedSpace: usedSpace ?? this.usedSpace,
      utilizationPercentage: utilizationPercentage ?? this.utilizationPercentage,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
      averageConnectionTime: averageConnectionTime ?? this.averageConnectionTime,
      connectionCount: connectionCount ?? this.connectionCount,
      health: health ?? this.health,
      usagePatterns: usagePatterns ?? this.usagePatterns,
      purpose: purpose ?? this.purpose,
      purposes: purposes ?? this.purposes,
      folderPurposes: folderPurposes ?? this.folderPurposes,
      organizationScore: organizationScore ?? this.organizationScore,
      optimizationSuggestions: optimizationSuggestions ?? this.optimizationSuggestions,
      insights: insights ?? this.insights,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      autoOrganizeEnabled: autoOrganizeEnabled ?? this.autoOrganizeEnabled,
      organizationRules: organizationRules ?? this.organizationRules,
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'type': type,
    'model': model,
    'serial_number': serialNumber,
    'total_space': totalSpace,
    'free_space': freeSpace,
    'used_space': usedSpace,
    'utilization_percentage': utilizationPercentage,
    'is_connected': isConnected,
    'last_seen': lastSeen?.toIso8601String(),
    'average_connection_time': averageConnectionTime?.inSeconds,
    'connection_count': connectionCount,
    'health': health.toJson(),
    'usage_patterns': usagePatterns.toJson(),
    'purpose': purpose,
    'purposes': purposes,
    'folder_purposes': folderPurposes,
    'organization_score': organizationScore,
    'optimization_suggestions': optimizationSuggestions,
    'insights': insights,
    'last_analyzed': lastAnalyzed.toIso8601String(),
    'auto_organize_enabled': autoOrganizeEnabled,
    'organization_rules': organizationRules,
    'favorite_locations': favoriteLocations,
    'user_preferences': userPreferences,
  };

  /// Create from JSON
  factory EnhancedDriveInfo.fromJson(Map<String, dynamic> json) {
    return EnhancedDriveInfo(
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Unknown',
      model: json['model'],
      serialNumber: json['serial_number'],
      totalSpace: json['total_space'] ?? 0,
      freeSpace: json['free_space'] ?? 0,
      usedSpace: json['used_space'] ?? 0,
      utilizationPercentage: json['utilization_percentage']?.toDouble() ?? 0.0,
      isConnected: json['is_connected'] ?? false,
      lastSeen: json['last_seen'] != null 
        ? DateTime.parse(json['last_seen'])
        : null,
      averageConnectionTime: json['average_connection_time'] != null 
        ? Duration(seconds: json['average_connection_time'])
        : null,
      connectionCount: json['connection_count'] ?? 0,
      health: json['health'] != null 
        ? DriveHealthMetrics.fromJson(json['health'])
        : DriveHealthMetrics.unknown(),
      usagePatterns: json['usage_patterns'] != null 
        ? DriveUsagePatterns.fromJson(json['usage_patterns'])
        : DriveUsagePatterns(
            averageUtilization: 0.0,
            analysisDate: DateTime.now(),
          ),
      purpose: json['purpose'],
      purposes: List<String>.from(json['purposes'] ?? []),
      folderPurposes: Map<String, String>.from(json['folder_purposes'] ?? {}),
      organizationScore: json['organization_score']?.toDouble() ?? 0.0,
      optimizationSuggestions: List<String>.from(json['optimization_suggestions'] ?? []),
      insights: Map<String, dynamic>.from(json['insights'] ?? {}),
      lastAnalyzed: json['last_analyzed'] != null 
        ? DateTime.parse(json['last_analyzed'])
        : DateTime.now(),
      autoOrganizeEnabled: json['auto_organize_enabled'] ?? false,
      organizationRules: Map<String, dynamic>.from(json['organization_rules'] ?? {}),
      favoriteLocations: List<String>.from(json['favorite_locations'] ?? []),
      userPreferences: Map<String, dynamic>.from(json['user_preferences'] ?? {}),
    );
  }

  /// Get space utilization status
  String get spaceStatus {
    if (utilizationPercentage < 0.5) return 'Plenty of space';
    if (utilizationPercentage < 0.75) return 'Moderate usage';
    if (utilizationPercentage < 0.9) return 'High usage';
    if (utilizationPercentage < 0.95) return 'Nearly full';
    return 'Critical - drive full';
  }

  /// Get health status color indicator
  String get healthColor {
    switch (health.overall) {
      case DriveHealth.excellent:
        return 'green';
      case DriveHealth.good:
        return 'lightgreen';
      case DriveHealth.fair:
        return 'yellow';
      case DriveHealth.poor:
        return 'orange';
      case DriveHealth.critical:
        return 'red';
      case DriveHealth.unknown:
        return 'grey';
    }
  }

  /// Check if drive needs attention
  bool get needsAttention {
    return utilizationPercentage > 0.9 ||
           health.overall == DriveHealth.poor ||
           health.overall == DriveHealth.critical ||
           health.smartWarnings.isNotEmpty ||
           organizationScore < 0.3;
  }

  /// Get primary recommendation
  String? get primaryRecommendation {
    if (utilizationPercentage > 0.95) {
      return 'Free up space - drive is nearly full';
    }
    if (health.overall == DriveHealth.critical) {
      return 'Backup data immediately - drive health critical';
    }
    if (organizationScore < 0.3) {
      return 'Consider organizing files for better structure';
    }
    if (health.smartWarnings.isNotEmpty) {
      return 'Check drive health - SMART warnings detected';
    }
    if (optimizationSuggestions.isNotEmpty) {
      return optimizationSuggestions.first;
    }
    return null;
  }
}

// ====================================
// ENHANCED ORGANIZATION PRESET MODEL
// ====================================

/// Enhanced organization preset with AI-powered relevance scoring
class EnhancedOrganizationPreset {
  final String id;
  final String name;
  final String description;
  final String intent;
  
  // Applicability and context
  final List<String> applicableFileTypes;
  final Map<String, String> folderStructure;
  final List<String> contextTags; // work, personal, media, etc.
  final Map<String, dynamic> targetCriteria; // when to suggest this preset
  
  // AI-powered scoring and learning
  final double staticRelevanceScore; // Initial relevance (0.0 - 1.0)
  final double dynamicRelevanceScore; // Learned relevance based on usage
  final double successRate; // How often this preset works well
  final int usageCount;
  final int successCount;
  final List<Map<String, dynamic>> usageHistory;
  
  // User interaction and feedback
  final bool isCustom;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final Map<String, int> userModifications; // track common modifications
  final List<String> userFeedback;
  final double userRating; // 1.0 - 5.0
  
  // Context awareness
  final Map<String, dynamic> optimalConditions; // when this works best
  final List<String> requiredFeatures; // features needed for this preset
  final Map<String, dynamic> performanceMetrics;
  final List<String> alternativePresets; // similar presets

  const EnhancedOrganizationPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.intent,
    this.applicableFileTypes = const [],
    this.folderStructure = const {},
    this.contextTags = const [],
    this.targetCriteria = const {},
    required this.staticRelevanceScore,
    required this.dynamicRelevanceScore,
    required this.successRate,
    this.usageCount = 0,
    this.successCount = 0,
    this.usageHistory = const [],
    required this.isCustom,
    this.isFavorite = false,
    required this.createdAt,
    this.lastUsed,
    this.userModifications = const {},
    this.userFeedback = const [],
    this.userRating = 0.0,
    this.optimalConditions = const {},
    this.requiredFeatures = const [],
    this.performanceMetrics = const {},
    this.alternativePresets = const [],
  });

  /// Create a copy with modified fields
  EnhancedOrganizationPreset copyWith({
    String? id,
    String? name,
    String? description,
    String? intent,
    List<String>? applicableFileTypes,
    Map<String, String>? folderStructure,
    List<String>? contextTags,
    Map<String, dynamic>? targetCriteria,
    double? staticRelevanceScore,
    double? dynamicRelevanceScore,
    double? successRate,
    int? usageCount,
    int? successCount,
    List<Map<String, dynamic>>? usageHistory,
    bool? isCustom,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastUsed,
    Map<String, int>? userModifications,
    List<String>? userFeedback,
    double? userRating,
    Map<String, dynamic>? optimalConditions,
    List<String>? requiredFeatures,
    Map<String, dynamic>? performanceMetrics,
    List<String>? alternativePresets,
  }) {
    return EnhancedOrganizationPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      intent: intent ?? this.intent,
      applicableFileTypes: applicableFileTypes ?? this.applicableFileTypes,
      folderStructure: folderStructure ?? this.folderStructure,
      contextTags: contextTags ?? this.contextTags,
      targetCriteria: targetCriteria ?? this.targetCriteria,
      staticRelevanceScore: staticRelevanceScore ?? this.staticRelevanceScore,
      dynamicRelevanceScore: dynamicRelevanceScore ?? this.dynamicRelevanceScore,
      successRate: successRate ?? this.successRate,
      usageCount: usageCount ?? this.usageCount,
      successCount: successCount ?? this.successCount,
      usageHistory: usageHistory ?? this.usageHistory,
      isCustom: isCustom ?? this.isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      userModifications: userModifications ?? this.userModifications,
      userFeedback: userFeedback ?? this.userFeedback,
      userRating: userRating ?? this.userRating,
      optimalConditions: optimalConditions ?? this.optimalConditions,
      requiredFeatures: requiredFeatures ?? this.requiredFeatures,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      alternativePresets: alternativePresets ?? this.alternativePresets,
    );
  }

  /// Calculate overall relevance score combining static and dynamic factors
  double get overallRelevanceScore {
    double base = (staticRelevanceScore + dynamicRelevanceScore) / 2.0;
    
    // Boost for success rate
    double successBoost = successRate * 0.2;
    
    // Boost for user rating
    double ratingBoost = (userRating / 5.0) * 0.1;
    
    // Boost for recent usage
    double recencyBoost = 0.0;
    if (lastUsed != null) {
      final daysSinceUsed = DateTime.now().difference(lastUsed!).inDays;
      if (daysSinceUsed < 7) recencyBoost = 0.1;
      else if (daysSinceUsed < 30) recencyBoost = 0.05;
    }
    
    // Penalty for low usage
    double usagePenalty = usageCount < 3 ? -0.1 : 0.0;
    
    return (base + successBoost + ratingBoost + recencyBoost + usagePenalty)
        .clamp(0.0, 1.0);
  }

  /// Check if preset is suitable for given context
  bool isSuitableFor(Map<String, dynamic> context) {
    // Check file types
    if (applicableFileTypes.isNotEmpty && context['file_types'] != null) {
      final contextFileTypes = List<String>.from(context['file_types']);
      final hasMatchingTypes = applicableFileTypes
          .any((type) => contextFileTypes.contains(type));
      if (!hasMatchingTypes) return false;
    }
    
    // Check context tags
    if (contextTags.isNotEmpty && context['tags'] != null) {
      final contextTagsList = List<String>.from(context['tags']);
      final hasMatchingTags = contextTags
          .any((tag) => contextTagsList.contains(tag));
      if (!hasMatchingTags) return false;
    }
    
    // Check target criteria
    for (final entry in targetCriteria.entries) {
      if (context[entry.key] != entry.value) return false;
    }
    
    return true;
  }

  /// Record usage and outcome
  EnhancedOrganizationPreset recordUsage({
    required bool wasSuccessful,
    Map<String, dynamic>? modifications,
    String? feedback,
    double? rating,
  }) {
    final newUsageCount = usageCount + 1;
    final newSuccessCount = wasSuccessful ? successCount + 1 : successCount;
    final newSuccessRate = newSuccessCount / newUsageCount;
    
    // Update user modifications tracking
    final updatedModifications = Map<String, int>.from(userModifications);
    if (modifications != null) {
      for (final key in modifications.keys) {
        updatedModifications[key] = (updatedModifications[key] ?? 0) + 1;
      }
    }
    
    // Update feedback
    final updatedFeedback = List<String>.from(userFeedback);
    if (feedback != null) {
      updatedFeedback.add(feedback);
    }
    
    // Update rating (weighted average)
    double newRating = userRating;
    if (rating != null) {
      newRating = usageCount == 0 
        ? rating 
        : ((userRating * usageCount) + rating) / newUsageCount;
    }
    
    // Add to usage history
    final updatedHistory = List<Map<String, dynamic>>.from(usageHistory);
    updatedHistory.add({
      'date': DateTime.now().toIso8601String(),
      'successful': wasSuccessful,
      'modifications': modifications,
      'feedback': feedback,
      'rating': rating,
    });
    
    // Keep only last 50 usage records
    if (updatedHistory.length > 50) {
      updatedHistory.removeRange(0, updatedHistory.length - 50);
    }
    
    return copyWith(
      usageCount: newUsageCount,
      successCount: newSuccessCount,
      successRate: newSuccessRate,
      lastUsed: DateTime.now(),
      userModifications: updatedModifications,
      userFeedback: updatedFeedback,
      userRating: newRating,
      usageHistory: updatedHistory,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'intent': intent,
    'applicable_file_types': applicableFileTypes,
    'folder_structure': folderStructure,
    'context_tags': contextTags,
    'target_criteria': targetCriteria,
    'static_relevance_score': staticRelevanceScore,
    'dynamic_relevance_score': dynamicRelevanceScore,
    'success_rate': successRate,
    'usage_count': usageCount,
    'success_count': successCount,
    'usage_history': usageHistory,
    'is_custom': isCustom,
    'is_favorite': isFavorite,
    'created_at': createdAt.toIso8601String(),
    'last_used': lastUsed?.toIso8601String(),
    'user_modifications': userModifications,
    'user_feedback': userFeedback,
    'user_rating': userRating,
    'optimal_conditions': optimalConditions,
    'required_features': requiredFeatures,
    'performance_metrics': performanceMetrics,
    'alternative_presets': alternativePresets,
  };

  /// Create from JSON
  factory EnhancedOrganizationPreset.fromJson(Map<String, dynamic> json) {
    return EnhancedOrganizationPreset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      intent: json['intent'] ?? '',
      applicableFileTypes: List<String>.from(json['applicable_file_types'] ?? []),
      folderStructure: Map<String, String>.from(json['folder_structure'] ?? {}),
      contextTags: List<String>.from(json['context_tags'] ?? []),
      targetCriteria: Map<String, dynamic>.from(json['target_criteria'] ?? {}),
      staticRelevanceScore: json['static_relevance_score']?.toDouble() ?? 0.0,
      dynamicRelevanceScore: json['dynamic_relevance_score']?.toDouble() ?? 0.0,
      successRate: json['success_rate']?.toDouble() ?? 0.0,
      usageCount: json['usage_count'] ?? 0,
      successCount: json['success_count'] ?? 0,
      usageHistory: List<Map<String, dynamic>>.from(json['usage_history'] ?? []),
      isCustom: json['is_custom'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      lastUsed: json['last_used'] != null 
        ? DateTime.parse(json['last_used'])
        : null,
      userModifications: Map<String, int>.from(json['user_modifications'] ?? {}),
      userFeedback: List<String>.from(json['user_feedback'] ?? []),
      userRating: json['user_rating']?.toDouble() ?? 0.0,
      optimalConditions: Map<String, dynamic>.from(json['optimal_conditions'] ?? {}),
      requiredFeatures: List<String>.from(json['required_features'] ?? []),
      performanceMetrics: Map<String, dynamic>.from(json['performance_metrics'] ?? {}),
      alternativePresets: List<String>.from(json['alternative_presets'] ?? []),
    );
  }
}

// ====================================
// ENHANCED FOLDER ANALYTICS MODEL
// ====================================

/// Comprehensive folder analytics with optimization insights
class EnhancedFolderAnalytics {
  final String path;
  final DateTime analyzedAt;
  
  // Basic metrics
  final int totalFiles;
  final int totalFolders;
  final int totalSize;
  final int depth; // folder nesting depth
  final Map<String, int> fileTypeDistribution;
  final Map<String, int> fileSizeDistribution; // size ranges
  final Map<String, int> fileAgeDistribution; // age ranges
  
  // Advanced insights
  final List<String> largestFiles;
  final List<String> duplicates;
  final List<String> emptyFolders;
  final List<String> deeplyNestedPaths;
  final List<String> unusedFiles; // not accessed recently
  final List<String> problematicFiles; // corrupted, inaccessible, etc.
  
  // Organization metrics
  final double organizationScore; // 0.0 (chaotic) - 1.0 (perfect)
  final Map<String, double> categoryScores; // scores by file type
  final List<String> organizationIssues;
  final Map<String, int> namingPatterns; // common naming patterns
  
  // Efficiency metrics
  final double spaceEfficiency; // how well space is used
  final double accessEfficiency; // how easy it is to find files
  final Map<String, dynamic> redundancyAnalysis; // duplicate content analysis
  final Map<String, dynamic> compressionPotential; // files that could be compressed
  
  // Recommendations and insights
  final List<Map<String, dynamic>> optimizationSuggestions;
  final List<Map<String, dynamic>> organizationSuggestions;
  final List<Map<String, dynamic>> cleanupSuggestions;
  final Map<String, dynamic> trendAnalysis; // how folder changed over time
  final Map<String, dynamic> predictiveInsights; // future growth predictions
  
  // Comparison and benchmarking
  final Map<String, dynamic>? comparisonBaseline; // compare with previous analysis
  final Map<String, dynamic> benchmarkData; // compare with similar folders
  final List<String> bestPractices; // relevant best practices

  const EnhancedFolderAnalytics({
    required this.path,
    required this.analyzedAt,
    required this.totalFiles,
    required this.totalFolders,
    required this.totalSize,
    required this.depth,
    this.fileTypeDistribution = const {},
    this.fileSizeDistribution = const {},
    this.fileAgeDistribution = const {},
    this.largestFiles = const [],
    this.duplicates = const [],
    this.emptyFolders = const [],
    this.deeplyNestedPaths = const [],
    this.unusedFiles = const [],
    this.problematicFiles = const [],
    required this.organizationScore,
    this.categoryScores = const {},
    this.organizationIssues = const [],
    this.namingPatterns = const {},
    required this.spaceEfficiency,
    required this.accessEfficiency,
    this.redundancyAnalysis = const {},
    this.compressionPotential = const {},
    this.optimizationSuggestions = const [],
    this.organizationSuggestions = const [],
    this.cleanupSuggestions = const [],
    this.trendAnalysis = const {},
    this.predictiveInsights = const {},
    this.comparisonBaseline,
    this.benchmarkData = const {},
    this.bestPractices = const [],
  });

  /// Create a copy with modified fields
  EnhancedFolderAnalytics copyWith({
    String? path,
    DateTime? analyzedAt,
    int? totalFiles,
    int? totalFolders,
    int? totalSize,
    int? depth,
    Map<String, int>? fileTypeDistribution,
    Map<String, int>? fileSizeDistribution,
    Map<String, int>? fileAgeDistribution,
    List<String>? largestFiles,
    List<String>? duplicates,
    List<String>? emptyFolders,
    List<String>? deeplyNestedPaths,
    List<String>? unusedFiles,
    List<String>? problematicFiles,
    double? organizationScore,
    Map<String, double>? categoryScores,
    List<String>? organizationIssues,
    Map<String, int>? namingPatterns,
    double? spaceEfficiency,
    double? accessEfficiency,
    Map<String, dynamic>? redundancyAnalysis,
    Map<String, dynamic>? compressionPotential,
    List<Map<String, dynamic>>? optimizationSuggestions,
    List<Map<String, dynamic>>? organizationSuggestions,
    List<Map<String, dynamic>>? cleanupSuggestions,
    Map<String, dynamic>? trendAnalysis,
    Map<String, dynamic>? predictiveInsights,
    Map<String, dynamic>? comparisonBaseline,
    Map<String, dynamic>? benchmarkData,
    List<String>? bestPractices,
  }) {
    return EnhancedFolderAnalytics(
      path: path ?? this.path,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      totalFiles: totalFiles ?? this.totalFiles,
      totalFolders: totalFolders ?? this.totalFolders,
      totalSize: totalSize ?? this.totalSize,
      depth: depth ?? this.depth,
      fileTypeDistribution: fileTypeDistribution ?? this.fileTypeDistribution,
      fileSizeDistribution: fileSizeDistribution ?? this.fileSizeDistribution,
      fileAgeDistribution: fileAgeDistribution ?? this.fileAgeDistribution,
      largestFiles: largestFiles ?? this.largestFiles,
      duplicates: duplicates ?? this.duplicates,
      emptyFolders: emptyFolders ?? this.emptyFolders,
      deeplyNestedPaths: deeplyNestedPaths ?? this.deeplyNestedPaths,
      unusedFiles: unusedFiles ?? this.unusedFiles,
      problematicFiles: problematicFiles ?? this.problematicFiles,
      organizationScore: organizationScore ?? this.organizationScore,
      categoryScores: categoryScores ?? this.categoryScores,
      organizationIssues: organizationIssues ?? this.organizationIssues,
      namingPatterns: namingPatterns ?? this.namingPatterns,
      spaceEfficiency: spaceEfficiency ?? this.spaceEfficiency,
      accessEfficiency: accessEfficiency ?? this.accessEfficiency,
      redundancyAnalysis: redundancyAnalysis ?? this.redundancyAnalysis,
      compressionPotential: compressionPotential ?? this.compressionPotential,
      optimizationSuggestions: optimizationSuggestions ?? this.optimizationSuggestions,
      organizationSuggestions: organizationSuggestions ?? this.organizationSuggestions,
      cleanupSuggestions: cleanupSuggestions ?? this.cleanupSuggestions,
      trendAnalysis: trendAnalysis ?? this.trendAnalysis,
      predictiveInsights: predictiveInsights ?? this.predictiveInsights,
      comparisonBaseline: comparisonBaseline ?? this.comparisonBaseline,
      benchmarkData: benchmarkData ?? this.benchmarkData,
      bestPractices: bestPractices ?? this.bestPractices,
    );
  }

  /// Get overall health score (combination of organization and efficiency)
  double get overallHealthScore {
    return (organizationScore + spaceEfficiency + accessEfficiency) / 3.0;
  }

  /// Get priority issues that need immediate attention
  List<Map<String, dynamic>> get priorityIssues {
    final issues = <Map<String, dynamic>>[];
    
    if (organizationScore < 0.3) {
      issues.add({
        'type': 'organization',
        'severity': 'high',
        'message': 'Folder is poorly organized',
        'suggestion': 'Consider reorganizing files by type or purpose'
      });
    }
    
    if (duplicates.length > totalFiles * 0.1) {
      issues.add({
        'type': 'duplicates',
        'severity': 'medium',
        'message': 'Many duplicate files found',
        'suggestion': 'Remove ${duplicates.length} duplicate files to save space'
      });
    }
    
    if (spaceEfficiency < 0.5) {
      issues.add({
        'type': 'space',
        'severity': 'medium',
        'message': 'Inefficient space usage',
        'suggestion': 'Compress or archive old files'
      });
    }
    
    if (depth > 8) {
      issues.add({
        'type': 'structure',
        'severity': 'low',
        'message': 'Folder structure is very deep',
        'suggestion': 'Flatten folder hierarchy for easier navigation'
      });
    }
    
    return issues;
  }

  /// Get top optimization suggestions sorted by impact
  List<Map<String, dynamic>> get topOptimizations {
    final allSuggestions = [
      ...optimizationSuggestions,
      ...organizationSuggestions,
      ...cleanupSuggestions,
    ];
    
    // Sort by impact score (descending)
    allSuggestions.sort((a, b) => 
      (b['impact_score'] ?? 0.0).compareTo(a['impact_score'] ?? 0.0));
    
    return allSuggestions.take(5).toList();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'path': path,
    'analyzed_at': analyzedAt.toIso8601String(),
    'total_files': totalFiles,
    'total_folders': totalFolders,
    'total_size': totalSize,
    'depth': depth,
    'file_type_distribution': fileTypeDistribution,
    'file_size_distribution': fileSizeDistribution,
    'file_age_distribution': fileAgeDistribution,
    'largest_files': largestFiles,
    'duplicates': duplicates,
    'empty_folders': emptyFolders,
    'deeply_nested_paths': deeplyNestedPaths,
    'unused_files': unusedFiles,
    'problematic_files': problematicFiles,
    'organization_score': organizationScore,
    'category_scores': categoryScores,
    'organization_issues': organizationIssues,
    'naming_patterns': namingPatterns,
    'space_efficiency': spaceEfficiency,
    'access_efficiency': accessEfficiency,
    'redundancy_analysis': redundancyAnalysis,
    'compression_potential': compressionPotential,
    'optimization_suggestions': optimizationSuggestions,
    'organization_suggestions': organizationSuggestions,
    'cleanup_suggestions': cleanupSuggestions,
    'trend_analysis': trendAnalysis,
    'predictive_insights': predictiveInsights,
    'comparison_baseline': comparisonBaseline,
    'benchmark_data': benchmarkData,
    'best_practices': bestPractices,
  };

  /// Create from JSON
  factory EnhancedFolderAnalytics.fromJson(Map<String, dynamic> json) {
    return EnhancedFolderAnalytics(
      path: json['path'] ?? '',
      analyzedAt: json['analyzed_at'] != null 
        ? DateTime.parse(json['analyzed_at'])
        : DateTime.now(),
      totalFiles: json['total_files'] ?? 0,
      totalFolders: json['total_folders'] ?? 0,
      totalSize: json['total_size'] ?? 0,
      depth: json['depth'] ?? 0,
      fileTypeDistribution: Map<String, int>.from(json['file_type_distribution'] ?? {}),
      fileSizeDistribution: Map<String, int>.from(json['file_size_distribution'] ?? {}),
      fileAgeDistribution: Map<String, int>.from(json['file_age_distribution'] ?? {}),
      largestFiles: List<String>.from(json['largest_files'] ?? []),
      duplicates: List<String>.from(json['duplicates'] ?? []),
      emptyFolders: List<String>.from(json['empty_folders'] ?? []),
      deeplyNestedPaths: List<String>.from(json['deeply_nested_paths'] ?? []),
      unusedFiles: List<String>.from(json['unused_files'] ?? []),
      problematicFiles: List<String>.from(json['problematic_files'] ?? []),
      organizationScore: json['organization_score']?.toDouble() ?? 0.0,
      categoryScores: Map<String, double>.from(json['category_scores'] ?? {}),
      organizationIssues: List<String>.from(json['organization_issues'] ?? []),
      namingPatterns: Map<String, int>.from(json['naming_patterns'] ?? {}),
      spaceEfficiency: json['space_efficiency']?.toDouble() ?? 0.0,
      accessEfficiency: json['access_efficiency']?.toDouble() ?? 0.0,
      redundancyAnalysis: Map<String, dynamic>.from(json['redundancy_analysis'] ?? {}),
      compressionPotential: Map<String, dynamic>.from(json['compression_potential'] ?? {}),
      optimizationSuggestions: List<Map<String, dynamic>>.from(json['optimization_suggestions'] ?? []),
      organizationSuggestions: List<Map<String, dynamic>>.from(json['organization_suggestions'] ?? []),
      cleanupSuggestions: List<Map<String, dynamic>>.from(json['cleanup_suggestions'] ?? []),
      trendAnalysis: Map<String, dynamic>.from(json['trend_analysis'] ?? {}),
      predictiveInsights: Map<String, dynamic>.from(json['predictive_insights'] ?? {}),
      comparisonBaseline: json['comparison_baseline'] != null 
        ? Map<String, dynamic>.from(json['comparison_baseline'])
        : null,
      benchmarkData: Map<String, dynamic>.from(json['benchmark_data'] ?? {}),
      bestPractices: List<String>.from(json['best_practices'] ?? []),
    );
  }
}

// ====================================
// ENHANCED PROGRESS UPDATE MODEL
// ====================================

/// Comprehensive progress tracking with performance monitoring
class EnhancedProgressUpdate {
  final String operationId;
  final String sessionId; // Group related operations
  final DateTime timestamp;
  
  // Basic progress metrics
  final int completedOperations;
  final int totalOperations;
  final double percentage;
  final String currentFile;
  final String currentOperation;
  final OperationStatus status;
  
  // Time and performance metrics
  final Duration elapsed;
  final Duration? estimatedRemaining;
  final Duration? totalEstimated;
  final double operationsPerSecond;
  final double bytesPerSecond;
  final int processedBytes;
  final int totalBytes;
  
  // Resource usage monitoring
  final double cpuUsage; // 0.0 - 1.0
  final double memoryUsage; // 0.0 - 1.0 (percentage of available)
  final double diskIOUsage; // 0.0 - 1.0
  final Map<String, dynamic> systemResources;
  
  // Error and issue tracking
  final int errorCount;
  final int warningCount;
  final List<String> recentErrors;
  final List<String> recentWarnings;
  final Map<String, int> errorTypes; // categorized error counts
  
  // Detailed operation stages
  final String currentStage; // analyzing, preparing, executing, verifying
  final List<String> completedStages;
  final Map<String, double> stageProgress; // progress per stage
  final Map<String, Duration> stageDurations;
  
  // Quality and success metrics
  final int successfulOperations;
  final int failedOperations;
  final int skippedOperations;
  final double successRate;
  final List<Map<String, dynamic>> operationResults;
  
  // User interaction and control
  final bool canPause;
  final bool canCancel;
  final bool canModify;
  final List<String> availableActions;
  final Map<String, dynamic> userControls;
  
  // Adaptive optimization
  final Map<String, dynamic> performanceHints;
  final List<String> optimizationSuggestions;
  final bool isOptimized; // whether operations are running optimally
  final Map<String, dynamic> adaptiveSettings;

  const EnhancedProgressUpdate({
    required this.operationId,
    required this.sessionId,
    required this.timestamp,
    required this.completedOperations,
    required this.totalOperations,
    required this.percentage,
    required this.currentFile,
    required this.currentOperation,
    required this.status,
    required this.elapsed,
    this.estimatedRemaining,
    this.totalEstimated,
    required this.operationsPerSecond,
    required this.bytesPerSecond,
    required this.processedBytes,
    required this.totalBytes,
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.diskIOUsage = 0.0,
    this.systemResources = const {},
    this.errorCount = 0,
    this.warningCount = 0,
    this.recentErrors = const [],
    this.recentWarnings = const [],
    this.errorTypes = const {},
    required this.currentStage,
    this.completedStages = const [],
    this.stageProgress = const {},
    this.stageDurations = const {},
    this.successfulOperations = 0,
    this.failedOperations = 0,
    this.skippedOperations = 0,
    required this.successRate,
    this.operationResults = const [],
    this.canPause = true,
    this.canCancel = true,
    this.canModify = false,
    this.availableActions = const [],
    this.userControls = const {},
    this.performanceHints = const {},
    this.optimizationSuggestions = const [],
    this.isOptimized = true,
    this.adaptiveSettings = const {},
  });

  /// Create a copy with modified fields
  EnhancedProgressUpdate copyWith({
    String? operationId,
    String? sessionId,
    DateTime? timestamp,
    int? completedOperations,
    int? totalOperations,
    double? percentage,
    String? currentFile,
    String? currentOperation,
    OperationStatus? status,
    Duration? elapsed,
    Duration? estimatedRemaining,
    Duration? totalEstimated,
    double? operationsPerSecond,
    double? bytesPerSecond,
    int? processedBytes,
    int? totalBytes,
    double? cpuUsage,
    double? memoryUsage,
    double? diskIOUsage,
    Map<String, dynamic>? systemResources,
    int? errorCount,
    int? warningCount,
    List<String>? recentErrors,
    List<String>? recentWarnings,
    Map<String, int>? errorTypes,
    String? currentStage,
    List<String>? completedStages,
    Map<String, double>? stageProgress,
    Map<String, Duration>? stageDurations,
    int? successfulOperations,
    int? failedOperations,
    int? skippedOperations,
    double? successRate,
    List<Map<String, dynamic>>? operationResults,
    bool? canPause,
    bool? canCancel,
    bool? canModify,
    List<String>? availableActions,
    Map<String, dynamic>? userControls,
    Map<String, dynamic>? performanceHints,
    List<String>? optimizationSuggestions,
    bool? isOptimized,
    Map<String, dynamic>? adaptiveSettings,
  }) {
    return EnhancedProgressUpdate(
      operationId: operationId ?? this.operationId,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      completedOperations: completedOperations ?? this.completedOperations,
      totalOperations: totalOperations ?? this.totalOperations,
      percentage: percentage ?? this.percentage,
      currentFile: currentFile ?? this.currentFile,
      currentOperation: currentOperation ?? this.currentOperation,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      estimatedRemaining: estimatedRemaining ?? this.estimatedRemaining,
      totalEstimated: totalEstimated ?? this.totalEstimated,
      operationsPerSecond: operationsPerSecond ?? this.operationsPerSecond,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      processedBytes: processedBytes ?? this.processedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskIOUsage: diskIOUsage ?? this.diskIOUsage,
      systemResources: systemResources ?? this.systemResources,
      errorCount: errorCount ?? this.errorCount,
      warningCount: warningCount ?? this.warningCount,
      recentErrors: recentErrors ?? this.recentErrors,
      recentWarnings: recentWarnings ?? this.recentWarnings,
      errorTypes: errorTypes ?? this.errorTypes,
      currentStage: currentStage ?? this.currentStage,
      completedStages: completedStages ?? this.completedStages,
      stageProgress: stageProgress ?? this.stageProgress,
      stageDurations: stageDurations ?? this.stageDurations,
      successfulOperations: successfulOperations ?? this.successfulOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      skippedOperations: skippedOperations ?? this.skippedOperations,
      successRate: successRate ?? this.successRate,
      operationResults: operationResults ?? this.operationResults,
      canPause: canPause ?? this.canPause,
      canCancel: canCancel ?? this.canCancel,
      canModify: canModify ?? this.canModify,
      availableActions: availableActions ?? this.availableActions,
      userControls: userControls ?? this.userControls,
      performanceHints: performanceHints ?? this.performanceHints,
      optimizationSuggestions: optimizationSuggestions ?? this.optimizationSuggestions,
      isOptimized: isOptimized ?? this.isOptimized,
      adaptiveSettings: adaptiveSettings ?? this.adaptiveSettings,
    );
  }

  /// Get overall health score of the operation (0.0 - 1.0)
  double get operationHealthScore {
    double base = successRate;
    
    // Penalize for high error rate
    double errorPenalty = (errorCount / (completedOperations + 1)) * 0.3;
    
    // Penalize for high resource usage
    double resourcePenalty = 0.0;
    if (cpuUsage > 0.9 || memoryUsage > 0.9 || diskIOUsage > 0.9) {
      resourcePenalty = 0.2;
    }
    
    // Boost for optimization
    double optimizationBoost = isOptimized ? 0.1 : 0.0;
    
    return (base - errorPenalty - resourcePenalty + optimizationBoost)
        .clamp(0.0, 1.0);
  }

  /// Check if operation needs attention
  bool get needsAttention {
    return errorCount > 0 ||
           cpuUsage > 0.95 ||
           memoryUsage > 0.95 ||
           !isOptimized ||
           status == OperationStatus.error;
  }

  /// Get estimated completion time
  DateTime? get estimatedCompletionTime {
    if (estimatedRemaining == null) return null;
    return timestamp.add(estimatedRemaining!);
  }

  /// Get human-readable status description
  String get statusDescription {
    switch (status) {
      case OperationStatus.analyzing:
        return 'Analyzing files and planning operations...';
      case OperationStatus.preparing:
        return 'Preparing file operations...';
      case OperationStatus.executing:
        return 'Organizing files ($completedOperations/$totalOperations)...';
      case OperationStatus.verifying:
        return 'Verifying completed operations...';
      case OperationStatus.paused:
        return 'Operation paused by user';
      case OperationStatus.completed:
        return 'File organization completed successfully';
      case OperationStatus.error:
        return 'Operation encountered errors';
      case OperationStatus.cancelled:
        return 'Operation cancelled by user';
      default:
        return 'Processing...';
    }
  }

  /// Get performance summary
  Map<String, dynamic> get performanceSummary {
    return {
      'operations_per_second': operationsPerSecond,
      'transfer_rate': '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s',
      'cpu_usage': '${(cpuUsage * 100).round()}%',
      'memory_usage': '${(memoryUsage * 100).round()}%',
      'disk_io_usage': '${(diskIOUsage * 100).round()}%',
      'success_rate': '${(successRate * 100).round()}%',
      'error_rate': '${((errorCount / (completedOperations + 1)) * 100).round()}%',
      'health_score': operationHealthScore,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'session_id': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'completed_operations': completedOperations,
    'total_operations': totalOperations,
    'percentage': percentage,
    'current_file': currentFile,
    'current_operation': currentOperation,
    'status': status.toString(),
    'elapsed': elapsed.inSeconds,
    'estimated_remaining': estimatedRemaining?.inSeconds,
    'total_estimated': totalEstimated?.inSeconds,
    'operations_per_second': operationsPerSecond,
    'bytes_per_second': bytesPerSecond,
    'processed_bytes': processedBytes,
    'total_bytes': totalBytes,
    'cpu_usage': cpuUsage,
    'memory_usage': memoryUsage,
    'disk_io_usage': diskIOUsage,
    'system_resources': systemResources,
    'error_count': errorCount,
    'warning_count': warningCount,
    'recent_errors': recentErrors,
    'recent_warnings': recentWarnings,
    'error_types': errorTypes,
    'current_stage': currentStage,
    'completed_stages': completedStages,
    'stage_progress': stageProgress,
    'stage_durations': stageDurations.map((k, v) => MapEntry(k, v.inSeconds)),
    'successful_operations': successfulOperations,
    'failed_operations': failedOperations,
    'skipped_operations': skippedOperations,
    'success_rate': successRate,
    'operation_results': operationResults,
    'can_pause': canPause,
    'can_cancel': canCancel,
    'can_modify': canModify,
    'available_actions': availableActions,
    'user_controls': userControls,
    'performance_hints': performanceHints,
    'optimization_suggestions': optimizationSuggestions,
    'is_optimized': isOptimized,
    'adaptive_settings': adaptiveSettings,
  };

  /// Create from JSON
  factory EnhancedProgressUpdate.fromJson(Map<String, dynamic> json) {
    return EnhancedProgressUpdate(
      operationId: json['operation_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
      completedOperations: json['completed_operations'] ?? 0,
      totalOperations: json['total_operations'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
      currentFile: json['current_file'] ?? '',
      currentOperation: json['current_operation'] ?? '',
      status: OperationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OperationStatus.idle,
      ),
      elapsed: Duration(seconds: json['elapsed'] ?? 0),
      estimatedRemaining: json['estimated_remaining'] != null 
        ? Duration(seconds: json['estimated_remaining'])
        : null,
      totalEstimated: json['total_estimated'] != null 
        ? Duration(seconds: json['total_estimated'])
        : null,
      operationsPerSecond: json['operations_per_second']?.toDouble() ?? 0.0,
      bytesPerSecond: json['bytes_per_second']?.toDouble() ?? 0.0,
      processedBytes: json['processed_bytes'] ?? 0,
      totalBytes: json['total_bytes'] ?? 0,
      cpuUsage: json['cpu_usage']?.toDouble() ?? 0.0,
      memoryUsage: json['memory_usage']?.toDouble() ?? 0.0,
      diskIOUsage: json['disk_io_usage']?.toDouble() ?? 0.0,
      systemResources: Map<String, dynamic>.from(json['system_resources'] ?? {}),
      errorCount: json['error_count'] ?? 0,
      warningCount: json['warning_count'] ?? 0,
      recentErrors: List<String>.from(json['recent_errors'] ?? []),
      recentWarnings: List<String>.from(json['recent_warnings'] ?? []),
      errorTypes: Map<String, int>.from(json['error_types'] ?? {}),
      currentStage: json['current_stage'] ?? '',
      completedStages: List<String>.from(json['completed_stages'] ?? []),
      stageProgress: Map<String, double>.from(json['stage_progress'] ?? {}),
      stageDurations: (json['stage_durations'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, Duration(seconds: v))),
      successfulOperations: json['successful_operations'] ?? 0,
      failedOperations: json['failed_operations'] ?? 0,
      skippedOperations: json['skipped_operations'] ?? 0,
      successRate: json['success_rate']?.toDouble() ?? 0.0,
      operationResults: List<Map<String, dynamic>>.from(json['operation_results'] ?? []),
      canPause: json['can_pause'] ?? true,
      canCancel: json['can_cancel'] ?? true,
      canModify: json['can_modify'] ?? false,
      availableActions: List<String>.from(json['available_actions'] ?? []),
      userControls: Map<String, dynamic>.from(json['user_controls'] ?? {}),
      performanceHints: Map<String, dynamic>.from(json['performance_hints'] ?? {}),
      optimizationSuggestions: List<String>.from(json['optimization_suggestions'] ?? []),
      isOptimized: json['is_optimized'] ?? true,
      adaptiveSettings: Map<String, dynamic>.from(json['adaptive_settings'] ?? {}),
    );
  }
}

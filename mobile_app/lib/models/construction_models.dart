import 'package:json_annotation/json_annotation.dart';

part 'construction_models.g.dart';

enum ConstructionPhaseType {
  foundation,
  structure,
  envelope,
  mechanical,
  interior,
  exterior,
  permits_fees;

  String get displayName {
    switch (this) {
      case ConstructionPhaseType.foundation:
        return 'Foundation';
      case ConstructionPhaseType.structure:
        return 'Structure';
      case ConstructionPhaseType.envelope:
        return 'Envelope';
      case ConstructionPhaseType.mechanical:
        return 'Mechanical';
      case ConstructionPhaseType.interior:
        return 'Interior';
      case ConstructionPhaseType.exterior:
        return 'Exterior';
      case ConstructionPhaseType.permits_fees:
        return 'Permits & Fees';
    }
  }
}

@JsonSerializable()
class ConstructionProject {
  final String id;
  final String name;
  final String description;
  final double totalBudget;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final DateTime? actualEndDate;
  final String status; // planned, in_progress, completed, paused
  final List<ConstructionPhase> phases;
  final List<String> contractorIds;

  ConstructionProject({
    required this.id,
    required this.name,
    required this.description,
    required this.totalBudget,
    required this.startDate,
    this.expectedEndDate,
    this.actualEndDate,
    required this.status,
    required this.phases,
    required this.contractorIds,
  });

  factory ConstructionProject.fromJson(Map<String, dynamic> json) =>
      _$ConstructionProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionProjectToJson(this);

  double get totalSpent => phases.fold(0.0, (sum, phase) => sum + phase.totalSpent);
  double get totalPlanned => phases.fold(0.0, (sum, phase) => sum + phase.totalPlanned);
  double get remainingBudget => totalBudget - totalSpent;
  double get budgetUtilization => totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
}

@JsonSerializable()
class ConstructionPhase {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final ConstructionPhaseType type;
  final double budget;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? expectedEndDate;
  final String status; // planned, in_progress, completed, delayed
  final int orderIndex;
  final List<ConstructionExpense> expenses;
  final List<PlannedExpense> plannedExpenses;

  ConstructionPhase({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.type,
    required this.budget,
    this.startDate,
    this.endDate,
    this.expectedEndDate,
    required this.status,
    required this.orderIndex,
    required this.expenses,
    required this.plannedExpenses,
  });

  factory ConstructionPhase.fromJson(Map<String, dynamic> json) =>
      _$ConstructionPhaseFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionPhaseToJson(this);

  double get totalSpent => expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  double get totalPlanned => plannedExpenses.fold(0.0, (sum, planned) => sum + planned.estimatedCost);
  double get remainingBudget => budget - totalSpent;
  double get phaseProgress => budget > 0 ? (totalSpent / budget) * 100 : 0;
}

@JsonSerializable()
class ConstructionExpense {
  final String id;
  final String phaseId;
  final String category;
  final String subcategory;
  final double amount;
  final String description;
  final DateTime date;
  final String? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? invoicePath;
  final String? receiptPath;
  final String paymentStatus; // pending, paid, overdue
  final DateTime? paymentDate;
  final String? notes;
  final bool isVatIncluded;
  final double? vatAmount;
  final String? measurementUnit;
  final double? quantity;
  final double? unitPrice;

  ConstructionExpense({
    required this.id,
    required this.phaseId,
    required this.category,
    required this.subcategory,
    required this.amount,
    required this.description,
    required this.date,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.invoicePath,
    this.receiptPath,
    required this.paymentStatus,
    this.paymentDate,
    this.notes,
    required this.isVatIncluded,
    this.vatAmount,
    this.measurementUnit,
    this.quantity,
    this.unitPrice,
  });

  factory ConstructionExpense.fromJson(Map<String, dynamic> json) =>
      _$ConstructionExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionExpenseToJson(this);

  double get netAmount => isVatIncluded && vatAmount != null ? amount - vatAmount! : amount;
  bool get isOverdue => paymentStatus == 'overdue';
  bool get isPaid => paymentStatus == 'paid';
}

@JsonSerializable()
class PlannedExpense {
  final String id;
  final String phaseId;
  final String category;
  final String subcategory;
  final String description;
  final double estimatedCost;
  final double? minCost;
  final double? maxCost;
  final DateTime? plannedDate;
  final DateTime? deadlineDate;
  final String priority; // low, medium, high, critical
  final String? supplierId;
  final String? supplierName;
  final String? notes;
  final bool isApproved;
  final String? measurementUnit;
  final double? estimatedQuantity;
  final double? estimatedUnitPrice;
  final List<String> dependencies; // IDs of other planned expenses

  PlannedExpense({
    required this.id,
    required this.phaseId,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.estimatedCost,
    this.minCost,
    this.maxCost,
    this.plannedDate,
    this.deadlineDate,
    required this.priority,
    this.supplierId,
    this.supplierName,
    this.notes,
    required this.isApproved,
    this.measurementUnit,
    this.estimatedQuantity,
    this.estimatedUnitPrice,
    required this.dependencies,
  });

  factory PlannedExpense.fromJson(Map<String, dynamic> json) =>
      _$PlannedExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$PlannedExpenseToJson(this);

  double get costRange => maxCost != null && minCost != null ? maxCost! - minCost! : 0;
  bool get isHighPriority => priority == 'high' || priority == 'critical';
  bool get hasDeadline => deadlineDate != null;
}

@JsonSerializable()
class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String category; // materials, labor, equipment, services
  final double? rating;
  final String? notes;
  final bool isPreferred;
  final List<String> specialties;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.website,
    required this.category,
    this.rating,
    this.notes,
    required this.isPreferred,
    required this.specialties,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) =>
      _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);
}

// Austrian Construction Categories
class ConstructionCategories {
  static const Map<String, List<String>> categories = {
    'foundation': [
      'excavation',
      'concrete',
      'reinforcement',
      'waterproofing',
      'drainage',
    ],
    'structure': [
      'concrete_work',
      'steel_work',
      'masonry',
      'timber_frame',
      'roofing',
    ],
    'envelope': [
      'insulation',
      'windows',
      'doors',
      'facade',
      'roofing_materials',
    ],
    'mechanical': [
      'heating',
      'plumbing',
      'ventilation',
      'electrical',
      'smart_home',
    ],
    'interior': [
      'flooring',
      'walls',
      'ceiling',
      'kitchen',
      'bathrooms',
    ],
    'exterior': [
      'landscaping',
      'driveway',
      'fencing',
      'outdoor_lighting',
      'garden',
    ],
    'permits_fees': [
      'building_permits',
      'inspection_fees',
      'utility_connections',
      'professional_services',
      'insurance',
    ],
  };

  static const Map<String, String> categoryNames = {
    'foundation': 'Foundation & Site Work',
    'structure': 'Structural Work',
    'envelope': 'Building Envelope',
    'mechanical': 'Mechanical Systems',
    'interior': 'Interior Finishing',
    'exterior': 'Exterior & Landscaping',
    'permits_fees': 'Permits & Fees',
  };

  static List<String> getAllCategories() => categories.keys.toList();
  
  static List<String> getSubcategories(String category) => 
      categories[category] ?? [];

  static String getCategoryDisplayName(String category) => 
      categoryNames[category] ?? category;
}

// Construction Project Timeline
@JsonSerializable()
class ConstructionTimeline {
  final String projectId;
  final List<TimelineEvent> events;
  final List<Milestone> milestones;

  ConstructionTimeline({
    required this.projectId,
    required this.events,
    required this.milestones,
  });

  factory ConstructionTimeline.fromJson(Map<String, dynamic> json) =>
      _$ConstructionTimelineFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionTimelineToJson(this);
}

@JsonSerializable()
class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // expense, milestone, issue, note
  final String? relatedId; // expense ID, milestone ID, etc.

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.relatedId,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
  Map<String, dynamic> toJson() => _$TimelineEventToJson(this);
}

@JsonSerializable()
class Milestone {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final DateTime targetDate;
  final DateTime? actualDate;
  final String status; // pending, completed, delayed
  final double? budgetAllocation;
  final List<String> dependentPhaseIds;

  Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.targetDate,
    this.actualDate,
    required this.status,
    this.budgetAllocation,
    required this.dependentPhaseIds,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) =>
      _$MilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$MilestoneToJson(this);

  bool get isCompleted => status == 'completed';
  bool get isDelayed => status == 'delayed';
  int get daysUntilTarget => targetDate.difference(DateTime.now()).inDays;
} 
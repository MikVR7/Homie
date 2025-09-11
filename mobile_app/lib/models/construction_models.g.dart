// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'construction_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConstructionProject _$ConstructionProjectFromJson(Map<String, dynamic> json) =>
    ConstructionProject(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      totalBudget: (json['totalBudget'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      expectedEndDate: json['expectedEndDate'] == null
          ? null
          : DateTime.parse(json['expectedEndDate'] as String),
      actualEndDate: json['actualEndDate'] == null
          ? null
          : DateTime.parse(json['actualEndDate'] as String),
      status: json['status'] as String,
      phases: (json['phases'] as List<dynamic>)
          .map((e) => ConstructionPhase.fromJson(e as Map<String, dynamic>))
          .toList(),
      contractorIds: (json['contractorIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ConstructionProjectToJson(
  ConstructionProject instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'totalBudget': instance.totalBudget,
  'startDate': instance.startDate.toIso8601String(),
  'expectedEndDate': instance.expectedEndDate?.toIso8601String(),
  'actualEndDate': instance.actualEndDate?.toIso8601String(),
  'status': instance.status,
  'phases': instance.phases,
  'contractorIds': instance.contractorIds,
};

ConstructionPhase _$ConstructionPhaseFromJson(Map<String, dynamic> json) =>
    ConstructionPhase(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ConstructionPhaseTypeEnumMap, json['type']),
      budget: (json['budget'] as num).toDouble(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      expectedEndDate: json['expectedEndDate'] == null
          ? null
          : DateTime.parse(json['expectedEndDate'] as String),
      status: json['status'] as String,
      orderIndex: (json['orderIndex'] as num).toInt(),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => ConstructionExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      plannedExpenses: (json['plannedExpenses'] as List<dynamic>)
          .map((e) => PlannedExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ConstructionPhaseToJson(ConstructionPhase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'description': instance.description,
      'type': _$ConstructionPhaseTypeEnumMap[instance.type]!,
      'budget': instance.budget,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'expectedEndDate': instance.expectedEndDate?.toIso8601String(),
      'status': instance.status,
      'orderIndex': instance.orderIndex,
      'expenses': instance.expenses,
      'plannedExpenses': instance.plannedExpenses,
    };

const _$ConstructionPhaseTypeEnumMap = {
  ConstructionPhaseType.foundation: 'foundation',
  ConstructionPhaseType.structure: 'structure',
  ConstructionPhaseType.envelope: 'envelope',
  ConstructionPhaseType.mechanical: 'mechanical',
  ConstructionPhaseType.interior: 'interior',
  ConstructionPhaseType.exterior: 'exterior',
  ConstructionPhaseType.permits_fees: 'permits_fees',
};

ConstructionExpense _$ConstructionExpenseFromJson(Map<String, dynamic> json) =>
    ConstructionExpense(
      id: json['id'] as String,
      phaseId: json['phaseId'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoicePath: json['invoicePath'] as String?,
      receiptPath: json['receiptPath'] as String?,
      paymentStatus: json['paymentStatus'] as String,
      paymentDate: json['paymentDate'] == null
          ? null
          : DateTime.parse(json['paymentDate'] as String),
      notes: json['notes'] as String?,
      isVatIncluded: json['isVatIncluded'] as bool,
      vatAmount: (json['vatAmount'] as num?)?.toDouble(),
      measurementUnit: json['measurementUnit'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ConstructionExpenseToJson(
  ConstructionExpense instance,
) => <String, dynamic>{
  'id': instance.id,
  'phaseId': instance.phaseId,
  'category': instance.category,
  'subcategory': instance.subcategory,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'supplierId': instance.supplierId,
  'supplierName': instance.supplierName,
  'invoiceNumber': instance.invoiceNumber,
  'invoicePath': instance.invoicePath,
  'receiptPath': instance.receiptPath,
  'paymentStatus': instance.paymentStatus,
  'paymentDate': instance.paymentDate?.toIso8601String(),
  'notes': instance.notes,
  'isVatIncluded': instance.isVatIncluded,
  'vatAmount': instance.vatAmount,
  'measurementUnit': instance.measurementUnit,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
};

PlannedExpense _$PlannedExpenseFromJson(Map<String, dynamic> json) =>
    PlannedExpense(
      id: json['id'] as String,
      phaseId: json['phaseId'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      description: json['description'] as String,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      minCost: (json['minCost'] as num?)?.toDouble(),
      maxCost: (json['maxCost'] as num?)?.toDouble(),
      plannedDate: json['plannedDate'] == null
          ? null
          : DateTime.parse(json['plannedDate'] as String),
      deadlineDate: json['deadlineDate'] == null
          ? null
          : DateTime.parse(json['deadlineDate'] as String),
      priority: json['priority'] as String,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      notes: json['notes'] as String?,
      isApproved: json['isApproved'] as bool,
      measurementUnit: json['measurementUnit'] as String?,
      estimatedQuantity: (json['estimatedQuantity'] as num?)?.toDouble(),
      estimatedUnitPrice: (json['estimatedUnitPrice'] as num?)?.toDouble(),
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PlannedExpenseToJson(PlannedExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phaseId': instance.phaseId,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'description': instance.description,
      'estimatedCost': instance.estimatedCost,
      'minCost': instance.minCost,
      'maxCost': instance.maxCost,
      'plannedDate': instance.plannedDate?.toIso8601String(),
      'deadlineDate': instance.deadlineDate?.toIso8601String(),
      'priority': instance.priority,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'notes': instance.notes,
      'isApproved': instance.isApproved,
      'measurementUnit': instance.measurementUnit,
      'estimatedQuantity': instance.estimatedQuantity,
      'estimatedUnitPrice': instance.estimatedUnitPrice,
      'dependencies': instance.dependencies,
    };

Supplier _$SupplierFromJson(Map<String, dynamic> json) => Supplier(
  id: json['id'] as String,
  name: json['name'] as String,
  contactPerson: json['contactPerson'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  website: json['website'] as String?,
  category: json['category'] as String,
  rating: (json['rating'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  isPreferred: json['isPreferred'] as bool,
  specialties: (json['specialties'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SupplierToJson(Supplier instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'contactPerson': instance.contactPerson,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'website': instance.website,
  'category': instance.category,
  'rating': instance.rating,
  'notes': instance.notes,
  'isPreferred': instance.isPreferred,
  'specialties': instance.specialties,
};

ConstructionTimeline _$ConstructionTimelineFromJson(
  Map<String, dynamic> json,
) => ConstructionTimeline(
  projectId: json['projectId'] as String,
  events: (json['events'] as List<dynamic>)
      .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  milestones: (json['milestones'] as List<dynamic>)
      .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ConstructionTimelineToJson(
  ConstructionTimeline instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  'events': instance.events,
  'milestones': instance.milestones,
};

TimelineEvent _$TimelineEventFromJson(Map<String, dynamic> json) =>
    TimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      relatedId: json['relatedId'] as String?,
    );

Map<String, dynamic> _$TimelineEventToJson(TimelineEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'type': instance.type,
      'relatedId': instance.relatedId,
    };

Milestone _$MilestoneFromJson(Map<String, dynamic> json) => Milestone(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  targetDate: DateTime.parse(json['targetDate'] as String),
  actualDate: json['actualDate'] == null
      ? null
      : DateTime.parse(json['actualDate'] as String),
  status: json['status'] as String,
  budgetAllocation: (json['budgetAllocation'] as num?)?.toDouble(),
  dependentPhaseIds: (json['dependentPhaseIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MilestoneToJson(Milestone instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'title': instance.title,
  'description': instance.description,
  'targetDate': instance.targetDate.toIso8601String(),
  'actualDate': instance.actualDate?.toIso8601String(),
  'status': instance.status,
  'budgetAllocation': instance.budgetAllocation,
  'dependentPhaseIds': instance.dependentPhaseIds,
};

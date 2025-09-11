import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/construction_models.dart';
import '../config/api_config.dart';
import 'package:uuid/uuid.dart';

class ConstructionService {
  static const String _baseUrl = ApiConfig.baseUrl;
  final _uuid = const Uuid();

  // ========== PROJECT MANAGEMENT ==========

  // Public method for demo projects
  List<ConstructionProject> getDemoProjects() {
    return _getDemoProjects();
  }

  // Helper methods for provider
  ConstructionProject addExpenseToProject(ConstructionProject project, ConstructionExpense expense) {
    final updatedPhases = project.phases.map((phase) {
      if (phase.id == expense.phaseId) {
        final updatedExpenses = [...phase.expenses, expense];
        return ConstructionPhase(
          id: phase.id,
          projectId: phase.projectId,
          name: phase.name,
          description: phase.description,
          type: phase.type,
          budget: phase.budget,
          startDate: phase.startDate,
          endDate: phase.endDate,
          expectedEndDate: phase.expectedEndDate,
          status: phase.status,
          orderIndex: phase.orderIndex,
          expenses: updatedExpenses,
          plannedExpenses: phase.plannedExpenses,
        );
      }
      return phase;
    }).toList();

    return ConstructionProject(
      id: project.id,
      name: project.name,
      description: project.description,
      totalBudget: project.totalBudget,
      startDate: project.startDate,
      expectedEndDate: project.expectedEndDate,
      actualEndDate: project.actualEndDate,
      status: project.status,
      phases: updatedPhases,
      contractorIds: project.contractorIds,
    );
  }

  ConstructionProject updateExpenseInProject(ConstructionProject project, ConstructionExpense expense) {
    final updatedPhases = project.phases.map((phase) {
      if (phase.id == expense.phaseId) {
        final updatedExpenses = phase.expenses.map((e) => e.id == expense.id ? expense : e).toList();
        return ConstructionPhase(
          id: phase.id,
          projectId: phase.projectId,
          name: phase.name,
          description: phase.description,
          type: phase.type,
          budget: phase.budget,
          startDate: phase.startDate,
          endDate: phase.endDate,
          expectedEndDate: phase.expectedEndDate,
          status: phase.status,
          orderIndex: phase.orderIndex,
          expenses: updatedExpenses,
          plannedExpenses: phase.plannedExpenses,
        );
      }
      return phase;
    }).toList();

    return ConstructionProject(
      id: project.id,
      name: project.name,
      description: project.description,
      totalBudget: project.totalBudget,
      startDate: project.startDate,
      expectedEndDate: project.expectedEndDate,
      actualEndDate: project.actualEndDate,
      status: project.status,
      phases: updatedPhases,
      contractorIds: project.contractorIds,
    );
  }

  ConstructionProject addPlannedExpenseToProject(ConstructionProject project, PlannedExpense plannedExpense) {
    final updatedPhases = project.phases.map((phase) {
      if (phase.id == plannedExpense.phaseId) {
        final updatedPlannedExpenses = [...phase.plannedExpenses, plannedExpense];
        return ConstructionPhase(
          id: phase.id,
          projectId: phase.projectId,
          name: phase.name,
          description: phase.description,
          type: phase.type,
          budget: phase.budget,
          startDate: phase.startDate,
          endDate: phase.endDate,
          expectedEndDate: phase.expectedEndDate,
          status: phase.status,
          orderIndex: phase.orderIndex,
          expenses: phase.expenses,
          plannedExpenses: updatedPlannedExpenses,
        );
      }
      return phase;
    }).toList();

    return ConstructionProject(
      id: project.id,
      name: project.name,
      description: project.description,
      totalBudget: project.totalBudget,
      startDate: project.startDate,
      expectedEndDate: project.expectedEndDate,
      actualEndDate: project.actualEndDate,
      status: project.status,
      phases: updatedPhases,
      contractorIds: project.contractorIds,
    );
  }

  ConstructionProject updatePlannedExpenseInProject(ConstructionProject project, PlannedExpense plannedExpense) {
    final updatedPhases = project.phases.map((phase) {
      if (phase.id == plannedExpense.phaseId) {
        final updatedPlannedExpenses = phase.plannedExpenses.map((p) => p.id == plannedExpense.id ? plannedExpense : p).toList();
        return ConstructionPhase(
          id: phase.id,
          projectId: phase.projectId,
          name: phase.name,
          description: phase.description,
          type: phase.type,
          budget: phase.budget,
          startDate: phase.startDate,
          endDate: phase.endDate,
          expectedEndDate: phase.expectedEndDate,
          status: phase.status,
          orderIndex: phase.orderIndex,
          expenses: phase.expenses,
          plannedExpenses: updatedPlannedExpenses,
        );
      }
      return phase;
    }).toList();

    return ConstructionProject(
      id: project.id,
      name: project.name,
      description: project.description,
      totalBudget: project.totalBudget,
      startDate: project.startDate,
      expectedEndDate: project.expectedEndDate,
      actualEndDate: project.actualEndDate,
      status: project.status,
      phases: updatedPhases,
      contractorIds: project.contractorIds,
    );
  }

  Future<List<ConstructionProject>> getProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/projects'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ConstructionProject.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load construction projects');
      }
    } catch (e) {
      // Fallback to demo data
      return _getDemoProjects();
    }
  }

  Future<ConstructionProject?> getProject(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/projects/$projectId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConstructionProject.fromJson(data);
      }
      return null;
    } catch (e) {
      // Fallback to demo project
      final projects = await getProjects();
      return projects.isNotEmpty ? projects.first : null;
    }
  }

  Future<ConstructionProject> createProject(ConstructionProject project) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/construction/projects'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConstructionProject.fromJson(data);
      } else {
        throw Exception('Failed to create project');
      }
    } catch (e) {
      // Return the project with generated ID for demo
      return project;
    }
  }

  // ========== EXPENSE TRACKING ==========

  Future<List<ConstructionExpense>> getPhaseExpenses(String phaseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/phases/$phaseId/expenses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ConstructionExpense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses');
      }
    } catch (e) {
      return _getDemoExpenses(phaseId);
    }
  }

  Future<ConstructionExpense> addExpense(ConstructionExpense expense) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/construction/expenses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConstructionExpense.fromJson(data);
      } else {
        throw Exception('Failed to add expense');
      }
    } catch (e) {
      return expense;
    }
  }

  Future<void> updateExpensePaymentStatus(String expenseId, String status, DateTime? paymentDate) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/construction/expenses/$expenseId/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentStatus': status,
          'paymentDate': paymentDate?.toIso8601String(),
        }),
      );
    } catch (e) {
      // Ignore error in demo mode
    }
  }

  // ========== FUTURE COST PLANNING ==========

  Future<List<PlannedExpense>> getPlannedExpenses(String phaseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/phases/$phaseId/planned-expenses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlannedExpense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load planned expenses');
      }
    } catch (e) {
      return _getDemoPlannedExpenses(phaseId);
    }
  }

  Future<PlannedExpense> addPlannedExpense(PlannedExpense plannedExpense) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/construction/planned-expenses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(plannedExpense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return PlannedExpense.fromJson(data);
      } else {
        throw Exception('Failed to add planned expense');
      }
    } catch (e) {
      return plannedExpense;
    }
  }

  Future<void> approvePlannedExpense(String plannedExpenseId) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/construction/planned-expenses/$plannedExpenseId/approve'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Ignore error in demo mode
    }
  }

  Future<ConstructionExpense> convertPlannedToActual(PlannedExpense plannedExpense, double actualAmount) async {
    final actualExpense = ConstructionExpense(
      id: _uuid.v4(),
      phaseId: plannedExpense.phaseId,
      category: plannedExpense.category,
      subcategory: plannedExpense.subcategory,
      amount: actualAmount,
      description: plannedExpense.description,
      date: DateTime.now(),
      supplierId: plannedExpense.supplierId,
      supplierName: plannedExpense.supplierName,
      paymentStatus: 'pending',
      isVatIncluded: true,
      vatAmount: actualAmount * 0.20, // Austrian VAT
      measurementUnit: plannedExpense.measurementUnit,
      quantity: plannedExpense.estimatedQuantity,
      unitPrice: plannedExpense.estimatedUnitPrice,
      notes: 'Converted from planned expense: ${plannedExpense.id}',
    );

    return await addExpense(actualExpense);
  }

  // ========== SUPPLIER MANAGEMENT ==========

  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/suppliers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Supplier.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load suppliers');
      }
    } catch (e) {
      return _getDemoSuppliers();
    }
  }

  Future<Supplier> addSupplier(Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/construction/suppliers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplier.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data);
      } else {
        throw Exception('Failed to add supplier');
      }
    } catch (e) {
      return supplier;
    }
  }

  // ========== ANALYTICS & REPORTING ==========

  // Synchronous method for provider
  Map<String, dynamic> calculateProjectAnalytics(String projectId) {
    return _getDemoAnalytics(projectId);
  }

  // Category breakdown for provider
  List<Map<String, dynamic>> getCategoryBreakdown(ConstructionProject project) {
    final breakdown = <String, double>{};
    
    for (final phase in project.phases) {
      for (final expense in phase.expenses) {
        breakdown[expense.category] = (breakdown[expense.category] ?? 0) + expense.amount;
      }
    }
    
    return breakdown.entries
        .map((entry) => {'category': entry.key, 'amount': entry.value})
        .toList();
  }

  Future<Map<String, dynamic>> getProjectAnalytics(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/projects/$projectId/analytics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics');
      }
    } catch (e) {
      return _getDemoAnalytics(projectId);
    }
  }

  Future<List<Map<String, dynamic>>> getCostOverruns(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/projects/$projectId/overruns'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load cost overruns');
      }
    } catch (e) {
      return _getDemoCostOverruns();
    }
  }

  Future<Map<String, double>> getCashFlowForecast(String projectId, int months) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/construction/projects/$projectId/cash-flow?months=$months'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, double>.from(data);
      } else {
        throw Exception('Failed to load cash flow forecast');
      }
    } catch (e) {
      return _getDemoCashFlowForecast();
    }
  }

  // ========== DEMO DATA ==========

  List<ConstructionProject> _getDemoProjects() {
    return [
      ConstructionProject(
        id: 'proj_1',
        name: 'Family House Construction',
        description: 'Single-family house construction in Lower Austria',
        totalBudget: 350000.0,
        startDate: DateTime(2024, 3, 1),
        expectedEndDate: DateTime(2025, 10, 30),
        status: 'in_progress',
        phases: _getDemoPhases(),
        contractorIds: ['contractor_1', 'contractor_2'],
      ),
    ];
  }

  List<ConstructionPhase> _getDemoPhases() {
    return [
      ConstructionPhase(
        id: 'phase_1',
        projectId: 'proj_1',
        name: 'Foundation & Site Work',
        description: 'Excavation, foundation, and site preparation',
        type: ConstructionPhaseType.foundation,
        budget: 75000.0,
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 5, 15),
        expectedEndDate: DateTime(2024, 5, 30),
        status: 'completed',
        orderIndex: 1,
        expenses: _getDemoExpenses('phase_1'),
        plannedExpenses: [],
      ),
      ConstructionPhase(
        id: 'phase_2',
        projectId: 'proj_1',
        name: 'Structural Work',
        description: 'Concrete work, steel, masonry, and roofing',
        type: ConstructionPhaseType.structure,
        budget: 120000.0,
        startDate: DateTime(2024, 5, 16),
        expectedEndDate: DateTime(2024, 9, 30),
        status: 'in_progress',
        orderIndex: 2,
        expenses: _getDemoExpenses('phase_2'),
        plannedExpenses: _getDemoPlannedExpenses('phase_2'),
      ),
      ConstructionPhase(
        id: 'phase_3',
        projectId: 'proj_1',
        name: 'Mechanical Systems',
        description: 'Heating, plumbing, electrical, and HVAC',
        type: ConstructionPhaseType.mechanical,
        budget: 85000.0,
        expectedEndDate: DateTime(2024, 12, 31),
        status: 'planned',
        orderIndex: 3,
        expenses: [],
        plannedExpenses: _getDemoPlannedExpenses('phase_3'),
      ),
    ];
  }

  List<ConstructionExpense> _getDemoExpenses(String phaseId) {
    return [
      ConstructionExpense(
        id: 'exp_1',
        phaseId: phaseId,
        category: 'foundation',
        subcategory: 'concrete',
        amount: 12500.0,
        description: 'Foundation concrete C25/30',
        date: DateTime(2024, 3, 15),
        supplierId: 'supplier_1',
        supplierName: 'Wienerberger AG',
        invoiceNumber: 'INV-2024-001',
        paymentStatus: 'paid',
        paymentDate: DateTime(2024, 3, 25),
        isVatIncluded: true,
        vatAmount: 2500.0,
        measurementUnit: 'm³',
        quantity: 50.0,
        unitPrice: 250.0,
      ),
      ConstructionExpense(
        id: 'exp_2',
        phaseId: phaseId,
        category: 'foundation',
        subcategory: 'reinforcement',
        amount: 8750.0,
        description: 'Steel reinforcement bars',
        date: DateTime(2024, 3, 20),
        supplierId: 'supplier_2',
        supplierName: 'voestalpine Stahl GmbH',
        invoiceNumber: 'INV-2024-002',
        paymentStatus: 'pending',
        isVatIncluded: true,
        vatAmount: 1750.0,
        measurementUnit: 'tons',
        quantity: 3.5,
        unitPrice: 2500.0,
      ),
    ];
  }

  List<PlannedExpense> _getDemoPlannedExpenses(String phaseId) {
    return [
      PlannedExpense(
        id: 'planned_1',
        phaseId: phaseId,
        category: 'mechanical',
        subcategory: 'heating',
        description: 'Heat pump installation (air-to-water)',
        estimatedCost: 18000.0,
        minCost: 15000.0,
        maxCost: 22000.0,
        plannedDate: DateTime(2024, 11, 15),
        deadlineDate: DateTime(2024, 12, 1),
        priority: 'high',
        supplierId: 'supplier_3',
        supplierName: 'Dimplex Austria',
        notes: 'Include installation and commissioning',
        isApproved: false,
        measurementUnit: 'unit',
        estimatedQuantity: 1.0,
        estimatedUnitPrice: 18000.0,
        dependencies: [],
      ),
      PlannedExpense(
        id: 'planned_2',
        phaseId: phaseId,
        category: 'mechanical',
        subcategory: 'electrical',
        description: 'Main electrical panel and wiring',
        estimatedCost: 12000.0,
        minCost: 10000.0,
        maxCost: 15000.0,
        plannedDate: DateTime(2024, 10, 1),
        priority: 'critical',
        supplierId: 'supplier_4',
        supplierName: 'Schneider Electric Austria',
        isApproved: true,
        measurementUnit: 'unit',
        estimatedQuantity: 1.0,
        estimatedUnitPrice: 12000.0,
        dependencies: [],
      ),
    ];
  }

  List<Supplier> _getDemoSuppliers() {
    return [
      Supplier(
        id: 'supplier_1',
        name: 'Wienerberger AG',
        contactPerson: 'Johann Müller',
        email: 'johann.mueller@wienerberger.com',
        phone: '+43 1 601 92-0',
        address: 'Wienerbergerstraße 11, 1100 Wien',
        website: 'www.wienerberger.at',
        category: 'materials',
        rating: 4.8,
        isPreferred: true,
        specialties: ['bricks', 'concrete', 'roofing'],
      ),
      Supplier(
        id: 'supplier_2',
        name: 'voestalpine Stahl GmbH',
        contactPerson: 'Maria Schmidt',
        email: 'maria.schmidt@voestalpine.com',
        phone: '+43 50304-0',
        category: 'materials',
        rating: 4.7,
        isPreferred: true,
        specialties: ['steel', 'reinforcement', 'structural'],
      ),
      Supplier(
        id: 'supplier_3',
        name: 'Dimplex Austria',
        contactPerson: 'Peter Wagner',
        email: 'peter.wagner@dimplex.at',
        phone: '+43 7242 69 300',
        category: 'equipment',
        rating: 4.6,
        isPreferred: false,
        specialties: ['heating', 'heat_pumps', 'renewable_energy'],
      ),
    ];
  }

  Map<String, dynamic> _getDemoAnalytics(String projectId) {
    return {
      'totalBudget': 350000.0,
      'totalSpent': 145000.0,
      'totalPlanned': 89000.0,
      'remainingBudget': 205000.0,
      'budgetUtilization': 41.4,
      'projectedTotalCost': 378000.0,
      'projectedOverrun': 28000.0,
      'overrunPercentage': 8.0,
      'completionPercentage': 35.0,
      'scheduleDaysRemaining': 295,
      'averageDailyCost': 491.5,
      'categoryBreakdown': {
        'foundation': 65000.0,
        'structure': 80000.0,
        'mechanical': 0.0,
        'envelope': 0.0,
        'interior': 0.0,
        'exterior': 0.0,
      },
      'monthlySpending': {
        '2024-03': 35000.0,
        '2024-04': 42000.0,
        '2024-05': 38000.0,
        '2024-06': 30000.0,
      },
    };
  }

  List<Map<String, dynamic>> _getDemoCostOverruns() {
    return [
      {
        'phase': 'Foundation & Site Work',
        'budget': 75000.0,
        'actual': 78500.0,
        'overrun': 3500.0,
        'overrunPercentage': 4.7,
        'reason': 'Additional excavation for rocky soil',
      },
      {
        'phase': 'Structural Work',
        'budget': 120000.0,
        'actual': 126000.0,
        'overrun': 6000.0,
        'overrunPercentage': 5.0,
        'reason': 'Steel price increase',
      },
    ];
  }

  Map<String, double> _getDemoCashFlowForecast() {
    return {
      '2024-07': -25000.0,
      '2024-08': -32000.0,
      '2024-09': -28000.0,
      '2024-10': -45000.0,
      '2024-11': -38000.0,
      '2024-12': -35000.0,
    };
  }
} 
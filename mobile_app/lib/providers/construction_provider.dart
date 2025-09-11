import 'package:flutter/foundation.dart';
import 'package:homie_app/models/construction_models.dart';
import 'package:homie_app/services/construction_service.dart';

class ConstructionProvider with ChangeNotifier {
  final ConstructionService _constructionService = ConstructionService();

  List<ConstructionProject> _projects = [];
  ConstructionProject? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;

  List<ConstructionProject> get projects => _projects;
  ConstructionProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize the provider with demo data
  ConstructionProvider() {
    _loadDemoData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _loadDemoData() {
    try {
      _setLoading(true);
      _projects = _constructionService.getDemoProjects();
      if (_projects.isNotEmpty) {
        _currentProject = _projects.first;
      }
      _setError(null);
    } catch (e) {
      _setError('Failed to load construction data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Project management
  Future<void> createProject(ConstructionProject project) async {
    try {
      _setLoading(true);
      _projects.add(project);
      if (_currentProject == null) {
        _currentProject = project;
      }
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create project: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentProject(String projectId) {
    try {
      _currentProject = _projects.firstWhere((p) => p.id == projectId);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Project not found');
    }
  }

  // Expense management
  Future<void> addExpense(ConstructionExpense expense) async {
    try {
      if (_currentProject == null) return;
      
      _setLoading(true);
      _currentProject = _constructionService.addExpenseToProject(_currentProject!, expense);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add expense: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense(ConstructionExpense expense) async {
    try {
      if (_currentProject == null) return;
      
      _setLoading(true);
      _currentProject = _constructionService.updateExpenseInProject(_currentProject!, expense);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update expense: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Planned expense management
  Future<void> addPlannedExpense(PlannedExpense plannedExpense) async {
    try {
      if (_currentProject == null) return;
      
      _setLoading(true);
      _currentProject = _constructionService.addPlannedExpenseToProject(_currentProject!, plannedExpense);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add planned expense: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePlannedExpense(PlannedExpense plannedExpense) async {
    try {
      if (_currentProject == null) return;
      
      _setLoading(true);
      _currentProject = _constructionService.updatePlannedExpenseInProject(_currentProject!, plannedExpense);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update planned expense: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Analytics
  Map<String, dynamic> getProjectAnalytics() {
    if (_currentProject == null) return {};
    return _constructionService.calculateProjectAnalytics(_currentProject!.id);
  }

  List<Map<String, dynamic>> getCategoryBreakdown() {
    if (_currentProject == null) return [];
    return _constructionService.getCategoryBreakdown(_currentProject!);
  }

  List<Map<String, dynamic>> getCashFlowForecast() {
    if (_currentProject == null) return [];
    return _constructionService.getCategoryBreakdown(_currentProject!);
  }

  // Utility methods
  List<ConstructionExpense> getExpensesForPhase(ConstructionPhaseType phase) {
    if (_currentProject == null) return [];
    
    final projectPhase = _currentProject!.phases.firstWhere(
      (p) => p.type == phase,
      orElse: () => ConstructionPhase(
        id: '',
        projectId: '',
        name: phase.displayName,
        description: '',
        type: phase,
        budget: 0,
        status: 'planned',
        orderIndex: 0,
        expenses: [],
        plannedExpenses: [],
      ),
    );
    
    return projectPhase.expenses;
  }

  List<PlannedExpense> getPlannedExpensesForPhase(ConstructionPhaseType phase) {
    if (_currentProject == null) return [];
    
    final projectPhase = _currentProject!.phases.firstWhere(
      (p) => p.type == phase,
      orElse: () => ConstructionPhase(
        id: '',
        projectId: '',
        name: phase.displayName,
        description: '',
        type: phase,
        budget: 0,
        status: 'planned',
        orderIndex: 0,
        expenses: [],
        plannedExpenses: [],
      ),
    );
    
    return projectPhase.plannedExpenses;
  }

  Map<String, dynamic> getAnalytics() {
    if (_currentProject == null) return {};
    // For now, return demo analytics data since the service method is async
    return {
      'budgetUtilization': _currentProject!.budgetUtilization,
      'overrunPercentage': (_currentProject!.totalSpent - _currentProject!.totalBudget) / _currentProject!.totalBudget * 100,
      'completionPercentage': 65.0,
      'scheduleDaysRemaining': 180,
      'categoryBreakdown': {
        'foundation': 82500.0,
        'structure': 135000.0,
        'mechanical': 45000.0,
        'interior': 28000.0,
        'exterior': 15000.0,
        'permits_fees': 8500.0,
      },
    };
  }

  List<Map<String, dynamic>> getCostOverruns() {
    if (_currentProject == null) return [];
    // For now, return demo data since the service method is async
    return [
      {
        'phase': 'Foundation & Site Work',
        'budget': 75000.0,
        'actual': 82500.0,
        'overrun': 7500.0,
        'overrunPercentage': 10.0,
      },
      {
        'phase': 'Structural Work',
        'budget': 120000.0,
        'actual': 135000.0,
        'overrun': 15000.0,
        'overrunPercentage': 12.5,
      },
    ];
  }

  void refresh() {
    _loadDemoData();
  }
} 
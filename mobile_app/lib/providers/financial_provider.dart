import 'package:flutter/foundation.dart';
import 'package:homie_app/models/financial_models.dart';
import 'package:homie_app/services/api_service.dart';

class FinancialProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  FinancialSummary? _summary;
  List<IncomeEntry> _incomeEntries = [];
  List<ExpenseEntry> _expenseEntries = [];
  ConstructionBudget? _constructionBudget;
  TaxReport? _taxReport;
  bool _isLoading = false;
  int _loadingCounter = 0;
  String? _errorMessage;
  
  // User accounts and securities
  List<Map<String, dynamic>> _userAccounts = [];
  List<Map<String, dynamic>> _securities = [];
  
  // Time period filtering
  String _selectedPeriod = 'Yearly';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Current period navigation
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  FinancialSummary? get summary => _summary;
  List<IncomeEntry> get incomeEntries => _incomeEntries;
  List<ExpenseEntry> get expenseEntries => _expenseEntries;
  ConstructionBudget? get constructionBudget => _constructionBudget;
  TaxReport? get taxReport => _taxReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // User accounts and securities getters
  List<Map<String, dynamic>> get userAccounts => _userAccounts;
  List<Map<String, dynamic>> get securities => _securities;
  
  // Time period getters
  String get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  
  // Current period getters
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  DateTime get currentWeekStart => _currentWeekStart;
  
  // Current period display helpers
  String get currentPeriodDisplay {
    switch (_selectedPeriod) {
      case 'Monthly':
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[_currentMonth - 1]} $_currentYear';
      case 'Yearly':
        return '$_currentYear';
      case 'Weekly':
        final weekEnd = _currentWeekStart.add(const Duration(days: 6));
        return '${_currentWeekStart.day}/${_currentWeekStart.month} - ${weekEnd.day}/${weekEnd.month}';
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}';
        }
        return 'Custom Period';
      default:
        return '';
    }
  }

  Future<void> loadSummary() async {
    _setLoading(true);
    try {
      _summary = await _apiService.getFinancialSummary(
        period: _selectedPeriod,
        year: _currentYear,
        month: _selectedPeriod == 'Monthly' ? _currentMonth : null,
        weekStart: _selectedPeriod == 'Weekly' ? _currentWeekStart : null,
        startDate: _customStartDate,
        endDate: _customEndDate,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load financial summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadIncomeEntries() async {
    _setLoading(true);
    try {
      _incomeEntries = await _apiService.getIncomeEntries();
      _clearError();
    } catch (e) {
      _setError('Failed to load income entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadExpenseEntries() async {
    _setLoading(true);
    try {
      _expenseEntries = await _apiService.getExpenseEntries();
      _clearError();
    } catch (e) {
      _setError('Failed to load expense entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConstructionBudget() async {
    _setLoading(true);
    try {
      _constructionBudget = await _apiService.getConstructionBudget();
      _clearError();
    } catch (e) {
      _setError('Failed to load construction budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTaxReport() async {
    _setLoading(true);
    try {
      _taxReport = await _apiService.getTaxReport();
      _clearError();
    } catch (e) {
      _setError('Failed to load tax report: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addIncomeEntry(IncomeEntry entry) async {
    _setLoading(true);
    try {
      await _apiService.addIncomeEntry(entry);
      await loadIncomeEntries();
      await loadSummary();
      _clearError();
    } catch (e) {
      _setError('Failed to add income entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpenseEntry(ExpenseEntry entry) async {
    _setLoading(true);
    try {
      await _apiService.addExpenseEntry(entry);
      await loadExpenseEntries();
      await loadSummary();
      _clearError();
    } catch (e) {
      _setError('Failed to add expense entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateConstructionBudget(ConstructionBudget budget) async {
    _setLoading(true);
    try {
      await _apiService.updateConstructionBudget(budget);
      await loadConstructionBudget();
      _clearError();
    } catch (e) {
      _setError('Failed to update construction budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (loading) {
      _loadingCounter++;
    } else {
      _loadingCounter = (_loadingCounter - 1).clamp(0, double.infinity).toInt();
    }
    
    bool newLoadingState = _loadingCounter > 0;
    if (_isLoading != newLoadingState) {
      _isLoading = newLoadingState;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> importCsvFile(String filePath, {String accountType = 'main'}) async {
    _setLoading(true);
    try {
      final result = await _apiService.importCsvFile(filePath, accountType: accountType);
      
      // Refresh all data after successful import
      await loadSummary();
      await loadIncomeEntries();
      await loadExpenseEntries();
      await loadConstructionBudget();
      
      _clearError();
      return result;
    } catch (e) {
      _setError('Failed to import CSV file: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Time period methods
  void setTimePeriod(String period) {
    _selectedPeriod = period;
    loadSummary(); // Reload data with new period
    notifyListeners();
  }

  void setCustomStartDate(DateTime date) {
    _customStartDate = date;
    if (_selectedPeriod == 'Custom') {
      loadSummary();
    }
    notifyListeners();
  }

  void setCustomEndDate(DateTime date) {
    _customEndDate = date;
    if (_selectedPeriod == 'Custom') {
      loadSummary();
    }
    notifyListeners();
  }

  // Navigation methods
  void navigatePrevious() {
    switch (_selectedPeriod) {
      case 'Monthly':
        if (_currentMonth == 1) {
          _currentMonth = 12;
          _currentYear--;
        } else {
          _currentMonth--;
        }
        break;
      case 'Yearly':
        _currentYear--;
        break;
      case 'Weekly':
        _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
        break;
    }
    loadSummary();
    notifyListeners();
  }

  void navigateNext() {
    switch (_selectedPeriod) {
      case 'Monthly':
        if (_currentMonth == 12) {
          _currentMonth = 1;
          _currentYear++;
        } else {
          _currentMonth++;
        }
        break;
      case 'Yearly':
        _currentYear++;
        break;
      case 'Weekly':
        _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
        break;
    }
    loadSummary();
    notifyListeners();
  }

  void navigateToToday() {
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    loadSummary();
    notifyListeners();
  }
  
  // Combined method to load all account management data
  Future<void> loadAccountManagementData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadUserAccountsInternal(),
        _loadSecuritiesInternal(),
      ]);
      _clearError();
    } catch (e) {
      print('Error loading account management data: $e');
      _setError('Failed to load account data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Internal method for loading user accounts (no loading state management)
  Future<void> _loadUserAccountsInternal() async {
    final response = await _apiService.get('/financial/accounts');
    if (response['success']) {
      _userAccounts = List<Map<String, dynamic>>.from(response['data']);
    }
  }

  // User Account Management Methods
  Future<void> loadUserAccounts() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/financial/accounts');
      if (response['success']) {
        _userAccounts = List<Map<String, dynamic>>.from(response['data']);
        _clearError();
      }
    } catch (e) {
      print('Error loading user accounts: $e');
      _setError('Failed to load user accounts: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> createUserAccount(String name, String type, double initialBalance) async {
    try {
      final response = await _apiService.post('/financial/accounts', {
        'name': name,
        'type': type,
        'initial_balance': initialBalance,
      });
      
      if (response['success']) {
        await loadUserAccounts(); // Refresh the list
        await loadSummary(); // Refresh summary to reflect changes
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating user account: $e');
      return false;
    }
  }
  
  Future<bool> deleteUserAccount(String accountId) async {
    try {
      final response = await _apiService.delete('/financial/accounts/$accountId');
      
      if (response['success']) {
        await loadUserAccounts(); // Refresh the list
        await loadSummary(); // Refresh summary to reflect changes
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }
  
  Future<bool> setAccountBalance(String accountType, double balance, {String? manualBalanceDate}) async {
    try {
      final requestBody = <String, dynamic>{
        'balance': balance,
      };
      
      if (manualBalanceDate != null) {
        requestBody['manual_balance_date'] = manualBalanceDate;
      }
      
      final response = await _apiService.post('/financial/accounts/$accountType/balance', requestBody);
      
      if (response['success']) {
        await loadSummary(); // Refresh summary to reflect changes
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting account balance: $e');
      return false;
    }
  }
  
  // Internal method for loading securities (no loading state management)
  Future<void> _loadSecuritiesInternal() async {
    final response = await _apiService.get('/financial/securities');
    if (response['success']) {
      _securities = List<Map<String, dynamic>>.from(response['data']);
    }
  }

  // Securities Management Methods
  Future<void> loadSecurities() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/financial/securities');
      if (response['success']) {
        _securities = List<Map<String, dynamic>>.from(response['data']);
        _clearError();
      }
    } catch (e) {
      print('Error loading securities: $e');
      _setError('Failed to load securities: $e');
    } finally {
      _setLoading(false);
    }
  }
  
    Future<Map<String, dynamic>?> getSecurityPrice(String symbol) async {
    try {
      final response = await _apiService.get('/financial/securities/$symbol/price');
      if (response['success']) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('Error getting security price: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityHistory(String symbol, int days) async {
    try {
      final response = await _apiService.get('/financial/securities/$symbol/history?days=$days');
      if (response['success']) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('Error getting security history: $e');
      return [];
    }
  }

  Future<bool> addSecurity(String symbol, String name, double quantity, double price, [String? purchaseDate]) async {
    try {
      final response = await _apiService.post('/financial/securities', {
        'symbol': symbol,
        'name': name,
        'quantity': quantity,
        'purchase_price': price,
        if (purchaseDate != null) 'purchase_date': purchaseDate,
      });
      
      if (response['success']) {
        await _loadSecuritiesInternal(); // Use internal method to avoid loading state
        notifyListeners(); // Single notification
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding security: $e');
      return false;
    }
  }

  Future<bool> deleteSecurity(String securityId) async {
    try {
      final response = await _apiService.delete('/financial/securities/$securityId');
      
      if (response['success']) {
        await _loadSecuritiesInternal(); // Use internal method to avoid loading state
        notifyListeners(); // Single notification
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting security: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> lookupSecurity(String searchQuery) async {
    try {
      final response = await _apiService.post('/financial/securities/lookup', {
        'query': searchQuery,
      });
      
      if (response['success'] && response['suggestions'] != null) {
        return List<Map<String, dynamic>>.from(response['suggestions']);
      }
      return [];
    } catch (e) {
      print('Error looking up security: $e');
      rethrow;
    }
  }
} 
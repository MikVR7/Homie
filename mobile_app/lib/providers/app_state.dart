import 'package:flutter/foundation.dart';

class AppState with ChangeNotifier {
  bool _isLoading = false;
  String _currentModule = 'dashboard';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String get currentModule => _currentModule;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setCurrentModule(String module) {
    _currentModule = module;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 
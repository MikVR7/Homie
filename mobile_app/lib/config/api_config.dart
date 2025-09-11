class ApiConfig {
  // Development/Demo configuration
  static const String baseUrl = 'http://localhost:3000/api';
  static const String environment = 'development';
  
  // Production configuration (to be updated when backend is deployed)
  static const String prodBaseUrl = 'https://api.homie.app';
  
  // Timeout configurations
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // API versioning
  static const String apiVersion = 'v1';
  
  static String get currentBaseUrl {
    return environment == 'production' ? prodBaseUrl : baseUrl;
  }
} 
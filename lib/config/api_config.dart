class ApiConfig {
  // Base URL cho API
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // Timeout cho các request
  static const Duration timeout = Duration(seconds: 10);
  
  // Headers mặc định
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String userInfo = '/auth/me';
  
  // Notification endpoints
  static const String deviceToken = '/notifications/device-token';
  
  // Message endpoints
  static const String messages = '/messages';
  static const String conversations = '/messages/conversations';
  
  // Game endpoints
  static const String games = '/games';
  static const String gamePlayers = '/game-players';
  
  // Payment endpoints
  static const String payments = '/payments';
  
  // Player endpoints
  static const String players = '/players';
} 
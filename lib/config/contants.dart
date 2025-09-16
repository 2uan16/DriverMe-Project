class AppConstants {
  // App Info
  static const String appName = 'DriverMe';
  static const String appVersion = '1.0.0';

  // API Endpoints (sẽ update sau khi có backend)
  static const String baseUrl = 'http://localhost:3000/api';

  // Map Constants
  static const double defaultZoom = 15.0;
  static const double defaultLat = 21.0285; // Hanoi
  static const double defaultLng = 105.8542;

  // Timing
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Roles
  static const String roleUser = 'user';
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';
}
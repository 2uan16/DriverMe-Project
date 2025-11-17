import 'api_keys.dart';

class AppConfig {
  AppConfig._();

  // ✅ Backend endpoints
  static final String baseUrl = '${ApiKeys.backendBaseUrl}/api';
  static final String authEndpoint = '$baseUrl/auth';
  static final String userEndpoint = '$baseUrl/users';
  static final String driverEndpoint = '$baseUrl/drivers';
  static final String bookingEndpoint = '$baseUrl/bookings';
  static final String adminEndpoint = '$baseUrl/admin';

  // ✅ Socket.io
  static final String socketUrl = ApiKeys.socketUrl;

  // ✅ Mapbox
  static const String mapboxAccessToken = ApiKeys.mapboxAccessToken;

  // ✅ Other configs
  static const bool isDevelopment = true;
  static const double defaultLatitude = 21.0285;
  static const double defaultLongitude = 105.8542;
  static const String defaultAddress = 'Hà Nội, Việt Nam';
}
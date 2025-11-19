import 'api_keys.dart';
class AppConfig {
  AppConfig._();
  static const String _apiPrefix = '/api';
  static const String authEndpoint = '$_apiPrefix/auth';
  static const String userEndpoint = '$_apiPrefix/users';
  static const String driverEndpoint = '$_apiPrefix/drivers';
  static const String bookingEndpoint = '$_apiPrefix/bookings';
  static const String adminEndpoint = '$_apiPrefix/admin';
  static final String socketUrl = ApiKeys.socketUrl;
  static const String mapboxAccessToken = ApiKeys.mapboxAccessToken;
  static const bool isDevelopment = true;
  static const double defaultLatitude = 21.0285;
  static const double defaultLongitude = 105.8542;
  static const String defaultAddress = 'Hà Nội, Việt Nam';
}
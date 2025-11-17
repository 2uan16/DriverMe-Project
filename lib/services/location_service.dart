import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _address;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get address => _address;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _currentPosition != null;

  /// Get current location with permission handling
  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Dịch vụ định vị chưa được bật';
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Quyền truy cập vị trí bị từ chối';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt';
        return false;
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      return true;
    } catch (e) {
      _errorMessage = 'Lỗi lấy vị trí: $e';
      _currentPosition = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get address from coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
      } else {
        _address = 'Không xác định được địa chỉ';
      }
    } catch (e) {
      _address = 'Lỗi lấy địa chỉ';
      print('Error getting address: $e');
    }
  }

  /// Search places by query
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> results = [];

      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          results.add({
            'name': query,
            'address': '${place.street}, ${place.subLocality}, ${place.locality}',
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }

      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Clear location data
  void clearLocation() {
    _currentPosition = null;
    _address = null;
    _errorMessage = null;
    notifyListeners();
  }
}
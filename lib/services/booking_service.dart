import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../models/car_service.dart';
import '../screens/user/payment_screen.dart';
import 'auth_service.dart';

class BookingService {
  final AuthService _authService = AuthService();

  /// Tạo booking mới
  Future<Map<String, dynamic>> createBooking({
    required String pickup,
    required LatLng pickupLatLng,
    required String dropoff,
    required LatLng dropoffLatLng,
    required CarService selectedService,
    required PaymentMethod payment,
    double? distanceKm,
    String? durationText,
    String? voucherCode,
    String? notes,
    Map<String, bool>? preferences,
  }) async {
    try {
      final bookingData = {
        'pickup_address': pickup,
        'pickup_lat': pickupLatLng.latitude,
        'pickup_lng': pickupLatLng.longitude,
        'destination_address': dropoff,
        'destination_lat': dropoffLatLng.latitude,
        'destination_lng': dropoffLatLng.longitude,
        'service_type': 'point_to_point',
        'car_type': selectedService.type.toString().split('.').last,
        'estimated_price': selectedService.price,
        'payment_method': payment.value,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (durationText != null) 'estimated_duration': durationText,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucher_code': voucherCode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (preferences != null) 'preferences': preferences,
      };

      print('📤 Creating booking: $bookingData');

      final response = await _authService.authenticatedRequest(
        method: 'POST',
        endpoint: '/api/bookings',
        body: bookingData,
      );

      final responseData = json.decode(response.body);
      print('📥 Response: $responseData');

      if (response.statusCode == 201 && responseData['success'] == true) {
        return {
          'success': true,
          'booking_id': responseData['data']?['id'] ??
              responseData['booking']?['id'] ??
              'N/A',
          'message': responseData['message'] ?? 'Đặt chuyến thành công',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Đặt chuyến thất bại',
        };
      }
    } catch (e) {
      print('❌ Booking error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}
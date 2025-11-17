/// Cấu hình bảng giá DriverMe (2025)
class PricingConfig {
  PricingConfig._();

  // ✅ VAT
  static const double vatRate = 0.08; // 8%

  // ✅ Phí nền tảng (Platform fee) - nếu có
  static const int platformFee = 0; // đ (có thể thay đổi)

  // ✅ BẢNG GIÁ THEO LOẠI XE
  static const Map<String, VehiclePricing> vehiclePricing = {
    'economy': VehiclePricing(
      baseFare: 10000, // 10,000đ
      pricePerKm: 5000, // 5,000đ/km
      pricePerMinute: 500, // 500đ/phút
    ),
    'standard': VehiclePricing(
      baseFare: 15000, // 15,000đ
      pricePerKm: 7000, // 7,000đ/km
      pricePerMinute: 700, // 700đ/phút
    ),
    'premium': VehiclePricing(
      baseFare: 25000, // 25,000đ
      pricePerKm: 10000, // 10,000đ/km
      pricePerMinute: 1000, // 1,000đ/phút
    ),
  };

  // ✅ KHUNG GIỜ CAO ĐIỂM
  static const List<PeakHourConfig> peakHours = [
    // Sáng: 6:30 - 9:00
    PeakHourConfig(
      name: 'Giờ cao điểm sáng',
      startHour: 6,
      startMinute: 30,
      endHour: 9,
      endMinute: 0,
      surchargeRate: 0.20, // +20%
    ),
    // Chiều: 16:30 - 19:00
    PeakHourConfig(
      name: 'Giờ cao điểm chiều',
      startHour: 16,
      startMinute: 30,
      endHour: 19,
      endMinute: 0,
      surchargeRate: 0.20, // +20%
    ),
    // Đêm muộn: 22:00 - 5:00
    PeakHourConfig(
      name: 'Giờ cao điểm đêm',
      startHour: 22,
      startMinute: 0,
      endHour: 5,
      endMinute: 0,
      surchargeRate: 0.15, // +15%
      isOvernight: true, // Qua đêm (22h hôm nay -> 5h hôm sau)
    ),
  ];
}

// ✅ MODEL: Vehicle Pricing
class VehiclePricing {
  final int baseFare; // Giá mở cửa (đ)
  final int pricePerKm; // Giá theo km (đ/km)
  final int pricePerMinute; // Giá theo phút (đ/phút)

  const VehiclePricing({
    required this.baseFare,
    required this.pricePerKm,
    required this.pricePerMinute,
  });
}

// ✅ MODEL: Peak Hour Config
class PeakHourConfig {
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double surchargeRate; // Hệ số phụ phí (0.20 = +20%)
  final bool isOvernight; // Có qua đêm không

  const PeakHourConfig({
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.surchargeRate,
    this.isOvernight = false,
  });

  /// Kiểm tra thời gian có trong khung giờ này không
  bool isInPeakHour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final currentMinutes = hour * 60 + minute;

    if (!isOvernight) {
      // Khung giờ thường (trong ngày)
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Khung giờ qua đêm (22:00 -> 5:00)
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;

      // Từ 22:00 đến 24:00 hoặc từ 0:00 đến 5:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }
}
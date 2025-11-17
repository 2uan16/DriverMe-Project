import '../config/pricing_config.dart';
import '../models/car_service.dart';

/// Service tính giá chuyến đi
class PricingService {
  PricingService._();

  /// ✅ TÍNH TỔNG GIÁ CHUYẾN ĐI
  ///
  /// Công thức:
  /// Tổng giá = ((Base + km*giáKm + phút*giáPhút) * HệSốGiờCaoĐiểm + PhíNềnTảng) * 1.08
  static PricingResult calculatePrice({
    required CarType carType,
    required double distanceKm,
    required int durationMinutes,
    DateTime? bookingTime,
    int? voucherDiscount,
  }) {
    // 1. Lấy bảng giá theo loại xe
    final vehiclePricing = _getVehiclePricing(carType);

    // 2. Tính giá cơ bản (chưa có phụ phí)
    final baseFare = vehiclePricing.baseFare;
    final distanceFare = (distanceKm * vehiclePricing.pricePerKm).round();
    final timeFare = (durationMinutes * vehiclePricing.pricePerMinute).round();

    final subtotal = baseFare + distanceFare + timeFare;

    // 3. Kiểm tra giờ cao điểm
    final peakHourInfo = _getPeakHourInfo(bookingTime ?? DateTime.now());
    final surchargeRate = peakHourInfo['rate'] as double;
    final peakHourName = peakHourInfo['name'] as String?;

    // 4. Áp dụng hệ số giờ cao điểm
    final surchargeAmount = (subtotal * surchargeRate).round();
    final priceAfterSurcharge = subtotal + surchargeAmount;

    // 5. Thêm phí nền tảng (nếu có)
    final platformFee = PricingConfig.platformFee;
    final priceWithPlatformFee = priceAfterSurcharge + platformFee;

    // 6. Áp dụng mã giảm giá (nếu có)
    final discount = voucherDiscount ?? 0;
    final priceAfterDiscount = priceWithPlatformFee - discount;

    // 7. Tính VAT
    final vatAmount = (priceAfterDiscount * PricingConfig.vatRate).round();
    final finalPrice = priceAfterDiscount + vatAmount;

    // 8. Return kết quả chi tiết
    return PricingResult(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      subtotal: subtotal,
      surchargeRate: surchargeRate,
      surchargeAmount: surchargeAmount,
      peakHourName: peakHourName,
      platformFee: platformFee,
      discount: discount,
      vatAmount: vatAmount,
      finalPrice: finalPrice,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  /// Lấy bảng giá theo loại xe
  static VehiclePricing _getVehiclePricing(CarType carType) {
    switch (carType) {
      case CarType.economy:
        return PricingConfig.vehiclePricing['economy']!;
      case CarType.standard:
        return PricingConfig.vehiclePricing['standard']!;
      case CarType.premium:
        return PricingConfig.vehiclePricing['premium']!;
    }
  }

  /// Kiểm tra giờ cao điểm
  static Map<String, dynamic> _getPeakHourInfo(DateTime dateTime) {
    for (final peakHour in PricingConfig.peakHours) {
      if (peakHour.isInPeakHour(dateTime)) {
        return {
          'rate': peakHour.surchargeRate,
          'name': peakHour.name,
        };
      }
    }

    // Không phải giờ cao điểm
    return {
      'rate': 0.0,
      'name': null,
    };
  }

  /// ✅ FORMAT GIÁ THÀNH CHUỖI
  static String formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write('.');
    }
    return '${buf.toString()}đ';
  }

  /// ✅ ESTIMATE GIÁ NHANH (cho preview)
  static int estimatePrice({
    required CarType carType,
    required double distanceKm,
  }) {
    final vehiclePricing = _getVehiclePricing(carType);

    // Estimate duration (giả sử 30km/h)
    final durationMinutes = ((distanceKm / 30) * 60).round();

    final result = calculatePrice(
      carType: carType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );

    return result.finalPrice;
  }
}

/// ✅ MODEL: Kết quả tính giá
class PricingResult {
  final int baseFare; // Giá mở cửa
  final int distanceFare; // Phí quãng đường
  final int timeFare; // Phí thời gian
  final int subtotal; // Tổng trước phụ phí
  final double surchargeRate; // Hệ số phụ phí (0.2 = 20%)
  final int surchargeAmount; // Số tiền phụ phí
  final String? peakHourName; // Tên khung giờ (nếu có)
  final int platformFee; // Phí nền tảng
  final int discount; // Giảm giá
  final int vatAmount; // Tiền VAT
  final int finalPrice; // Tổng cuối cùng
  final double distanceKm; // Khoảng cách
  final int durationMinutes; // Thời gian

  const PricingResult({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.subtotal,
    required this.surchargeRate,
    required this.surchargeAmount,
    this.peakHourName,
    required this.platformFee,
    required this.discount,
    required this.vatAmount,
    required this.finalPrice,
    required this.distanceKm,
    required this.durationMinutes,
  });

  /// Có phụ phí giờ cao điểm không?
  bool get hasSurcharge => surchargeAmount > 0;

  /// % phụ phí (20%, 15%...)
  String get surchargePercentage => '+${(surchargeRate * 100).round()}%';

  /// Breakdown giá (để hiển thị cho user)
  Map<String, dynamic> toBreakdown() {
    return {
      'Giá mở cửa': baseFare,
      'Phí quãng đường (${distanceKm.toStringAsFixed(1)}km)': distanceFare,
      'Phí thời gian ($durationMinutes phút)': timeFare,
      if (hasSurcharge)
        'Phụ phí $peakHourName ($surchargePercentage)': surchargeAmount,
      if (platformFee > 0) 'Phí nền tảng': platformFee,
      if (discount > 0) 'Giảm giá': -discount,
      'VAT (8%)': vatAmount,
      'Tổng cộng': finalPrice,
    };
  }
}
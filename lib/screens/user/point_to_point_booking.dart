import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'trip_tracking_screen.dart';

// Config
import '../../config/api_keys.dart';

// Services
import '../../services/location_service.dart';
import '../../services/booking_service.dart';
import '../../services/pricing_service.dart';

// Models
import '../../models/car_service.dart';

// Widgets
import '../../widgets/mapbox_widget.dart';
import '../../widgets/booking/round_icon_button.dart';
import '../../widgets/booking/pickup_drop_card.dart';
import '../../widgets/booking/booking_bottom_panel.dart';
import '../../widgets/booking/action_buttons_row.dart';

// Screens
import 'search_destination_screen.dart';
import 'voucher_screen.dart';
import 'payment_screen.dart';

class PointToPointBookingScreen extends StatefulWidget {
  const PointToPointBookingScreen({super.key});

  @override
  State<PointToPointBookingScreen> createState() => _PointToPointBookingScreenState();
}

class _PointToPointBookingScreenState extends State<PointToPointBookingScreen> {
  final BookingService _bookingService = BookingService();

  //Location data
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? pickup;
  String? dropoff;
  bool locating = true;

  List<CarService> services = [];
  int selectedServiceIndex = 0;

  //Route info
  double? _distanceKm;
  String? _distanceText;
  String? _durationText;

  //Booking options
  String? voucherCode;
  PaymentMethod payment = const PaymentMethod.cash();
  bool noteFemaleDriver = false;
  bool noteEnglish = false;
  bool noteNoEV = false;
  bool noteInvoice = false;
  String notesText = '';

  //State
  bool _isBooking = false;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final loc = context.read<LocationService>();
    final ok = await loc.getCurrentLocation();

    if (!mounted) return;

    if (ok && loc.currentPosition != null) {
      final pos = loc.currentPosition!;
      _pickupLatLng = LatLng(pos.latitude, pos.longitude);
      pickup = loc.address ?? 'Vị trí của tôi';
    } else {
      pickup = loc.errorMessage ?? 'Vị trí của tôi (chưa cấp quyền)';
    }
    locating = false;
    setState(() {});
  }

  // MAPBOX — Geocoding + Directions
  Future<LatLng?> _mapboxGeocode(String query) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
          '?access_token=${ApiKeys.mapboxAccessToken}&limit=1&language=vi',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    final feats = (data['features'] as List?) ?? [];
    if (feats.isEmpty) return null;
    final center = feats.first['center'] as List<dynamic>; // [lng, lat]
    return LatLng(center[1].toDouble(), center[0].toDouble());
  }

  Future<void> _getRouteDirections(LatLng from, LatLng to) async {
    setState(() {
      _isRouting = true;
      _distanceKm = null;
      _distanceText = null;
      _durationText = null;
      services = [];
    });

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?access_token=${ApiKeys.mapboxAccessToken}'
          '&geometries=geojson&overview=full&steps=false&language=vi',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) {
        _showSnackBar('Không lấy được tuyến đường (Mapbox ${res.statusCode})');
        setState(() => _isRouting = false);
        return;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        _showSnackBar('Không tìm thấy tuyến phù hợp');
        setState(() => _isRouting = false);
        return;
      }

      final r = routes.first as Map<String, dynamic>;
      final distanceMeters = (r['distance'] as num).toDouble();
      final durationSeconds = (r['duration'] as num).toDouble();

      final km = distanceMeters / 1000.0;
      final minutes = (durationSeconds / 60).round();

      final distanceText = km < 1 ? '${distanceMeters.round()}m' : '${km.toStringAsFixed(1)}km';
      final durationText = minutes < 60
          ? '$minutes phút'
          : (() {
        final h = minutes ~/ 60;
        final m = minutes % 60;
        return m == 0 ? '$h giờ' : '$h giờ $m phút';
      })();

      final built = _buildServices(km, minutes, distanceText, durationText);

      setState(() {
        _distanceKm = km;
        _distanceText = distanceText;
        _durationText = durationText;
        services = built;
        _isRouting = false;
      });
    } catch (e) {
      setState(() => _isRouting = false);
      _showSnackBar('Lỗi tuyến đường: $e');
    }
  }
  // SERVICES (Xây CHỈ khi đã có tuyến) — Ẩn giá trước đó
  List<CarService> _buildServices(
      double km,
      int durationMin,
      String distanceText,
      String durationText,
      ) {
    return [
      _buildCarService(CarType.economy, km, durationMin, distanceText, durationText),
      _buildCarService(CarType.standard, km, durationMin, distanceText, durationText),
      _buildCarService(CarType.premium, km, durationMin, distanceText, durationText),
    ];
  }

  CarService _buildCarService(
      CarType type,
      double km,
      int durationMin,
      String distanceText,
      String durationText,
      ) {
    final pricing = PricingService.calculatePrice(
      carType: type,
      distanceKm: km,
      durationMinutes: durationMin,
      bookingTime: DateTime.now(),
    );

    String name, capacity;
    switch (type) {
      case CarType.economy:
        name = 'Xe phổ thông';
        capacity = '4 chỗ';
        break;
      case CarType.standard:
        name = 'Xe tầm trung';
        capacity = '4–5 chỗ';
        break;
      case CarType.premium:
        name = 'Xe hạng sang';
        capacity = '4–7 chỗ';
        break;
    }

    final subtitle = pricing.hasSurcharge
        ? '$distanceText • $durationText • ${pricing.surchargePercentage}'
        : '$distanceText • $durationText';

    return CarService(
      type: type,
      name: name,
      capacity: capacity,
      etaMin: type == CarType.economy ? 7 : (type == CarType.standard ? 6 : 5),
      subtitle: subtitle,
      price: pricing.finalPrice,
      originalPrice: pricing.hasSurcharge ? pricing.subtotal + pricing.vatAmount : null,
    );
  }

  int _parseDuration(String durationText) {
    final hourMatch = RegExp(r'(\d+)\s*giờ').firstMatch(durationText);
    final minuteMatch = RegExp(r'(\d+)\s*phút').firstMatch(durationText);
    int hours = 0, minutes = 0;
    if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
    if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);
    return hours * 60 + minutes;
  }
  // USER ACTIONS
  Future<void> _refreshLocation() async {
    final loc = context.read<LocationService>();
    final ok = await loc.getCurrentLocation();
    if (ok && loc.currentPosition != null) {
      final pos = loc.currentPosition!;
      _pickupLatLng = LatLng(pos.latitude, pos.longitude);
      pickup = loc.address ?? 'Vị trí của tôi';
      _resetAfterAddressChange();
      if (_dropoffLatLng != null) {
        await _getRouteDirections(_pickupLatLng!, _dropoffLatLng!);
      }
      setState(() {});
    } else {
      _showSnackBar(loc.errorMessage ?? 'Không lấy được vị trí');
    }
  }

  Future<void> _selectPickup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchDestinationScreen(
          title: 'Bạn muốn đón ở đâu?',
          hint: 'Nhập địa chỉ đón',
        ),
      ),
    );

    if (result is String && result.isNotEmpty) {
      final latlng = await _mapboxGeocode(result);
      if (latlng == null) {
        _showSnackBar('Không tìm thấy địa chỉ');
        return;
      }
      setState(() {
        pickup = result;
        _pickupLatLng = latlng;
        _resetAfterAddressChange();
      });
      if (_dropoffLatLng != null) {
        await _getRouteDirections(_pickupLatLng!, _dropoffLatLng!);
      }
    }
  }

  Future<void> _selectDropoff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchDestinationScreen(
          title: 'Bạn muốn đến đâu?',
          hint: 'Nhập địa chỉ đến',
        ),
      ),
    );

    if (result is String && result.isNotEmpty) {
      final latlng = await _mapboxGeocode(result);
      if (latlng == null) {
        _showSnackBar('Không tìm thấy địa chỉ');
        return;
      }
      setState(() {
        dropoff = result;
        _dropoffLatLng = latlng;
        _resetAfterAddressChange();
      });
      if (_pickupLatLng != null) {
        await _getRouteDirections(_pickupLatLng!, _dropoffLatLng!);
      }
    }
  }

  void _swapLocations() {
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      final tmpLatLng = _pickupLatLng; _pickupLatLng = _dropoffLatLng; _dropoffLatLng = tmpLatLng;
      final tmpAddr = pickup; pickup = dropoff; dropoff = tmpAddr;
      _resetAfterAddressChange();
      _getRouteDirections(_pickupLatLng!, _dropoffLatLng!);
      setState(() {});
    }
  }

  void _resetAfterAddressChange() {
    //Mỗi khi đổi địa chỉ → ẨN GIÁ + xoá dịch vụ cho tới khi có route mới
    _distanceKm = null;
    _distanceText = null;
    _durationText = null;
    services = [];
    selectedServiceIndex = 0;
  }

  Future<void> _onPromoTap() async {
    final code = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => VoucherScreen(initialCode: voucherCode)),
    );
    if (!mounted) return;
    setState(() {
      voucherCode = (code ?? '').trim().isEmpty ? null : code!.trim();
      // đổi ưu đãi không tính lại route; PricingService tự áp dụng khi tạo booking
    });
  }

  Future<void> _openPayment() async {
    final selected = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(initial: payment)),
    );
    if (!mounted) return;
    if (selected != null) setState(() => payment = selected);
  }

  Future<void> _openNotesSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Ghi chú cho tài xế', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                maxLines: 4,
                controller: TextEditingController(text: notesText),
                decoration: const InputDecoration(hintText: 'Nhập ghi chú...', border: OutlineInputBorder()),
                onChanged: (v) => notesText = v,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(title: const Text('Tài xế nữ'), value: noteFemaleDriver, onChanged: (v) => setState(() => noteFemaleDriver = v ?? false)),
              CheckboxListTile(title: const Text('Tài xế nói tiếng Anh'), value: noteEnglish, onChanged: (v) => setState(() => noteEnglish = v ?? false)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Xong')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tùy chọn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(title: const Text('Xe số sàn'), value: noteNoEV, onChanged: (v) => setState(() => noteNoEV = v ?? false)),
            CheckboxListTile(title: const Text('Xe số tự động'), value: noteNoEV, onChanged: (v) => setState(() => noteNoEV = v ?? false)),
            CheckboxListTile(title: const Text('Xuất hóa đơn'), value: noteInvoice, onChanged: (v) => setState(() => noteInvoice = v ?? false)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Xong')),
          ],
        ),
      ),
    );
  }

  // BOOKING
  Future<void> _onBooking() async {
    if (_pickupLatLng == null || _dropoffLatLng == null || _distanceKm == null) {
      _showSnackBar('Vui lòng chọn điểm đón/điểm đến và chờ tính giá');
      return;
    }

    setState(() => _isBooking = true);

    try {
      final selected = services[selectedServiceIndex];
      
      // 1. Create the Booking
      final result = await _bookingService.createBooking(
        pickup: pickup!,
        pickupLatLng: _pickupLatLng!,
        dropoff: dropoff!,
        dropoffLatLng: _dropoffLatLng!,
        selectedService: selected,
        payment: payment,
        distanceKm: _distanceKm,
        durationText: _durationText,
        voucherCode: voucherCode,
        notes: notesText.isEmpty ? null : notesText,
        preferences: {
          'female_driver': noteFemaleDriver,
          'english_speaking': noteEnglish,
          'no_ev': noteNoEV,
          'invoice_required': noteInvoice,
        },
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final bookingId = result['booking_id'].toString();
        
        // 2. Show "Finding Driver" Dialog & Start Polling
        _showFindingDriverDialog(bookingId);
        
      } else {
        _showSnackBar(result['message'] ?? 'Đặt chuyến thất bại');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showFindingDriverDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (context) => _FindingDriverDialog(
        bookingId: bookingId,
        bookingService: _bookingService,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final canBook = pickup != null && dropoff != null && _distanceKm != null && !locService.isLoading && !_isRouting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mapbox map hiển thị điểm đón/trả
          Positioned.fill(
            child: MapboxWidget(
              pickup: _pickupLatLng,
              destination: _dropoffLatLng,
              onLocationSelected: (position) {},
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: RoundIconButton(
                icon: Icons.arrow_back,
                onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                    context.go('/user-home');
                  }
                },
              ),
            ),
          ),

          // Cảd cho Điểm đón / trả
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
                child: PickupDropCard(
                  pickupTitle: locService.isLoading ? 'Đang xác định điểm đón…' : 'Điểm đón',
                  pickup: pickup ?? 'Vị trí của tôi',
                  dropoff: dropoff,
                  distanceText: _distanceText,
                  durationText: _durationText,
                  onUseMyLocation: _refreshLocation,
                  onPickTap: _selectPickup,
                  onDropTap: _selectDropoff,
                  onSwap: _swapLocations,
                ),
              ),
            ),
          ),

          BookingBottomPanel(
            services: services,
            selectedServiceIndex: selectedServiceIndex,
            onServiceSelected: (index) => setState(() => selectedServiceIndex = index),
            actionButtons: [
              ActionButton(icon: Icons.local_offer, label: 'Ưu đãi', onTap: _onPromoTap),
              ActionButton(icon: Icons.edit_note, label: 'Ghi chú', onTap: _openNotesSheet),
              ActionButton(icon: Icons.tune, label: 'Tùy chọn', onTap: _openOptionsSheet),
              ActionButton(icon: Icons.payment, label: payment.display.length > 8 ? 'TT' : payment.display, onTap: _openPayment),
            ],
            canBook: canBook,
            isBooking: _isBooking || _isRouting,
            onBookTap: _onBooking,
          ),
        ],
      ),
    );
  }
}

//Class tìm tài xế
class _FindingDriverDialog extends StatefulWidget {
  final String bookingId;
  final BookingService bookingService;

  const _FindingDriverDialog({
    required this.bookingId,
    required this.bookingService,
  });

  @override
  State<_FindingDriverDialog> createState() => _FindingDriverDialogState();
}

class _FindingDriverDialogState extends State<_FindingDriverDialog> {
  Timer? _timer;
  bool _driverFound = false;
  Map<String, dynamic>? _bookingData;
  int _countdown = 5; // Auto-redirect countdown

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final result = await widget.bookingService.getBookingStatus(widget.bookingId);
      
      if (result['success'] == true) {
        final booking = result['booking'];
        final status = booking['status'];

        // If driver accepted
        if (status == 'accepted' || status == 'in_progress') {
          _timer?.cancel(); // Stop polling
          if (mounted) {
            setState(() {
              _driverFound = true;
              _bookingData = booking;
            });
            _startRedirectCountdown();
          }
        }
      }
    });
  }

  void _startRedirectCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _goToTrackingScreen();
        }
      });
    });
  }

  void _goToTrackingScreen() {
    Navigator.pop(context); // Close Dialog
    
    // Navigate to Trip Tracking with Booking ID
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (_) => TripTrackingScreen(bookingId: widget.bookingId)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // VIEW 1: Finding Driver
    if (!_driverFound) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF08B24B)),
              const SizedBox(height: 20),
              const Text("Đang tìm tài xế...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Vui lòng chờ trong giây lát", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.pop(context); // Cancel finding
                  // TODO: Call API to cancel booking
                },
                child: const Text("Hủy tìm kiếm", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        ),
      );
    }

    // VIEW 2: Driver Found!
    final driverName = _bookingData?['driver_name'] ?? 'Tài xế DriverMe';
    // Mock rating since backend might not send it yet
    const driverRating = 4.9; 
    
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 12),
            const Text("Tài xế đã nhận chuyến!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Driver Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: const [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(" $driverRating", style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToTrackingScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08B24B),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Theo dõi chuyến đi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text("Tự động chuyển sau $_countdown s", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

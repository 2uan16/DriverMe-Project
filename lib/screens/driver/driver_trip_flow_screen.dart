import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

enum DriverStep { accepted, arrived, onTrip, completed }

class DriverTripFlowScreen extends StatefulWidget {
  final String? bookingId;

  const DriverTripFlowScreen({
    super.key, 
    this.bookingId, 
  });

  @override
  State<DriverTripFlowScreen> createState() => _DriverTripFlowScreenState();
}

class _DriverTripFlowScreenState extends State<DriverTripFlowScreen> {
  DriverStep _currentStep = DriverStep.accepted;

  // Data Mock (Replace with API data later)
  final String _pickup = "Royal City, 72 Nguyễn Trãi";
  final String _dropoff = "Hồ Gươm, Hoàn Kiếm";
  final double _fare = 120000;
  final double _commissionRate = 0.20; // 20% platform fee
  final double _driverWalletBalance = 500000; // Mock wallet balance

  Future<void> _nextStep() async {
    setState(() {
      switch (_currentStep) {
        case DriverStep.accepted:
          _currentStep = DriverStep.arrived;
          break;
        case DriverStep.arrived:
          _currentStep = DriverStep.onTrip;
          break;
        case DriverStep.onTrip:
          _currentStep = DriverStep.completed;
          break;
        case DriverStep.completed:
          _finishTrip();
          break;
      }
    });
  }

  void _finishTrip() {
    // 1. TODO: Call API to complete booking here
    // await _bookingService.completeBooking(widget.bookingId);
    
    // 2. Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn thành chuyến và cập nhật ví!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 3. Navigate back to Home
    // Using go() replaces the stack, preventing back navigation to this trip
    if (mounted) {
       context.go('/driver-home'); 
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case DriverStep.accepted: return "Đã đến điểm đón";
      case DriverStep.arrived: return "Bắt đầu chuyến đi";
      case DriverStep.onTrip: return "Hoàn thành chuyến";
      case DriverStep.completed: return "Xác nhận thanh toán & Kết thúc";
    }
  }

  Color _getButtonColor() {
    return _currentStep == DriverStep.completed ? Colors.green : const Color(0xFF08B24B);
  }

  Future<void> _openMaps() async {
    // Destination address based on current step
    final query = _currentStep == DriverStep.onTrip ? _dropoff : _pickup;
    
    // Google Maps Universal Link
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở bản đồ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate financials for receipt
    final double commissionFee = _fare * _commissionRate;
    final double netIncome = _fare - commissionFee;
    final double newWalletBalance = _driverWalletBalance - commissionFee;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          Positioned.fill(
            child: Container(
              color: Colors.blueGrey[50], 
              child: const Center(child: Text("Navigation Map Area", style: TextStyle(color: Colors.grey))),
            )
          ),

          // 2. Top Action Bar (Navigation) - Hidden on Receipt screen
          if (_currentStep != DriverStep.completed)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.turn_right, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentStep == DriverStep.onTrip ? "Đi đến điểm trả" : "Đi đến điểm đón",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              _currentStep == DriverStep.onTrip ? _dropoff : _pickup,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.blueAccent),
                        onPressed: _openMaps,
                      )
                    ],
                  ),
                ),
              ),
            ),

          // 3. Bottom Control Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info (Hidden on Receipt)
                  if (_currentStep != DriverStep.completed) ...[
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Khách hàng A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Thanh toán tiền mặt", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.message, color: Colors.blue), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Receipt (Only for Completed) - "Thu tiền & biên lai"
                  if (_currentStep == DriverStep.completed) ...[
                    const Center(
                      child: Text(
                        "BIÊN LAI THU TIỀN",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Total Amount Large Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text("Tổng tiền thu khách (Tiền mặt)", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            "${_fare.toStringAsFixed(0)}đ",
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Details
                    _buildReceiptRow("Cước phí chuyến đi", "${_fare.toStringAsFixed(0)}đ"),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                      "Phí nền tảng (${(_commissionRate * 100).toStringAsFixed(0)}%)", 
                      "-${commissionFee.toStringAsFixed(0)}đ",
                      isNegative: true
                    ),
                    const Divider(height: 24),
                    _buildReceiptRow(
                      "Thu nhập thực nhận", 
                      "${netIncome.toStringAsFixed(0)}đ", 
                      isBold: true
                    ),
                    const SizedBox(height: 16),
                    
                    // Wallet Impact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Số dư ví sau chuyến:", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                          Text("${newWalletBalance.toStringAsFixed(0)}đ", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_getButtonText(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87
          )
        ),
        Text(
          value, 
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? Colors.red : Colors.black87
          )
        ),
      ],
    );
  }
}
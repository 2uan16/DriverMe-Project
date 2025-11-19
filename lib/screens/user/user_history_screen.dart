import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _completedTrips = [];
  List<Map<String, dynamic>> _cancelledTrips = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get current User ID
      final user = _authService.user;
      final userId = user?['uid']?.toString(); // Ensure we match the 'uid' field

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch all bookings
      final res = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: AppConfig.bookingEndpoint,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final allBookings = data['bookings'] as List<dynamic>;

          // 3. Filter bookings for THIS user
          final myBookings = allBookings.where((b) {
            // Check if user_id matches (handle both string/int types)
            return b['user_id']?.toString() == userId;
          }).toList();

          setState(() {
            _completedTrips = myBookings
                .where((b) => b['status'] == 'completed')
                .cast<Map<String, dynamic>>()
                .toList();
            
            _cancelledTrips = myBookings
                .where((b) => b['status'] == 'cancelled')
                .cast<Map<String, dynamic>>()
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lịch sử chuyến đi'),
        backgroundColor: const Color(0xFF08B24B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF08B24B)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(_completedTrips, isCompleted: true),
                _buildTripList(_cancelledTrips, isCompleted: false),
              ],
            ),
    );
  }

  Widget _buildTripList(List<Map<String, dynamic>> trips, {required bool isCompleted}) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.history : Icons.cancel_presentation,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'Chưa có chuyến đi nào' : 'Chưa có chuyến hủy nào',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Sort by newest first (assuming booking_time exists, else keep order)
    trips.sort((a, b) {
      final timeA = a['booking_time'] ?? '';
      final timeB = b['booking_time'] ?? '';
      return timeB.compareTo(timeA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(trips[index], isCompleted);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> trip, bool isCompleted) {
    final pickup = trip['pickup_address'] ?? 'N/A';
    final dropoff = trip['destination_address'] ?? 'N/A';
    final price = trip['final_price'] ?? trip['estimated_price'] ?? 0;
    final dateStr = trip['booking_time'] ?? DateTime.now().toString();
    final serviceType = trip['service_type'] == 'hourly' ? 'Thuê theo giờ' : 'Điểm - Điểm';
    
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${price.toString()}đ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF08B24B)),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Locations
            _buildLocationRow(Icons.radio_button_checked, Colors.green, pickup),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.location_on, Colors.red, dropoff),
            
            const SizedBox(height: 16),
            
            // Footer: Service Type & Status
            Row(
              children: [
                Icon(
                  trip['service_type'] == 'hourly' ? Icons.access_time : Icons.directions_car,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(serviceType, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text('Đã hủy', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                else 
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Hoàn thành', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
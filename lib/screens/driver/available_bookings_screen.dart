import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class AvailableBookingsScreen extends StatefulWidget {
  const AvailableBookingsScreen({super.key});

  @override
  State<AvailableBookingsScreen> createState() => _AvailableBookingsScreenState();
}

class _AvailableBookingsScreenState extends State<AvailableBookingsScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _availableBookings = [];
  bool _loading = false;
  String _filter = 'all'; // all, point_to_point, hourly

  @override
  void initState() {
    super.initState();
    _loadAvailableBookings();
  }

  Future<void> _loadAvailableBookings() async {
    setState(() => _loading = true);

    try {
      final res = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: AppConfig.bookingEndpoint,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final allBookings = data['bookings'] as List<dynamic>;

          // Filter only pending bookings (available for drivers to accept)
          setState(() {
            _availableBookings = allBookings
                .where((booking) => booking['status'] == 'pending')
                .cast<Map<String, dynamic>>()
                .toList();
          });
        }
      } else {
        _showSnackBar('Không thể tải danh sách chuyến');
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nhận chuyến'),
        content: const Text('Bạn có chắc muốn nhận chuyến này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Nhận chuyến'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _authService.authenticatedRequest(
        method: 'PATCH',
        endpoint: '${AppConfig.bookingEndpoint}/$bookingId/accept',
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        _showSnackBar(data['message'], isError: false);
        _loadAvailableBookings(); // Refresh list
      } else {
        _showSnackBar(data['message'] ?? 'Không thể nhận chuyến');
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_filter == 'all') return _availableBookings;
    return _availableBookings
        .where((booking) => booking['service_type'] == _filter)
        .toList();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến Có Thể Nhận'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver-home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab('Tất cả', 'all', _availableBookings.length),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'Điểm-Điểm',
                    'point_to_point',
                    _availableBookings.where((b) => b['service_type'] == 'point_to_point').length,
                  ),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'Theo giờ',
                    'hourly',
                    _availableBookings.where((b) => b['service_type'] == 'hourly').length,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bookings List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadAvailableBookings,
              child: _buildBookingsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String value, int count) {
    final isSelected = _filter == value;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final filteredBookings = _filteredBookings;

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có chuyến nào để nhận',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy kiểm tra lại sau',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id']?.toString() ?? '';
    final pickup = booking['pickup_address']?.toString() ?? '';
    final destination = booking['destination_address']?.toString() ?? '';
    final serviceType = booking['service_type']?.toString() ?? '';
    final price = booking['estimated_price']?.toString() ?? '0';
    final notes = booking['notes']?.toString() ?? '';
    final userName = booking['user_name']?.toString() ?? '';
    final userPhone = booking['user_phone']?.toString() ?? '';
    final durationHours = booking['duration_hours'];
    final bookingTime = booking['booking_time']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: serviceType == 'hourly' ? Colors.orange[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        serviceType == 'hourly' ? Icons.access_time : Icons.directions_car,
                        size: 16,
                        color: serviceType == 'hourly' ? Colors.orange[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        serviceType == 'hourly' ? 'Theo giờ' : 'Điểm-Điểm',
                        style: TextStyle(
                          color: serviceType == 'hourly' ? Colors.orange[700] : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: $id',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer Info
            if (userName.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (userPhone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• $userPhone',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Locations
            if (pickup.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.radio_button_checked, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickup,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (destination.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(destination),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Duration for hourly service
            if (serviceType == 'hourly' && durationHours != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Thời gian: ${durationHours}h',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Notes
            if (notes.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Price and time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${price} VNĐ',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (bookingTime.isNotEmpty)
                  Text(
                    _formatTime(bookingTime),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _acceptBooking(id),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Nhận Chuyến'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } catch (e) {
      return timeString;
    }
  }
}
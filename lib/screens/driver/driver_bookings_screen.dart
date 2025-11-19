import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class DriverBookingsScreen extends StatefulWidget {
  const DriverBookingsScreen({super.key});

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyBookings() async {
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
          final driverId = _authService.user?['uid']?.toString();

          // Filter bookings assigned to this driver
          final myBookings = allBookings
              .where((booking) => booking['driver_id']?.toString() == driverId)
              .cast<Map<String, dynamic>>()
              .toList();

          setState(() {
            _activeBookings = myBookings
                .where((b) => ['accepted', 'in_progress'].contains(b['status']))
                .toList();
            _completedBookings = myBookings
                .where((b) => ['completed', 'cancelled'].contains(b['status']))
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

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final res = await _authService.authenticatedRequest(
        method: 'PATCH',
        endpoint: '${AppConfig.bookingEndpoint}/$bookingId/status',
        body: {'status': newStatus},
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        _showSnackBar(_getStatusMessage(newStatus), isError: false);
        _loadMyBookings(); // Refresh list
      } else {
        _showSnackBar(data['message'] ?? 'Không thể cập nhật trạng thái');
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e');
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'in_progress':
        return 'Đã bắt đầu chuyến đi';
      case 'completed':
        return 'Đã hoàn thành chuyến';
      case 'cancelled':
        return 'Đã hủy chuyến';
      default:
        return 'Đã cập nhật trạng thái';
    }
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
        title: const Text('Chuyến Của Tôi'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver-home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Đang làm (${_activeBookings.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Hoàn thành (${_completedBookings.length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(_activeBookings, isActive: true),
          _buildBookingsList(_completedBookings, isActive: false),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.work_off : Icons.history_toggle_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'Không có chuyến nào đang làm'
                  : 'Chưa có chuyến hoàn thành',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Hãy nhận chuyến từ danh sách có sẵn'
                  : 'Lịch sử sẽ hiển thị ở đây',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {required bool isActive}) {
    final id = booking['id']?.toString() ?? '';
    final pickup = booking['pickup_address']?.toString() ?? '';
    final destination = booking['destination_address']?.toString() ?? '';
    final serviceType = booking['service_type']?.toString() ?? '';
    final price = booking['estimated_price']?.toString() ?? '0';
    final status = booking['status']?.toString() ?? '';
    final userName = booking['user_name']?.toString() ?? '';
    final userPhone = booking['user_phone']?.toString() ?? '';
    final durationHours = booking['duration_hours'];
    final notes = booking['notes']?.toString() ?? '';

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
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: serviceType == 'hourly' ? Colors.orange[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    serviceType == 'hourly' ? 'Theo giờ' : 'Điểm-Điểm',
                    style: TextStyle(
                      color: serviceType == 'hourly' ? Colors.orange[700] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer Info
            if (userName.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (userPhone.isNotEmpty)
                            Text(
                              userPhone,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive && userPhone.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _showSnackBar('Tính năng gọi điện đang phát triển', isError: false);
                        },
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Gọi khách hàng',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Route Info
            Column(
              children: [
                if (pickup.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đón: $pickup',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                if (destination.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Đến: $destination'),
                      ),
                    ],
                  ),
                ],

                if (serviceType == 'hourly' && durationHours != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Thời gian: ${durationHours}h'),
                    ],
                  ),
                ],

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ghi chú: $notes',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${price} VNĐ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
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
            ),

            // Action buttons for active bookings
            if (isActive) ...[
              const SizedBox(height: 16),
              _buildActionButtons(id, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String bookingId, String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Hủy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _updateBookingStatus(bookingId, 'in_progress'),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Bắt đầu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateBookingStatus(bookingId, 'completed'),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Đã nhận';
      case 'in_progress':
        return 'Đang làm';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
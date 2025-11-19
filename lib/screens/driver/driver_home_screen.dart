import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'incoming_request_popup.dart'; // Ensure this import is correct

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();
  bool _isAvailable = false;
  bool _loading = false;
  Timer? _simulationTimer;

  // ✅ ADDED: State variable for the driver's name
  String _driverName = 'Tài xế'; 
  int _todayTrips = 0;
  double _todayEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();
    _loadTodayStats(); 
  }

  // ✅ UPDATED: Fetch name from AuthService cache
  Future<void> _loadDriverStatus() async {
    final user = _authService.user;
    if (user != null && user.containsKey('name')) {
        setState(() {
            // Use 'name' field if available, fallback to 'full_name'
            _driverName = user['name'] ?? user['full_name'] ?? 'Tài xế';
        });
    }

    // TODO: Load real driver availability status from API
    setState(() {
      _isAvailable = false; // Default offline
    });
  }

  Future<void> _loadTodayStats() async {
    // Mock data for demonstration
    setState(() {
      _todayTrips = 4; 
      _todayEarnings = 500000;
    });
  }

  Future<void> _toggleAvailability() async {
    setState(() => _loading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); 

      setState(() {
        _isAvailable = !_isAvailable;
      });

      if (_isAvailable) {
        _showSnackBar('Bạn đã online. Đang tìm chuyến...', isError: false);
        _simulationTimer = Timer(const Duration(seconds: 3), _showIncomingRequest);
      } else {
        _showSnackBar('Bạn đã offline', isError: false);
        _simulationTimer?.cancel();
      }
    } catch (e) {
      _showSnackBar('Lỗi cập nhật trạng thái: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showIncomingRequest() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomingRequestSheet(),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
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
    // final user = _authService.user; // No longer needed here

    return Scaffold(
      appBar: AppBar(
        title: const Text('DriverMe - Tài Xế'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/driver/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) context.go('/role-selection');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDriverStatus();
          await _loadTodayStats(); 
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2E7D32),
                        child: const Icon(
                          Icons.drive_eta,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ UPDATED: Use the state variable for the name
                            Text(
                              'Xin chào, $_driverName!', 
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sẵn sàng nhận chuyến hôm nay?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Status Card
              Card(
                color: _isAvailable ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAvailable ? Icons.online_prediction : Icons.offline_bolt,
                            color: _isAvailable ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAvailable ? 'Đang Online' : 'Đang Offline',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  _isAvailable
                                      ? 'Bạn có thể nhận chuyến mới'
                                      : 'Bật online để nhận chuyến',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isAvailable,
                            onChanged: _loading ? null : (_) => _toggleAvailability(),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),

                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Today's Stats Row using variables
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Chuyến Hôm Nay',
                      _todayTrips.toString(), // Dynamic value
                      Icons.directions_car,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Thu Nhập',
                      '${_todayEarnings.toStringAsFixed(0)}đ', // Dynamic value
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Thao Tác Nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                'Chuyến Có Thể Nhận',
                'Xem danh sách chuyến đang chờ tài xế',
                Icons.assignment,
                Colors.orange,
                () => context.push('/driver/available-bookings'),
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                'Chuyến Của Tôi',
                'Quản lý chuyến đang làm và lịch sử',
                Icons.history,
                Colors.purple,
                () => context.push('/driver/my-bookings'),
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                'Thu Nhập & Thống Kê',
                'Xem báo cáo thu nhập chi tiết',
                Icons.analytics,
                Colors.teal,
                () => context.push('/driver/earnings'), 
              ),

              const SizedBox(height: 20),

              // Tips Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Mẹo Cho Tài Xế',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• Luôn giữ điện thoại đầy pin khi online'),
                      const Text('• Xác nhận địa chỉ với khách trước khi đến'),
                      const Text('• Lái xe an toàn và tuân thủ luật giao thông'),
                      const Text('• Liên hệ khách hàng nếu có thay đổi'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _toggleAvailability,
        backgroundColor: _isAvailable ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        icon: Icon(_isAvailable ? Icons.pause : Icons.play_arrow),
        label: Text(_isAvailable ? 'Offline' : 'Online'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
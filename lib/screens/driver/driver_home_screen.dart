import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();
  bool _isAvailable = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();
  }

  Future<void> _loadDriverStatus() async {
    // TODO: Load driver availability status from API
    setState(() {
      _isAvailable = false; // Default offline
    });
  }

  Future<void> _toggleAvailability() async {
    setState(() => _loading = true);

    try {
      // TODO: Update availability status via API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _isAvailable = !_isAvailable;
      });

      _showSnackBar(
        _isAvailable ? 'Bạn đã online và có thể nhận chuyến' : 'Bạn đã offline',
        isError: false,
      );
    } catch (e) {
      _showSnackBar('Lỗi cập nhật trạng thái: $e');
    } finally {
      setState(() => _loading = false);
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
    final user = _authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DriverMe - Tài Xế'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Navigate to profile
              _showSnackBar('Tính năng profile đang phát triển...', isError: false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              context.go('/role-selection');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverStatus,
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
                            Text(
                              'Xin chào, ${user?['full_name'] ?? 'Tài xế'}!',
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

              // Today's Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Chuyến Hôm Nay',
                      '0',
                      Icons.directions_car,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Thu Nhập',
                      '0đ',
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
                    () => _showSnackBar('Tính năng đang phát triển...', isError: false),
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

      // FAB for quick online toggle
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
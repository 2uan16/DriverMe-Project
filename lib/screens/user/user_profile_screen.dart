import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isBiometricEnabled = false;
  Map<String, dynamic>? _userInfo;

  int _currentIndex = 3; // 0: home, 1: history, 2: notif, 3: profile

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await _authService.getUserInfo();
    if (mounted) {
      setState(() => _userInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildAccountSection(),
              const SizedBox(height: 16),
              _buildServiceSection(),
              const SizedBox(height: 16),
              _buildAboutSection(),
              const SizedBox(height: 16),
              _buildVersionText(),
              const SizedBox(height: 16),
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // ✅ Navigation tích hợp như Home
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == _currentIndex) return; // tránh reload lại chính mình
          switch (i) {
            case 0:
              context.go('/user-home');
              break;
            case 1:
            // context.go('/user-history');
              break;
            case 2:
            // context.go('/notifications');
              break;
            case 3:
              context.go('/user-profile');
              break;
          }
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  /* ---------------- Header ---------------- */
  Widget _buildHeader() {
    final userName = _userInfo?['full_name'] ?? 'Người dùng';
    final phone = _userInfo?['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08B24B), Color(0xFF0BC060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF08B24B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/default_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF08B24B),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.local_fire_department,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (phone.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /* ---------------- Sections ---------------- */
  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Tài khoản',
      items: [
        _ProfileMenuItem(icon: Icons.wallet, title: 'Hoa hồng', onTap: () {}),
        _ProfileMenuItem(icon: Icons.account_balance_wallet, title: 'Liên kết ví', onTap: () {}),
        _ProfileMenuItem(icon: Icons.star, title: 'Điểm thưởng', onTap: () {}),
        _ProfileMenuItem(icon: Icons.lock, title: 'Đổi mật khẩu', onTap: () {}),
        _ProfileMenuItem(icon: Icons.delete_outline, title: 'Xóa tài khoản', onTap: _showDeleteAccountDialog, isDestructive: true),
        _ProfileMenuItem(
          icon: Icons.fingerprint,
          title: 'Sinh trắc học',
          trailing: Switch(
            value: _isBiometricEnabled,
            onChanged: (v) => setState(() => _isBiometricEnabled = v),
            activeColor: const Color(0xFF08B24B),
          ),
        ),
        _ProfileMenuItem(
          icon: Icons.language,
          title: 'Đổi ngôn ngữ',
          trailing: Image.asset(
            'assets/images/vietnam_flag.png',
            width: 24,
            height: 16,
            errorBuilder: (_, __, ___) =>
            const Text('🇻🇳', style: TextStyle(fontSize: 20)),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return _buildSection(
      title: 'Dịch vụ',
      items: [
        _ProfileMenuItem(icon: Icons.person_outline, title: 'Giới thiệu bạn bè', onTap: () {}),
        _ProfileMenuItem(icon: Icons.calendar_today, title: 'Lịch sử đặt chỗ', onTap: () {}),
        _ProfileMenuItem(icon: Icons.directions_car, title: 'Trở thành tài xế DriverMe', onTap: () {}),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'Về chúng tôi',
      items: [
        _ProfileMenuItem(icon: Icons.privacy_tip_outlined, title: 'Chính sách bảo mật', onTap: () {}),
        _ProfileMenuItem(icon: Icons.description_outlined, title: 'Chính sách dịch vụ', onTap: () {}),
        _ProfileMenuItem(icon: Icons.feedback_outlined, title: 'Góp ý ứng dụng DriverMe', onTap: () {}),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<_ProfileMenuItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08B24B),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map(_buildMenuItem),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_ProfileMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 22,
                color: item.isDestructive ? Colors.red : const Color(0xFF08B24B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 15,
                  color: item.isDestructive ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            item.trailing ??
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionText() {
    return const Center(
      child: Text(
        'Phiên bản: 1.0.0',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete account
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) context.go('/role-selection');
    }
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });
}

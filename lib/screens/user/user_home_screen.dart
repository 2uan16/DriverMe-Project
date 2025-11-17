import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'point_to_point_booking.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _BuildHeroHeader()),
          SliverToBoxAdapter(child: _sectionTitle("DỊCH VỤ THUÊ TÀI XẾ")),

          // Service Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ServiceCard(
                icon: Icons.directions_car_filled_rounded,
                label: "Đặt xe theo chuyến",
                subtitle: "Đi từ điểm A đến điểm B",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PointToPointBookingScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _PromoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
      floatingActionButton: _HotlineFab(onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hotline: 1900-xxxx'),
            backgroundColor: Color(0xFF08B24B),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF08B24B),
      elevation: 0,
      toolbarHeight: 88,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 6),
            _LocationRow(),
            SizedBox(height: 8),
            _SearchField(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF08B24B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const Spacer(),
          const _MiniIllustration(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) {
        setState(() => _currentIndex = i);

        // Navigate based on index
        switch (i) {
          case 0:
          // Home - already here
            break;
          case 1:
          // History
            break;
          case 2:
          // Notifications
            break;
          case 3:
          // Profile
            GoRouter.of(context).go('/user-profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: "Trang chủ",
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          label: "Lịch sử",
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: "Thông báo",
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: "Cá nhân",
        ),
      ],
    );
  }
}


/* --------------------------- Sub-widgets --------------------------- */

class _BuildHeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08B24B), Color(0xFF0BC060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hãy cứ là bạn,\nan toàn có DriverMe",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.local_taxi_rounded,
              size: 64,
              color: Colors.white.withOpacity(.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.location_on_outlined, color: Colors.white),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            "Vị trí của bạn",
            style: TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF08B24B).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF08B24B).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF08B24B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF08B24B),
                size: 36,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF08B24B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: Color(0xFFFF6F00),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Ưu đãi hấp dẫn\nGiảm ngay 50K cho chuyến đầu",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF5D4037),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PointToPointBookingScreen(),  // ✅ Đổi tên
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.black54),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Bạn muốn đi đâu?",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Icon(Icons.my_location_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotlineFab extends StatelessWidget {
  final VoidCallback? onTap;
  const _HotlineFab({this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "hotline",
      onPressed: onTap,
      backgroundColor: const Color(0xFF08B24B),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.support_agent_rounded),
      label: const Text("Hotline 24/7"),
    );
  }
}

class _MiniIllustration extends StatelessWidget {
  const _MiniIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x1408B24B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: const [
          Icon(Icons.local_taxi_rounded, size: 14, color: Color(0xFF08B24B)),
          SizedBox(width: 6),
          Text("DriverMe", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

const _green = Color(0xFF08B24B);

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key, this.initialCode});

  final String? initialCode; // giữ để tương thích chỗ gọi Navigator.push

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Ưu đãi', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: const _EmptyVoucherView(),
    );
  }
}

class _EmptyVoucherView extends StatelessWidget {
  const _EmptyVoucherView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _green.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  size: 48, color: _green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có voucher nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Vui lòng thu thập thêm để sử dụng ưu đãi.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

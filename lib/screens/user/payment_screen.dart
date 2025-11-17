import 'package:flutter/material.dart';

enum PaymentType { cash, card, wallet }

class PaymentMethod {
  final PaymentType type;
  final String? masked;     // cho thẻ: **** 1234
  final String? walletName; // cho ví: Momo, Viettel Money...

  const PaymentMethod._(this.type, {this.masked, this.walletName});

  const PaymentMethod.cash() : this._(PaymentType.cash);

  const PaymentMethod.card({String? masked})
      : this._(PaymentType.card, masked: masked);

  const PaymentMethod.wallet({required String walletName})
      : this._(PaymentType.wallet, walletName: walletName);

  // Display name (tiếng Việt - cho user)
  String get display {
    switch (type) {
      case PaymentType.cash:
        return 'Tiền mặt';
      case PaymentType.card:
        return masked == null ? 'Thẻ' : 'Thẻ $masked';
      case PaymentType.wallet:
        return walletName ?? 'Ví';
    }
  }

  // Value (tiếng Anh - cho backend)
  String get value {
    switch (type) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.card:
        return 'card';
      case PaymentType.wallet:
        return 'ewallet';
    }
  }

  IconData get icon {
    switch (type) {
      case PaymentType.cash:
        return Icons.payments_outlined;
      case PaymentType.card:
        return Icons.credit_card;
      case PaymentType.wallet:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // So sánh 2 PaymentMethod
  bool isEqual(PaymentMethod other) {
    if (type != other.type) return false;
    if (type == PaymentType.card) return masked == other.masked;
    if (type == PaymentType.wallet) return walletName == other.walletName;
    return true;
  }
}

class PaymentScreen extends StatefulWidget {
  final PaymentMethod initial;
  const PaymentScreen({super.key, required this.initial});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _choose(PaymentMethod m) => setState(() => _selected = m);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, widget.initial),
        ),
        title: const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Section: Tiền mặt
                _buildSectionHeader('Thanh toán trực tiếp'),
                _buildPaymentCard(
                  method: const PaymentMethod.cash(),
                  icon: Icons.payments_outlined,
                  iconColor: Colors.green,
                  title: 'Tiền mặt',
                  subtitle: 'Thanh toán trực tiếp cho tài xế',
                ),

                const SizedBox(height: 16),

                // Section: Thẻ ngân hàng
                _buildSectionHeader('Thẻ ngân hàng'),
                _buildPaymentCard(
                  method: const PaymentMethod.card(masked: '**** 1234'),
                  icon: Icons.credit_card,
                  iconColor: Colors.blue,
                  title: 'Thẻ **** 1234',
                  subtitle: 'Visa • Vietcombank',
                  trailing: _buildManageButton(),
                ),
                _buildAddNewCard(),

                const SizedBox(height: 16),

                // Section: Ví điện tử
                _buildSectionHeader('Ví điện tử'),
                _buildPaymentCard(
                  method: const PaymentMethod.wallet(walletName: 'MoMo'),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.pink,
                  title: 'Ví MoMo',
                  subtitle: 'Liên kết để thanh toán nhanh',
                  badge: 'HOT',
                ),
                _buildPaymentCard(
                  method: const PaymentMethod.wallet(walletName: 'Viettel Money'),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.red,
                  title: 'Ví Viettel Money',
                  subtitle: 'Liên kết để thanh toán nhanh',
                ),
                _buildPaymentCard(
                  method: const PaymentMethod.wallet(walletName: 'ZaloPay'),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.blue[700]!,
                  title: 'Ví ZaloPay',
                  subtitle: 'Liên kết để thanh toán nhanh',
                ),

                const SizedBox(height: 80), // Space for button
              ],
            ),
          ),

          // Bottom Button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required PaymentMethod method,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? badge,
  }) {
    final isSelected = _selected.isEqual(method);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF7F50) : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: const Color(0xFFFF7F50).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _choose(method),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),

                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Trailing or Radio
                trailing ??
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      onChanged: (_) => _choose(method),
                      activeColor: const Color(0xFFFF7F50),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chức năng thêm thẻ mới đang phát triển'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_card_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thêm thẻ mới',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visa / MasterCard / JCB',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageButton() {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chức năng quản lý thẻ đang phát triển'),
            backgroundColor: Colors.blue,
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFF7F50),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: const Text(
        'Quản lý',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_selected.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Xác nhận - ${_selected.display}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
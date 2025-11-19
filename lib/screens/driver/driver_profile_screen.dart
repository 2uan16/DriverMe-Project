import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final AuthService _authService = AuthService();
  
  // Local State for UI updates (Mocking real data updates)
  String _name = "Tài xế DriverMe";
  String _phone = "0987654321";
  String _age = "28";
  String _vehicleModel = "Toyota Vios";
  String _vehiclePlate = "30A-123.45";
  String _vehicleColor = "Trắng";
  
  // Settings State
  bool _autoAccept = false;
  bool _soundEnabled = true;
  String _language = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    // Initialize with user data if available
    final user = _authService.user;
    if (user != null) {
      _name = user['full_name'] ?? _name;
      _phone = user['phone'] ?? _phone;
    }
  }

  // ======================= EDIT DIALOGS =======================

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final ageCtrl = TextEditingController(text: _age);
    final phoneCtrl = TextEditingController(text: _phone);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật thông tin cá nhân"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Họ và tên"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tuổi"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _name = nameCtrl.text;
                _age = ageCtrl.text;
                _phone = phoneCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  Future<void> _showEditVehicleDialog() async {
    final modelCtrl = TextEditingController(text: _vehicleModel);
    final plateCtrl = TextEditingController(text: _vehiclePlate);
    final colorCtrl = TextEditingController(text: _vehicleColor);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật thông tin xe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: modelCtrl,
              decoration: const InputDecoration(labelText: "Loại xe (Ví dụ: Toyota Vios)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateCtrl,
              decoration: const InputDecoration(labelText: "Biển số xe"),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: colorCtrl,
              decoration: const InputDecoration(labelText: "Màu xe"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              // TODO: Call API to update vehicle
              setState(() {
                _vehicleModel = modelCtrl.text;
                _vehiclePlate = plateCtrl.text;
                _vehicleColor = colorCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = 'Đang hoạt động'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ tài xế'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                            onPressed: () {
                                // TODO: Pick image
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "$_phone • $_age tuổi",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'Đang hoạt động' ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Đang hoạt động' ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Vehicle Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thông tin phương tiện", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _showEditVehicleDialog, child: const Text("Sửa")),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.directions_car, "Loại xe", _vehicleModel),
                    const Divider(),
                    _buildInfoRow(Icons.confirmation_number, "Biển số", _vehiclePlate),
                    const Divider(),
                    _buildInfoRow(Icons.color_lens, "Màu sắc", _vehicleColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Settings
            const Text("Cài đặt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Tự động nhận cuốc"),
                    subtitle: const Text("Hệ thống sẽ tự nhận chuyến khi có yêu cầu"),
                    value: _autoAccept,
                    onChanged: (val) => setState(() => _autoAccept = val),
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Âm báo"),
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("Ngôn ngữ"),
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        setState(() => _language = newValue!);
                      },
                      items: <String>['Tiếng Việt', 'English']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) context.go('/role-selection');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Đăng xuất"),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'driver_trip_flow_screen.dart';

class IncomingRequestSheet extends StatefulWidget {
  const IncomingRequestSheet({super.key});

  @override
  State<IncomingRequestSheet> createState() => _IncomingRequestSheetState();
}

class _IncomingRequestSheetState extends State<IncomingRequestSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Timer runs for 15 seconds
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pop(context); // Timeout: Close the popup
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Yêu cầu mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // ✅ FIXED: Use AnimatedBuilder instead of valueController
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _controller.value, // This binds the animation value (0.0 to 1.0)
                color: const Color(0xFF08B24B),
                backgroundColor: Colors.grey[200],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Route Info
          const Row(children: [
            Icon(Icons.my_location, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(child: Text("Royal City, 72 Nguyễn Trãi", style: TextStyle(fontWeight: FontWeight.w500))),
            Text("2.5km", style: TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text("Hồ Gươm, Hoàn Kiếm", style: TextStyle(fontWeight: FontWeight.w500))),
            Text("120k", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF08B24B))),
          ]),
          const SizedBox(height: 30),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close popup
                    
                    // Navigate to Trip Flow
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const DriverTripFlowScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08B24B), 
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: const Text("Chấp nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
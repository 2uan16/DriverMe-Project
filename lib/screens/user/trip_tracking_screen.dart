import 'package:driverme_app/screens/user/trip_rating_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/mapbox_widget.dart';

class TripTrackingScreen extends StatefulWidget {
  final String bookingId;
  const TripTrackingScreen({super.key, required this.bookingId});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  // Mocking status for UI testing
  int _statusIndex = 0; 
  final List<String> _statuses = ['Tài xế đang đến', 'Tài xế đã đến', 'Đang di chuyển', 'Đã đến nơi'];
  final List<String> _subtitles = ['Tài xế Nguyễn Văn A (2 phút)', 'Vui lòng ra điểm đón', 'Dự kiến đến: 10:30', 'Vui lòng thanh toán'];
  final List<double> _progress = [0.2, 0.4, 0.8, 1.0];

  final LatLng _driverLocation = LatLng(21.0285, 105.8542); 
  final LatLng _pickupLocation = LatLng(21.0290, 105.8550);
  final LatLng _destLocation = LatLng(21.0300, 105.8600);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapboxWidget(
              pickup: _pickupLocation,
              destination: _destLocation,
              // In a real app, you would update 'driverLocation' periodically
              // driverLocation: _driverLocation, 
              onLocationSelected: (_) {},
            ),
          ),

          // 2. Top Status Bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_taxi, color: Color(0xFF08B24B)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Mã chuyến: #${widget.bookingId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text("Toyota Vios • 30A-123.45", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Draggable Sheet for Trip Info
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: _progress[_statusIndex],
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF08B24B),
                  ),
                  const SizedBox(height: 16),

                  // Status Text
                  Text(
                    _statuses[_statusIndex],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF08B24B)),
                  ),
                  Text(
                    _subtitles[_statusIndex],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Driver Info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nguyễn Văn A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Text(" 4.9", style: TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                      // Action Buttons
                      _CircleBtn(icon: Icons.call, color: Colors.green, onTap: () {}),
                      const SizedBox(width: 12),
                      _CircleBtn(icon: Icons.message, color: Colors.blue, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // DEV ONLY: Button to simulate trip progress
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_statusIndex < 3) {
                            _statusIndex++;
                          } else {
                            // Trip Completed -> Go to Rating
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TripRatingScreen()));
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black),
                      child: Text(_statusIndex < 3 ? "Simulate: Next Step" : "Simulate: Finish Trip"),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripRatingScreen extends StatefulWidget {
  const TripRatingScreen({super.key});

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Đánh giá chuyến đi"), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 40, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 40, color: Colors.white)),
            const SizedBox(height: 16),
            const Text("Nguyễn Văn A", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Toyota Vios • 30A-123.45", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 40,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Comment
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Bạn cảm thấy chuyến đi thế nào?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),
            
            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Call API to submit rating
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cảm ơn đánh giá của bạn!")));
                  context.go('/user-home'); // Back to Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08B24B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Gửi đánh giá", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class HirePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> player;
  const HirePlayerScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<HirePlayerScreen> createState() => _HirePlayerScreenState();
}

class _HirePlayerScreenState extends State<HirePlayerScreen> {
  int selectedHour = 1;
  final TextEditingController messageController = TextEditingController();
  final List<int> hours = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuê người chơi'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.orange[100],
                    child: const Icon(Icons.person, size: 36, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.player['username'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            const Text('🍊', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF7E5F), Color(0xFFFFB347)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.player['pricePerHour'] ?? '0'} đ/h',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Số dư hiện tại', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Text('0', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Thời gian muốn thuê:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedHour,
                  items: hours.map((h) => DropdownMenuItem(
                    value: h,
                    child: Text('$h giờ'),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedHour = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Gửi tin nhắn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF7F7F9),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () {
                  // Xử lý thuê ở đây
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu thuê!')));
                },
                child: const Text('Thuê người chơi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

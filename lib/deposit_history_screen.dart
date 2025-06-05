import 'package:flutter/material.dart';

class DepositHistoryScreen extends StatefulWidget {
  const DepositHistoryScreen({super.key});

  @override
  State<DepositHistoryScreen> createState() => _DepositHistoryScreenState();
}

class _DepositHistoryScreenState extends State<DepositHistoryScreen> {
  // Giả lập dữ liệu, bạn thay bằng API thực tế
  List<Map<String, dynamic>> history = [
    {
      "createdAt": "2025-06-02 15:30",
      "amount": 100000,
      "coinAmount": 1000,
      "method": "MoMo",
      "status": "success",
      "transactionId": "TX123456"
    },
    {
      "createdAt": "2025-06-01 10:15",
      "amount": 200000,
      "coinAmount": 2000,
      "method": "Vietcombank",
      "status": "success",
      "transactionId": "TX123456"
    },
    {
      "createdAt": "2025-05-29 08:45",
      "amount": 500000,
      "coinAmount": 5000,
      "method": "ZaloPay",
      "status": "pending",
      "transactionId": "TX123456"
    },
    {
      "createdAt": "2025-05-25 14:20",
      "amount": 50000,
      "coinAmount": 500,
      "method": "QR Code",
      "status": "failed",
      "transactionId": "TX123453"
    },
    {
      "createdAt": "2025-05-20 09:10",
      "amount": 300000,
      "coinAmount": 3000,
      "method": "Techcombank",
      "status": "success",
      "transactionId": "TX123452"
    },
    {
      "createdAt": "2025-05-15 16:40",
      "amount": 1000000,
      "coinAmount": 10000,
      "method": "VNPay",
      "status": "success",
      "transactionId": "TX123451"
    },
  ];

  String search = '';
  String selectedStatus = 'Tất cả trạng thái';
  String selectedTime = 'Tất cả thời gian';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nạp xu'),
        backgroundColor: const Color(0xFFF7F7F9),
      ),
      body: Column(
        children: [
          // Filter & Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedTime,
                        items: [
                          'Tất cả thời gian',
                          // Thêm các filter thời gian nếu muốn
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedTime = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: [
                          'Tất cả trạng thái',
                          'Thành công',
                          'Đang xử lý',
                          'Thất bại',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredHistory().length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _filteredHistory()[index];
                return _buildHistoryItem(item);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text('Xem thêm'),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredHistory() {
    return history.where((item) {
      final matchSearch = search.isEmpty ||
          item['transactionId'].toString().contains(search) ||
          item['method'].toString().toLowerCase().contains(search.toLowerCase());
      final matchStatus = selectedStatus == 'Tất cả trạng thái' ||
          (selectedStatus == 'Thành công' && item['status'] == 'success') ||
          (selectedStatus == 'Đang xử lý' && item['status'] == 'pending') ||
          (selectedStatus == 'Thất bại' && item['status'] == 'failed');
      // Có thể thêm filter thời gian ở đây nếu muốn
      return matchSearch && matchStatus;
    }).toList();
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    Color statusColor;
    String statusText;
    switch (item['status']) {
      case 'success':
        statusColor = Colors.green;
        statusText = 'Thành công';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Đang xử lý';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = 'Thất bại';
        break;
      default:
        statusColor = Colors.grey;
        statusText = item['status'];
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['createdAt'],
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${item['coinAmount']} xu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
              const SizedBox(width: 12),
              Text(item['method'], style: const TextStyle(color: Colors.black54)),
              const Spacer(),
              if(item['amount'] != null)
                Text('(${_formatMoney(item['amount'])} đ)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Mã giao dịch: ${item['transactionId']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(num amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
} 
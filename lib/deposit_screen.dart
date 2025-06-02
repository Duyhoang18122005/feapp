import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'api_service.dart';
import 'webview_screen.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  String selectedMethod = 'MOMO';
  double? walletBalance;
  bool isLoadingBalance = true;
  
  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'MOMO', 'icon': Icons.phone_android, 'color': Colors.pink},
    {'name': 'VNPAY', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'name': 'ZALOPAY', 'icon': Icons.payment, 'color': Colors.blue[700]},
    {'name': 'BANK_TRANSFER', 'icon': Icons.account_balance_wallet, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final balance = await ApiService.fetchWalletBalance();
    setState(() {
      walletBalance = balance;
      isLoadingBalance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nạp tiền',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Số dư hiện tại
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư hiện tại',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        isLoadingBalance
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange),
                            )
                          : Text(
                              walletBalance != null
                                ? '${walletBalance!.toStringAsFixed(0)} đ'
                                : 'Lỗi',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange[700],
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Nhập số tiền
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập số tiền',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nhập số tiền cần nạp',
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.deepOrange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildAmountChip('50.000'),
                        _buildAmountChip('100.000'),
                        _buildAmountChip('200.000'),
                        _buildAmountChip('500.000'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Phương thức thanh toán
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...paymentMethods.map((method) => _buildPaymentMethod(method)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Nút nạp tiền
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      if (amount < 10000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Số tiền nạp tối thiểu là 10.000đ')),
                        );
                        return;
                      }
                      final result = await ApiService.deposit(amount, selectedMethod);
                      print('Deposit API response:');
                      print(result);
                      if (result == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lỗi không xác định!')),
                        );
                        return;
                      }
                      if (result['paymentUrl'] != null) {
                        print('Payment URL: ${result['paymentUrl']}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WebViewScreen(url: result['paymentUrl'], title: 'Thanh toán'),
                          ),
                        );
                      } else if (result['qrCode'] != null) {
                        _showQRCodeDialog(result);
                      } else if (selectedMethod == 'BANK_TRANSFER') {
                        _showBankTransferDialog(result);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Nạp tiền thành công')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Nạp tiền ngay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(String amount) {
    return ActionChip(
      label: Text(amount),
      onPressed: () {
        setState(() {
          _amountController.text = amount.replaceAll('.', '');
        });
      },
      backgroundColor: Colors.orange[50],
      labelStyle: const TextStyle(color: Colors.deepOrange),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    final isSelected = selectedMethod == method['name'];
    return InkWell(
      onTap: () {
        setState(() {
          selectedMethod = method['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(method['icon'], color: method['color']),
            const SizedBox(width: 12),
            Text(
              method['name'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepOrange : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: result['qrCode'] ?? '',
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Số tiền: ${_amountController.text}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 8),
              if (result['transactionId'] != null) ...[
                Text(
                  'Mã giao dịch: ${result['transactionId']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Nội dung: ${result['transferContent'] ?? ''}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Hiển thị loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        // Gọi API topup
                        final amount = double.tryParse(_amountController.text) ?? 0;
                        final error = await ApiService.topUp(amount);
                        
                        // Đóng loading
                        Navigator.pop(context);
                        
                        if (error == null) {
                          // Đóng dialog QR code
                          Navigator.pop(context);
                          // Cập nhật số dư
                          _loadWalletBalance();
                          // Hiển thị thông báo thành công
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nạp tiền thành công')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      } catch (e) {
                        // Đóng loading nếu có lỗi
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${e.toString()}')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Đã thanh toán'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankTransferDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin chuyển khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngân hàng: ${result['bankName'] ?? ''}'),
            Text('Số tài khoản: ${result['bankAccount'] ?? ''}'),
            Text('Chủ tài khoản: ${result['bankOwner'] ?? ''}'),
            Text('Nội dung: ${result['transferContent'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'Số tiền: ${_amountController.text}đ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Hiển thị loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Gọi API topup
                final amount = double.tryParse(_amountController.text) ?? 0;
                final error = await ApiService.topUp(amount);
                
                // Đóng loading
                Navigator.pop(context);
                
                if (error == null) {
                  // Đóng dialog chuyển khoản
                  Navigator.pop(context);
                  // Cập nhật số dư
                  _loadWalletBalance();
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nạp tiền thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              } catch (e) {
                // Đóng loading nếu có lỗi
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
            child: const Text('Đã chuyển khoản'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
} 
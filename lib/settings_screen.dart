import 'package:flutter/material.dart';
import 'register_player_screen.dart';
import 'login_screen.dart';
import 'api_service.dart';
import 'utils/notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userId = '';
  bool isLoading = true;
  double? walletBalance;
  bool isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadWalletBalance();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await ApiService.getCurrentUser();
    if (mounted) {
      setState(() {
        userId = userInfo?['id']?.toString() ?? '';
        isLoading = false;
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final balance = await ApiService.fetchWalletBalance();
    if (mounted) {
      setState(() {
        walletBalance = balance;
        isLoadingBalance = false;
      });
    }
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> handleLogout() async {
    final shouldLogout = await NotificationHelper.showConfirmDialog(
      context,
      title: 'Xác nhận đăng xuất',
      content: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
    );

    if (shouldLogout != true) return;

    await ApiService.logout();
    if (!mounted) return;

    NotificationHelper.showSuccess(context, 'Đăng xuất thành công!');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Avatar + nút đổi avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.deepOrange[100],
                    child: const Text(
                      "🍄",
                      style: TextStyle(fontSize: 54),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Thông tin
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Thông tin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.account_balance_wallet,
                      label: "Số dư trong ví",
                      value: isLoadingBalance
                        ? null
                        : (walletBalance != null ? '${walletBalance!.toStringAsFixed(0)}đ' : 'Lỗi'),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.balance, label: "Biến động số dư"),
                    const SizedBox(height: 8),
                    isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _InfoRow(
                          icon: Icons.info, 
                          label: "ID", 
                          value: userId,
                          isLink: true
                        ),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.share, label: "Chia sẻ link"),
                    const SizedBox(height: 24),
                    const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 16),
                    _SettingSwitch(icon: Icons.message, label: "Nhận tin nhắn từ người lạ", value: true),
                    const SizedBox(height: 8),
                    _SettingSwitch(icon: Icons.notifications, label: "Nhận yêu cầu thuê Duo", value: false),
                    const SizedBox(height: 8),
                    _SettingRow(icon: Icons.settings, label: "Cài đặt avatar, tên, url, giá thuê"),
                    const SizedBox(height: 8),
                    _SettingRow(icon: Icons.lock, label: "Khóa bảo vệ", color: Colors.purple),
                    const SizedBox(height: 8),
                    _SettingRow(icon: Icons.policy, label: "Chính sách", color: Colors.red),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: Icon(Icons.person_add, color: Colors.deepOrange),
                      title: Text('Đăng ký làm Player'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPlayerScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: handleLogout,
              child: const Text("Đăng xuất", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLink;
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.deepOrange[100],
          child: Icon(icon, color: Colors.deepOrange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    value!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isLink ? Colors.deepOrange : Colors.black87,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color? color;
  const _SettingSwitch({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (color is MaterialColor)
              ? (color as MaterialColor).shade100
              : (color ?? Colors.blue).withOpacity(0.15),
          child: Icon(icon, color: color ?? Colors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Switch(
          value: value,
          onChanged: (v) {},
          activeColor: Colors.deepOrange,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _SettingRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (color is MaterialColor)
              ? (color as MaterialColor).shade100
              : (color ?? Colors.yellow).withOpacity(0.15),
          child: Icon(icon, color: color ?? Colors.yellow[800], size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
} 
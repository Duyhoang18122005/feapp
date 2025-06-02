import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'main.dart';
import 'api_service.dart';
import 'utils/notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:io';
import 'config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? usernameError;
  String? passwordError;

  void validateInputs() {
    setState(() {
      usernameError = usernameController.text.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null;
      passwordError = passwordController.text.trim().isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    });
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
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

  Future<bool> kiemTraKetNoi() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> guiDeviceToken(String deviceToken) async {
    try {
      // Kiểm tra kết nối mạng
      if (!await kiemTraKetNoi()) {
        print('Không có kết nối mạng');
        return;
      }

      String? authToken = await layTokenXacThuc(); // Lấy JWT đã lưu
      if (authToken == null) {
        print('Không có token xác thực');
        return;
      }

      print('Đang gửi request với:');
      print('URL: ${ApiConfig.baseUrl}/api/notifications/device-token');
      print('Headers: {');
      print('  Content-Type: application/json');
      print('  Authorization: Bearer ${authToken.substring(0, 20)}...');
      print('}');
      print('Body: {"deviceToken": "$deviceToken"}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'deviceToken': deviceToken}),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Gửi token thiết bị thành công');
        // Lưu trạng thái đã gửi token
        final storage = FlutterSecureStorage();
        await storage.write(key: 'device_token_sent', value: 'true');
      } else if (response.statusCode == 401) {
        print('Token xác thực không hợp lệ hoặc đã hết hạn');
        // Xóa token cũ và yêu cầu đăng nhập lại
        final storage = FlutterSecureStorage();
        await storage.delete(key: 'jwt');
        await storage.delete(key: 'user');
        if (mounted) {
          NotificationHelper.showError(context, 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        print('Gửi token thiết bị thất bại: statusCode=${response.statusCode}, body=${response.body}');
        if (mounted) {
          NotificationHelper.showError(context, 'Không thể cập nhật token thiết bị. Vui lòng thử lại sau.');
        }
      }
    } catch (e) {
      print('Lỗi khi gửi token thiết bị: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Có lỗi xảy ra khi cập nhật token thiết bị.');
      }
    }
  }

  Future<String?> layTokenXacThuc() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt');
  }

  Future<void> handleLogin() async {
    validateInputs();
    if (usernameError != null || passwordError != null) return;

    setState(() => isLoading = true);
    try {
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();
      final error = await ApiService.login(username, password);
      if (error == null) {
        if (!mounted) return;

        // Sau khi login thành công, dùng JWT gọi API lấy thông tin user
        final user = await ApiService.getUserInfo();
        if (user != null) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'user', value: jsonEncode(user));
          final userId = user['id']?.toString() ?? '';
          String? deviceToken = await FirebaseMessaging.instance.getToken();
          if (userId.isNotEmpty && deviceToken != null) {
            final success = await ApiService.updateDeviceToken(deviceToken);
            if (success) {
              await storage.write(key: 'device_token_sent_$userId', value: deviceToken);
            } else if (mounted) {
              NotificationHelper.showError(context, 'Không thể cập nhật token thiết bị. Vui lòng thử lại sau.');
            }
          }
        } else {
          NotificationHelper.showError(context, 'Không lấy được thông tin người dùng!');
        }

        NotificationHelper.showSuccess(context, 'Đăng nhập thành công!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        if (!mounted) return;
        NotificationHelper.showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Thêm hàm logout để xóa sạch thông tin local
  Future<void> handleLogout() async {
    final storage = FlutterSecureStorage();
    await storage.deleteAll(); // Xóa sạch toàn bộ thông tin local
    await ApiService.logout();
    if (!mounted) return;
    NotificationHelper.showSuccess(context, 'Đăng xuất thành công!');
    await Future.delayed(const Duration(milliseconds: 500));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Logo và tên app
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_esports, color: Colors.deepOrange, size: 48),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PLAYERDUO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                        ),
                        Text(
                          'GAME COMMUNITY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Hình minh họa
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.computer, size: 100, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 32),
                // Form đăng nhập
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Tên đăng nhập',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    errorText: usernameError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    errorText: passwordError,
                  ),
                ),
                const SizedBox(height: 24),
                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút đăng nhập Facebook
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1877F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    onPressed: () {},
                    label: const Text('Đăng nhập bằng Facebook', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                // Quên mật khẩu
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    'Quên mật khẩu',
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                // Đăng ký và bỏ qua đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bạn chưa có tài khoản? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay!',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
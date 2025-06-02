import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/api_config.dart';

class ApiService {
  static const storage = FlutterSecureStorage();
  static Map<String, dynamic>? _currentUser;
  static const timeout = Duration(seconds: 10);

  static Future<Map<String, String>> get _headersWithToken async {
    final token = await storage.read(key: 'jwt');
    return {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // Login
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt', value: data['token']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
        _currentUser = data['user'];
        final userId = data['user']?['id']?.toString() ?? '';
        print('[Flutter] Đã lưu userId sau đăng nhập: $userId');
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // Logout
  static Future<void> logout() async {
    await storage.delete(key: 'jwt');
    await storage.delete(key: 'user');
    await storage.delete(key: 'device_token_sent');
    _currentUser = null;
  }

  // Update Device Token
  static Future<bool> updateDeviceToken(String deviceToken) async {
    try {
      final headers = await _headersWithToken;
      final url = '${ApiConfig.baseUrl}${ApiConfig.deviceToken}';
      print('==============================');
      print('[Flutter] BẮT ĐẦU GỬI DEVICE TOKEN');
      print('URL: $url');
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));
      print('Body: {"deviceToken": "$deviceToken"}');
      print('------------------------------');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'deviceToken': deviceToken}),
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200) {
        await storage.write(key: 'device_token_sent', value: 'true');
        print('[Flutter] Đã lưu trạng thái gửi device token thành công.');
        return true;
      } else if (response.statusCode == 401) {
        print('[Flutter] Token xác thực không hợp lệ hoặc đã hết hạn. Đăng xuất...');
        await logout();
        return false;
      } else {
        print('[Flutter] Gửi device token thất bại với status: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      print('[Flutter] LỖI khi gửi device token: $e');
      print('[Flutter] Stacktrace: $stack');
      return false;
    }
  }

  // Get Current User
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
        print('[Flutter] Lấy user từ storage: ${_currentUser?['id']}');
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Lỗi khi đọc thông tin người dùng: $e');
      return null;
    }
  }

  // Get User Info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      print('==============================');
      print('[Flutter] BẮT ĐẦU LẤY THÔNG TIN USER');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.userInfo}');
      final headers = await _headersWithToken;
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userInfo}'),
        headers: headers,
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi khi đọc thông tin người dùng: $e');
      return null;
    }
  }

  // Send Message
  static Future<Map<String, dynamic>?> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messages}/send/$receiverId'),
        headers: await _headersWithToken,
        body: jsonEncode({'content': content}),
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      return null;
    }
  }

  // Get Conversation
  static Future<List<dynamic>> getConversation(int userId) async {
    try {
      print('==============================');
      print('[Flutter] BẮT ĐẦU LẤY LỊCH SỬ TIN NHẮN');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.messages}/conversation/$userId');
      final headers = await _headersWithToken;
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messages}/conversation/$userId'),
        headers: headers,
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map && data.containsKey('messages')) {
          return data['messages'];
        }
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy hội thoại: $e');
      return [];
    }
  }

  // Get Conversations
  static Future<List<dynamic>> getConversations() async {
    try {
      print('==============================');
      print('[Flutter] BẮT ĐẦU LẤY DANH SÁCH HỘI THOẠI');
      final url = Uri.parse('${ApiConfig.baseUrl}/messages/all-conversations');
      final headers = await _headersWithToken;
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách hội thoại: $e');
      return [];
    }
  }

  static Future<String?> register(String username, String password, String email, String fullName) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      if (e is http.ClientException) {
        return 'Không thể kết nối đến máy chủ';
      }
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> fetchGames() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.games}');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> registerPlayer(Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return null;
        } else {
          return result['message'] ?? 'Đăng ký player thất bại';
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return error['message'] ?? 'Đăng ký player thất bại';
        } catch (e) {
          return response.body.isNotEmpty ? response.body : 'Đăng ký player thất bại';
        }
      }
    } catch (e) {
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> fetchAllPlayers() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchPlayerById(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}/$id');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<double?> fetchWalletBalance() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/wallet-balance');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return double.tryParse(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deposit(double amount, String method) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/deposit');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'method': method,
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Nạp tiền thất bại');
    }
  }

  static Future<Map<String, dynamic>?> processPayment(String transactionId) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/process');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': transactionId,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Xử lý thanh toán thất bại');
      }
    } catch (e) {
      print('Lỗi khi xử lý thanh toán: ${e.toString()}');
      return null;
    }
  }

  static Future<String?> topUp(double amount) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/topup');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return null; // Thành công
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Nạp tiền thất bại';
      }
    } catch (e) {
      print('Lỗi khi nạp tiền: ${e.toString()}');
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<int> fetchFollowerCount(int playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/followers/count');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['followerCount'] ?? 0;
    }
    return 0;
  }

  static Future<int> fetchHireHours(int playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/hire-hours');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalHireHours'] ?? 0;
    }
    return 0;
  }

  static Future<bool> followPlayer(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/follow');
    print('[LOG] Gửi POST follow tới $url với token: ${token != null}');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    print('[LOG] Response followPlayer: statusCode=${response.statusCode}, body=${response.body}');
    return response.statusCode == 200;
  }

  static Future<bool> checkFollowing(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/is-following');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFollowing'] == true;
    }
    return false;
  }

  static Future<bool> unfollowPlayer(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/unfollow');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi lấy thông tin user: $e');
      return null;
    }
  }
}
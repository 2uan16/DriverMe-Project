import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_keys.dart';
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Map<String, dynamic>? _cachedUser;

  static String? _workingBackendUrl;

  Future<String> _getWorkingBackendUrl() async {
    if (_workingBackendUrl != null) {
      return _workingBackendUrl!;
    }

    print('🔍 Testing backend URLs...');

    // Thử từng URL trong list
    for (final url in ApiKeys.allBackendUrls) {
      try {
        print('  Testing: $url');

        final response = await http.get(
          Uri.parse('$url/api/health'),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          _workingBackendUrl = url;
          print('  ✅ Success: $url');
          return url;
        }
      } catch (e) {
        print('  ❌ Failed: $url ($e)');
        continue;
      }
    }

    // Nếu không URL nào hoạt động, dùng URL đầu tiên
    print('    No working URL found, using default');
    _workingBackendUrl = ApiKeys.backendBaseUrl;
    return _workingBackendUrl!;
  }

  // ============================================
  // INIT
  // ============================================
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        _cachedUser = json.decode(userJson) as Map<String, dynamic>;
        print('✅ User loaded from cache: ${_cachedUser?['full_name']}');
      } else {
        print('ℹ️ No cached user found');
      }
    } catch (e) {
      print('❌ Init error: $e');
    }
  }

  // Getter cho user (synchronous)
  Map<String, dynamic>? get user => _cachedUser;

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final userInfo = await getUserInfo();
    return userInfo?['role'];
  }

  // Get user info with caching
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      // Return cached data if available
      if (_cachedUser != null) {
        return _cachedUser;
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        _cachedUser = json.decode(userJson) as Map<String, dynamic>;
        return _cachedUser;
      }

      // Nếu không có trong cache, gọi API
      final token = await getToken();
      if (token == null) return null;

      // ✅ Dùng working backend URL
      final backendUrl = await _getWorkingBackendUrl();

      final response = await http.get(
        Uri.parse('$backendUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _cachedUser = data['data'];
          await prefs.setString(_userKey, json.encode(_cachedUser));
          return _cachedUser;
        }
      }

      return null;
    } catch (e) {
      print('❌ Get user info error: $e');
      return null;
    }
  }

  // Update user info in cache
  Future<bool> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      _cachedUser = userData;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
      return true;
    } catch (e) {
      print('❌ Update user info error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login...');

      final backendUrl = await _getWorkingBackendUrl();

      print('Backend URL: $backendUrl');

      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('  Response status: ${response.statusCode}');
      print('  Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final user = data['data']['user'];

        _cachedUser = user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user));

        print('Login successful for: ${user['email']}');

        return {
          'success': true,
          'role': user['role'],
          'message': data['message'] ?? 'Đăng nhập thành công',
        };
      } else {
        print('Login failed: ${data['message']}');

        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      print('Login error: $e');

      // Reset cached URL để retry lần sau
      _workingBackendUrl = null;

      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'user',
  }) async {
    try {
      print('📝 Attempting registration...');

      // ✅ Get working backend URL
      final backendUrl = await _getWorkingBackendUrl();

      print('Backend URL: $backendUrl');

      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['data']['token'];
        final user = data['data']['user'];

        _cachedUser = user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user));

        print('Registration successful for: ${user['email']}');

        return {
          'success': true,
          'role': user['role'],
          'message': data['message'] ?? 'Đăng ký thành công',
        };
      } else {
        print('Registration failed: ${data['message']}');

        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      print('Registration error: $e');

      // Reset cached URL
      _workingBackendUrl = null;

      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('✅ Logged out successfully');
  }

  Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final backendUrl = await _getWorkingBackendUrl();

      // Build full URL
      final fullUrl = '$backendUrl$endpoint';

      print('Token: ${token.substring(0, 20)}...');
      print('Endpoint: $fullUrl');
      print('Method: $method');

      if (body != null) {
        print('Body: ${json.encode(body)}');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            Uri.parse(fullUrl),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          break;

        case 'POST':
          response = await http.post(
            Uri.parse(fullUrl),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;

        case 'PUT':
          response = await http.put(
            Uri.parse(fullUrl),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;

        case 'DELETE':
          response = await http.delete(
            Uri.parse(fullUrl),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          break;
        
        case 'PATCH':
          response = await http.patch(
            Uri.parse(fullUrl),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;

        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('Response status: ${response.statusCode}');

      return response;
    } catch (e) {
      print('Auth request error: $e');

      // Reset cached URL để retry lần sau
      _workingBackendUrl = null;

      rethrow;
    }
  }
}
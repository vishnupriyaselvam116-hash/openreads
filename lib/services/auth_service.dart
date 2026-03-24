import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ LOCAL TESTING — Flutter Web use pannum pothu
const String kBaseUrl = 'http://localhost:5000/api';

// 🌐 PRODUCTION (Render deploy ready-a irundha, ippa comment pannidu)
 //const String kBaseUrl = 'https://openreads-backend.onrender.com/api';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthService {
  // ── LOGIN ────────────────────────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
    required String requiredRole,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'requiredRole': requiredRole,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        await _saveSession(body['data']['token'], body['data']['user']);
        return AuthResult(
          success: true,
          message: body['message'],
          token: body['data']['token'],
          user: body['data']['user'],
        );
      }
      return AuthResult(
          success: false, message: body['message'] ?? 'Login failed');
    } catch (e) {
      return AuthResult(
          success: false,
          message: 'Server connect aakavillai. Check connection.');
    }
  }

  // ── REGISTER ─────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? penName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
              if (penName != null && penName.isNotEmpty) 'penName': penName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        await _saveSession(body['data']['token'], body['data']['user']);
        return AuthResult(
          success: true,
          message: body['message'],
          token: body['data']['token'],
          user: body['data']['user'],
        );
      }

      if (body['errors'] != null) {
        final msgs =
            (body['errors'] as List).map((e) => e['msg']).join(', ');
        return AuthResult(success: false, message: msgs);
      }

      return AuthResult(
          success: false, message: body['message'] ?? 'Register failed');
    } catch (e) {
      return AuthResult(
          success: false,
          message: 'Server connect aakavillai. Check connection.');
    }
  }

  // ── SAVE SESSION ─────────────────────────────────────────────────────────
  static Future<void> _saveSession(
      String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
    await prefs.setString('role', user['role']);
  }

  // ── LOGOUT ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('role');
  }

  // ── GET SAVED DATA ───────────────────────────────────────────────────────
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }
}
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/models/api_model.dart';
import 'package:project/services/secure_storage.dart';

import '../main.dart';
import '../models/current_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl = dotenv.env['base_url']!;
  static final SecureStorage _secureStorage = SecureStorage.instance;

  static final ApiService instance = ApiService._constructor();
  ApiService._constructor();

  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<CurrentUser> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final url = '$baseUrl${ApiModel.authRegister}';
    debugPrint('POST $url');

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'username': username,
          }),
        )
        .timeout(Duration(seconds: 5));

    debugPrint('Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      await _secureStorage.writeToken(token);
      setAuthToken(token);

      final currentUser = CurrentUser.fromAuthResponse(data, email, username);
      return currentUser;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  static Future<CurrentUser> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl${ApiModel.authAuthenticate}';
    debugPrint('POST $url');

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(Duration(seconds: 5));

    debugPrint('Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userId = data['id'];

      // Store token and expiry in secure storage
      await _secureStorage.writeToken(token);
      setAuthToken(token);

      try {
        // Fetch user details using the users endpoint
        final userDetails = await _fetchUserDetails(userId);

        final currentUser = CurrentUser(
          id: userId,
          token: token,
          email: userDetails['email'] ?? email,
          username: userDetails['username'] ?? '',
        );

        return currentUser;
      } catch (e) {
        // If fetching user details fails, create user with basic info
        debugPrint('Failed to fetch user details: $e');
        final currentUser = CurrentUser(
          id: userId,
          token: token,
          email: email,
          username: '', // Will be empty if we can't fetch it
        );

        return currentUser;
      }
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _fetchUserDetails(int userId) async {
    final url = '$baseUrl${ApiModel.users}';
    debugPrint('GET $url');

    final response = await http
        .get(
          Uri.parse(url),
          headers: _headers,
        )
        .timeout(Duration(seconds: 5));

    debugPrint('Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      // Find the current user in the users list
      final user = users.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => throw Exception('User not found'),
      );
      return user;
    } else {
      throw Exception('Failed to fetch user details: ${response.body}');
    }
  }

  static Future<void> logout() async {
    await _secureStorage.deleteToken();
    _authToken = null;
  }

  static Future<String?> getStoredToken() async {
    return await _secureStorage.readToken();
  }

  static Future<bool> isTokenValid() async {
    try {
      final token = await _secureStorage.readToken();
      if (token == null) return false;
      final expiryString = await _secureStorage.readExpiry();
      if (expiryString == null) return false;

      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }
}

Future<String?> readToken(BuildContext context) async {
  String? token = await secureStorage.readToken();
  if (token != null) {
    String? expiryString = await secureStorage.readExpiry();
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        if (context.mounted) AuthController.instance.logout(context);
        return null;
      } else {
        return token;
      }
    }
  }
  return null;
}

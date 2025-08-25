import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/models/api_model.dart';

import '../main.dart';
import '../models/current_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl = dotenv.env['base_url']!;

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
      setAuthToken(data['token']);
      return CurrentUser.fromAuthResponse(data, email, username);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  static Future<CurrentUser?> login({
    required String email,
    required String password,
  }) async {
    return null;
  }
}

Future<String?> readToken(BuildContext context) async {
  String? token = await secureStorage.readToken();
  if (token != null) {
    String? expiryString = await secureStorage.readExpiry();
    final expiry = DateTime.parse(expiryString!);
    if (DateTime.now().isAfter(expiry)) {
      if (context.mounted) AuthController.instance.logout(context);
      return null;
    } else {
      return token;
    }
  } else {
    return null;
  }
}

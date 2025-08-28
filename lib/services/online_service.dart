import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/models/api_model.dart';
import 'package:project/models/task_model.dart';
import 'package:project/models/user_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/secure_storage.dart';

import '../main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/current_user.dart';


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

    try {
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication failed - wrong credentials
        throw Exception('Email ou mot de passe incorrect');
      } else {
        // Server error or other HTTP error
        throw Exception('Erreur du serveur: ${response.statusCode}');
      }
    } on TimeoutException {
      // Network timeout
      throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
    } on SocketException {
      // No internet connection or server unreachable
      throw Exception('Serveur inaccessible. Vérifiez votre connexion internet.');
    } on HttpException {
      // HTTP-related issues
      throw Exception('Problème de réseau. Veuillez réessayer.');
    } catch (e) {
      throw Exception('Erreur de connexion. Veuillez réessayer.');
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

  static Future<List<User>> fetchUsers() async {
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
      final List<dynamic> usersJson = jsonDecode(response.body);
      final List<User> apiUsers = usersJson.map((userJson) => User.fromJson(userJson)).toList();

      // Sync the fetched users with local database
      await LocalDatabaseService.instance.syncUsersFromApi(apiUsers);

      return apiUsers;
    } else {
      throw Exception('Failed to fetch users: ${response.body}');
    }
  }

  // Get users from local database with API fallback
  static Future<List<User>> getUsers({bool forceRefresh = false}) async {
    final localDb = LocalDatabaseService.instance;

    // If force refresh is requested or no users exist locally, fetch from API
    if (forceRefresh || !(await localDb.hasUsers())) {
      try {
        // Try to fetch from API and sync to local database
        return await fetchUsers();
      } catch (e) {
        debugPrint('Failed to fetch users from API: $e');
        // If API fails, return local users (might be empty)
        return await localDb.getUsers();
      }
    }

    // Return users from local database
    return await localDb.getUsers();
  }

  static Future<List<Task>> fetchTasks() async {
    final url = '$baseUrl${ApiModel.tasks}';
    debugPrint('GET $url');

    final response = await http
        .get(
          Uri.parse(url),
          headers: _headers,
        )
        .timeout(Duration(seconds: 5));

    debugPrint('Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> tasksJson = jsonDecode(response.body);
      final List<Task> apiTasks = tasksJson.map((taskJson) => Task.fromApiJson(taskJson)).toList();

      // Sync the fetched tasks with local database
      await LocalDatabaseService.instance.syncTasksFromApi(apiTasks);

      return apiTasks;
    } else {
      throw Exception('Failed to fetch tasks: ${response.body}');
    }
  }

  // Get tasks from local database with API fallback
  static Future<List<Task>> getTasks({bool forceRefresh = false}) async {
    final localDb = LocalDatabaseService.instance;

    // If force refresh is requested or no tasks exist locally, fetch from API
    if (forceRefresh || !(await localDb.hasTasks())) {
      try {
        // Try to fetch from API and sync to local database
        return await fetchTasks();
      } catch (e) {
        debugPrint('Failed to fetch tasks from API: $e');
        // If API fails, return local tasks (might be empty)
        return await localDb.getTasks();
      }
    }

    // Return tasks from local database
    return await localDb.getTasks();
  }

  // Refresh users call (for when editing/adding tasks)
  static Future<void> refreshUsers() async {
    try {
      await fetchUsers();
    } catch (e) {
      debugPrint('Failed to refresh users: $e');
      // If it fails, continue with local database
    }
  }

  static Future<Task> createTask(Task task) async {
    final url = '$baseUrl${ApiModel.tasks}';
    debugPrint('POST $url');

    try {
      final requestBody = task.toJson();

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: ApiModel.timeoutInSec));

      debugPrint('Request body: ${jsonEncode(requestBody)}');
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        final serverTaskId = responseJson['taskId'] as int;

        // Create the task with the server-assigned ID
        final createdTask = Task(
          id: serverTaskId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          ownerId: task.ownerId,
          assignedId: task.assignedId,
          dueDate: task.dueDate,
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to local database
        await LocalDatabaseService.instance.addTask(createdTask);

        return createdTask;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la création de la tâche: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé lors de la création de la tâche.');
    } on SocketException {
      throw Exception('Impossible de créer la tâche. Vérifiez votre connexion internet.');
    } on HttpException {
      throw Exception('Erreur réseau lors de la création de la tâche.');
    } catch (e) {
      throw Exception('Erreur lors de la création de la tâche: $e');
    }
  }

  static Future<void> logout() async {
    await _secureStorage.deleteToken();
    _authToken = null;
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

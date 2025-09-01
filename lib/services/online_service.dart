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
import 'package:project/services/rate_limiter_service.dart';
import 'package:project/services/connectivity_service.dart';
import 'package:project/services/notif_service.dart';

import '../main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/current_user.dart';

class Result<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const Result.success(this.data) : isSuccess = true, errorMessage = null;
  const Result.error(this.errorMessage) : isSuccess = false, data = null;
}

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

  static Future<Result<CurrentUser>> register({
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
        .timeout(Duration(seconds: 20));

    debugPrint('Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      await _secureStorage.writeToken(token);
      setAuthToken(token);

      final currentUser = CurrentUser.fromAuthResponse(data, email, username);
      return Result.success(currentUser);
    } else {
      return Result.error('Registration failed: ${response.body}');
    }
  }

  static Future<Result<CurrentUser>> login({
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
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: 20));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['id'];

        // Store token and expiry in secure storage
        await _secureStorage.writeToken(token);
        setAuthToken(token);

        final userDetailsResult = await _fetchUserDetails(userId);
        if (userDetailsResult.isSuccess) {
          final userDetails = userDetailsResult.data!;
          final currentUser = CurrentUser(
            id: userId,
            token: token,
            email: userDetails['email'] ?? email,
            username: userDetails['username'] ?? '',
          );
          return Result.success(currentUser);
        } else {
          // If fetching user details fails, create user with basic info
          debugPrint(
            'Failed to fetch user details: ${userDetailsResult.errorMessage}',
          );
          final currentUser = CurrentUser(
            id: userId,
            token: token,
            email: email,
            username: '', // Will be empty if we can't fetch it
          );
          return Result.success(currentUser);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication failed - wrong credentials
        return Result.error('Email ou mot de passe incorrect');
      } else {
        // Server error or other HTTP error
        return Result.error('Erreur du serveur: ${response.statusCode}');
      }
    } on TimeoutException {
      // Network timeout
      return Result.error(
        'Délai d\'attente dépassé. Vérifiez votre connexion internet.',
      );
    } on SocketException {
      // No internet connection or server unreachable
      return Result.error(
        'Serveur inaccessible. Vérifiez votre connexion internet.',
      );
    } on HttpException {
      // HTTP-related issues
      return Result.error('Problème de réseau. Veuillez réessayer.');
    } catch (e) {
      return Result.error('Erreur de connexion. Veuillez réessayer.');
    }
  }

  static Future<Result<Map<String, dynamic>>> _fetchUserDetails(
    int userId,
  ) async {
    final url = '$baseUrl${ApiModel.users}';
    debugPrint('GET $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 20));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        // Find the current user in the users list
        final user = users.firstWhere(
          (user) => user['id'] == userId,
          orElse: () => null,
        );
        if (user != null) {
          return Result.success(user);
        } else {
          return Result.error('User not found');
        }
      } else {
        return Result.error('Failed to fetch user details: ${response.body}');
      }
    } catch (e) {
      return Result.error('Error fetching user details: $e');
    }
  }

  static Future<Result<List<User>>> fetchUsers() async {
    final rateLimiter = RateLimiterService();
    const endpoint = 'users';

    // Check if we can make the call based on rate limiting
    if (!rateLimiter.canMakeCall(endpoint)) {
      return Result.error('Rate limited - using local data');
    }

    final url = '$baseUrl${ApiModel.users}';
    debugPrint('GET $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 20));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        // Record successful API call
        rateLimiter.recordCall(endpoint);

        final List<dynamic> usersJson = jsonDecode(response.body);
        final List<User> apiUsers = usersJson
            .map((userJson) => User.fromJson(userJson))
            .toList();

        // Sync the fetched users with local database
        await LocalDatabaseService.instance.syncUsersFromApi(apiUsers);

        return Result.success(apiUsers);
      } else {
        return Result.error('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      return Result.error('Error fetching users: $e');
    }
  }

  // Get users from local database with API fallback
  static Future<List<User>> getUsers({bool forceRefresh = false}) async {
    final localDb = LocalDatabaseService.instance;

    // If force refresh is requested or no users exist locally, fetch from API
    if (forceRefresh || !(await localDb.hasUsers())) {
      final result = await fetchUsers();
      if (result.isSuccess) {
        return result.data!;
      } else {
        debugPrint('Failed to fetch users from API: ${result.errorMessage}');
        // For rate limiting or any other API failure, silently fall back to local data
        return await localDb.getUsers();
      }
    }

    // Return users from local database
    return await localDb.getUsers();
  }

  static Future<Result<List<Task>>> fetchTasks() async {
    final rateLimiter = RateLimiterService();
    const endpoint = 'tasks';

    // Check if we can make the call based on rate limiting
    if (!rateLimiter.canMakeCall(endpoint)) {
      return Result.error('Rate limited - using local data');
    }

    final url = '$baseUrl${ApiModel.tasks}';
    debugPrint('GET $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 20));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        // Record successful API call
        rateLimiter.recordCall(endpoint);

        final List<dynamic> tasksJson = jsonDecode(response.body);
        final List<Task> apiTasks = tasksJson
            .map((taskJson) => Task.fromApiJson(taskJson))
            .toList();

        // Sync the fetched tasks with local database
        await LocalDatabaseService.instance.syncTasksFromApi(apiTasks);

        return Result.success(apiTasks);
      } else {
        return Result.error('Failed to fetch tasks: ${response.body}');
      }
    } catch (e) {
      return Result.error('Error fetching tasks: $e');
    }
  }

  // Get tasks from local database with API fallback
  static Future<List<Task>> getTasks({bool forceRefresh = false}) async {
    final localDb = LocalDatabaseService.instance;

    // If force refresh is requested or no tasks exist locally, fetch from API
    if (forceRefresh || !(await localDb.hasTasks())) {
      final result = await fetchTasks();
      if (result.isSuccess) {
        return result.data!;
      } else {
        debugPrint('Failed to fetch tasks from API: ${result.errorMessage}');
        // For rate limiting or any other API failure, silently fall back to local data
        return await localDb.getTasks();
      }
    }

    // Return tasks from local database
    return await localDb.getTasks();
  }

  // Refresh users call (for when editing/adding tasks)
  static Future<void> refreshUsers() async {
    final result = await fetchUsers();
    if (!result.isSuccess) {
      debugPrint('Failed to refresh users: ${result.errorMessage}');
      // If it fails, continue with local database
    }
  }

  static Future<Result<Task>> createTask(Task task) async {
    final localDb = LocalDatabaseService.instance;
    final connectivity = ConnectivityService.instance;

    // Check connectivity first
    final isOnline = await connectivity.isOnline();

    if (!isOnline) {
      // Create task offline with local ID
      final localTaskId = DateTime.now().millisecondsSinceEpoch;
      final pendingTask = Task(
        id: localTaskId,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: false,
        isPending: true, // Mark as pending
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local database
      await localDb.addTask(pendingTask);

      // Add to pending changes
      await localDb.addPendingChange(
        taskId: localTaskId,
        changeType: 'CREATE',
        beforeChange: {},
        afterChange: pendingTask.toJson(),
      );

      return Result.success(pendingTask);
    }

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
          isPending: false, // Not pending since it was created successfully
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to local database
        await localDb.addTask(createdTask);

        return Result.success(createdTask);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return Result.error('Session expirée. Veuillez vous reconnecter.');
      } else {
        return Result.error(
          'Erreur lors de la création de la tâche: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      // Handle timeout by creating pending task
      final localTaskId = DateTime.now().millisecondsSinceEpoch;
      final pendingTask = Task(
        id: localTaskId,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: false,
        isPending: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDb.addTask(pendingTask);
      await localDb.addPendingChange(
        taskId: localTaskId,
        changeType: 'CREATE',
        beforeChange: {},
        afterChange: pendingTask.toJson(),
      );

      return Result.success(pendingTask);
    } on SocketException {
      // Handle network error by creating pending task
      final localTaskId = DateTime.now().millisecondsSinceEpoch;
      final pendingTask = Task(
        id: localTaskId,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: false,
        isPending: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDb.addTask(pendingTask);
      await localDb.addPendingChange(
        taskId: localTaskId,
        changeType: 'CREATE',
        beforeChange: {},
        afterChange: pendingTask.toJson(),
      );

      return Result.success(pendingTask);
    } on HttpException {
      return Result.error('Erreur réseau lors de la création de la tâche.');
    } catch (e) {
      return Result.error('Erreur lors de la création de la tâche: $e');
    }
  }

  static Future<Result<Task>> updateTask(Task task) async {
    final localDb = LocalDatabaseService.instance;
    final connectivity = ConnectivityService.instance;

    // Check connectivity first
    final isOnline = await connectivity.isOnline();

    if (!isOnline) {
      // Store original task state before changes
      final originalTask = await localDb.getTasks().then(
        (tasks) => tasks.firstWhere((t) => t.id == task.id, orElse: () => task),
      );

      // Update task locally and mark as pending
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        isPending: true, // Mark as pending
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to local database
      await localDb.updateTask(updatedTask);

      // Add to pending changes
      await localDb.addPendingChange(
        taskId: task.id!,
        changeType: 'UPDATE',
        beforeChange: originalTask.toJson(),
        afterChange: updatedTask.toJson(),
      );

      return Result.success(updatedTask);
    }

    // First check if task is completed remotely before updating
    final remoteTaskResult = await _fetchSingleTask(task.id!);
    if (remoteTaskResult.isSuccess) {
      final remoteTask = remoteTaskResult.data!;
      if (remoteTask.isCompleted) {
        // Show notification that task can't be updated because it's completed
        await NotifService().showNotification(
          id: task.getId,
          title: 'Mise à jour impossible',
          body:
              'La tâche ${task.title} ne peut pas être modifiée car elle est déjà terminée.',
        );
        return Result.error(
          'La tâche ne peut pas être modifiée car elle est déjà terminée.',
        );
      }
    }

    final url = '$baseUrl${ApiModel.tasks}/${task.getId}';
    debugPrint('PUT $url');

    try {
      final requestBody = task.toJson();

      final response = await http
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(requestBody))
          .timeout(Duration(seconds: ApiModel.timeoutInSec));

      debugPrint('Request body: ${jsonEncode(requestBody)}');
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update task to not pending since it was successful
        final updatedTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          priority: task.priority,
          ownerId: task.ownerId,
          assignedId: task.assignedId,
          dueDate: task.dueDate,
          isCompleted: task.isCompleted,
          isPending: false, // Not pending since it was updated successfully
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );

        // Save to local database
        await localDb.updateTask(updatedTask);

        return Result.success(updatedTask);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return Result.error('Session expirée. Veuillez vous reconnecter.');
      } else {
        return Result.error(
          'Erreur lors de la modification de la tâche: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      // Handle timeout by storing as pending change
      final originalTask = await localDb.getTasks().then(
        (tasks) => tasks.firstWhere((t) => t.id == task.id, orElse: () => task),
      );

      final pendingTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        isPending: true,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDb.updateTask(pendingTask);
      await localDb.addPendingChange(
        taskId: task.id!,
        changeType: 'UPDATE',
        beforeChange: originalTask.toJson(),
        afterChange: pendingTask.toJson(),
      );

      return Result.success(pendingTask);
    } on SocketException {
      // Handle network error by storing as pending change
      final originalTask = await localDb.getTasks().then(
        (tasks) => tasks.firstWhere((t) => t.id == task.id, orElse: () => task),
      );

      final pendingTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        ownerId: task.ownerId,
        assignedId: task.assignedId,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        isPending: true,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDb.updateTask(pendingTask);
      await localDb.addPendingChange(
        taskId: task.id!,
        changeType: 'UPDATE',
        beforeChange: originalTask.toJson(),
        afterChange: pendingTask.toJson(),
      );

      return Result.success(pendingTask);
    } on HttpException {
      return Result.error('Erreur réseau lors de la modification de la tâche.');
    } catch (e) {
      return Result.error('Erreur lors de la modification de la tâche: $e');
    }
  }

  static Future<Result<void>> deleteTask(int taskId) async {
    final url = '$baseUrl${ApiModel.tasks}/$taskId';
    debugPrint('DELETE $url');

    try {
      final response = await http
          .delete(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: ApiModel.timeoutInSec));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await LocalDatabaseService.instance.deleteTask(taskId);
        return Result.success(null);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return Result.error('Session expirée. Veuillez vous reconnecter.');
      } else {
        return Result.error(
          'Erreur lors de la suppression de la tâche: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return Result.error(
        'Délai d\'attente dépassé lors de la suppression de la tâche.',
      );
    } on SocketException {
      return Result.error(
        'Impossible de supprimer la tâche. Vérifiez votre connexion internet.',
      );
    } on HttpException {
      return Result.error('Erreur réseau lors de la suppression de la tâche.');
    } catch (e) {
      return Result.error('Erreur lors de la suppression de la tâche: $e');
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

  // Helper method to fetch a single task for validation
  static Future<Result<Task>> _fetchSingleTask(int taskId) async {
    final url = '$baseUrl${ApiModel.tasks}/$taskId';
    debugPrint('GET $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 5));

      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final taskJson = jsonDecode(response.body);
        final task = Task.fromApiJson(taskJson);
        return Result.success(task);
      } else {
        return Result.error('Failed to fetch task: ${response.body}');
      }
    } catch (e) {
      return Result.error('Error fetching task: $e');
    }
  }

  // Auto-sync pending changes when connection is restored
  static Future<void> syncPendingChanges() async {
    final localDb = LocalDatabaseService.instance;
    final connectivity = ConnectivityService.instance;

    // Check if we're online
    final isOnline = await connectivity.isOnline();
    if (!isOnline) {
      debugPrint('Cannot sync: No internet connection');
      return;
    }

    // Get all pending changes
    final pendingChanges = await localDb.getPendingChanges();
    if (pendingChanges.isEmpty) {
      debugPrint('No pending changes to sync');
      return;
    }

    debugPrint('Syncing ${pendingChanges.length} pending changes...');

    for (final change in pendingChanges) {
      final changeId = change['id'] as int;
      final taskId = change['task_id'] as int;
      final changeType = change['change_type'] as String;
      final afterChangeJson = jsonDecode(change['after_change']);

      try {
        if (changeType == 'CREATE') {
          // Try to create the task on the server
          final taskData = Task(
            id: null, // Will be assigned by server
            title: afterChangeJson['title'],
            description: afterChangeJson['description'],
            priority: Priority.values.firstWhere(
              (p) =>
                  p.toString().split('.')[1].toUpperCase() ==
                  afterChangeJson['priority'],
              orElse: () => Priority.low,
            ),
            ownerId: afterChangeJson['ownerId'] ?? 1,
            assignedId: afterChangeJson['assigneeId'] != null
                ? User(
                    id: afterChangeJson['assigneeId'],
                    username: '',
                    email: '',
                  )
                : null,
            dueDate: DateTime.fromMillisecondsSinceEpoch(
              afterChangeJson['dueDate'] * 1000,
            ),
            isCompleted: afterChangeJson['completed'] ?? false,
            isPending: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final result = await _createTaskOnServer(taskData);
          if (result.isSuccess) {
            final serverTask = result.data!;
            // Update local task with server ID
            await localDb.markTaskAsSynced(taskId, serverTask.id!);
            // Mark pending change as synced
            await localDb.markPendingChangeSynced(changeId);
            debugPrint(
              'Successfully synced CREATE for task $taskId -> ${serverTask.id}',
            );
          } else {
            debugPrint(
              'Failed to sync CREATE for task $taskId: ${result.errorMessage}',
            );
          }
        } else if (changeType == 'UPDATE') {
          // First check if the task is completed remotely
          final remoteTaskResult = await _fetchSingleTask(taskId);
          if (remoteTaskResult.isSuccess &&
              remoteTaskResult.data!.isCompleted) {
            // Task is completed remotely, show notification and remove pending change
            await NotifService().showNotification(
              id: taskId,
              title: 'Synchronisation impossible',
              body: 'La tâche ne peut pas être synchronisée car elle est déjà terminée sur le serveur.',
            );
            await localDb.markPendingChangeSynced(changeId);
            debugPrint('Skipped UPDATE for completed task $taskId');
            continue;
          }

          // Try to update the task on the server
          final taskData = Task(
            id: taskId,
            title: afterChangeJson['title'],
            description: afterChangeJson['description'],
            priority: Priority.values.firstWhere(
              (p) =>
                  p.toString().split('.')[1].toUpperCase() ==
                  afterChangeJson['priority'],
              orElse: () => Priority.low,
            ),
            ownerId: afterChangeJson['ownerId'] ?? 1,
            assignedId: afterChangeJson['assigneeId'] != null
                ? User(
                    id: afterChangeJson['assigneeId'],
                    username: '',
                    email: '',
                  )
                : null,
            dueDate: DateTime.fromMillisecondsSinceEpoch(
              afterChangeJson['dueDate'] * 1000,
            ),
            isCompleted: afterChangeJson['completed'] ?? false,
            isPending: false,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              afterChangeJson['createdAt'] ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            updatedAt: DateTime.now(),
          );

          final result = await _updateTaskOnServer(taskData);
          if (result.isSuccess) {
            // Update local task to not pending
            await localDb.updateTask(taskData);
            // Mark pending change as synced
            await localDb.markPendingChangeSynced(changeId);
            debugPrint('Successfully synced UPDATE for task $taskId');
          } else {
            debugPrint(
              'Failed to sync UPDATE for task $taskId: ${result.errorMessage}',
            );
          }
        }
      } catch (e) {
        debugPrint('Error syncing change $changeId: $e');
      }
    }

    debugPrint('Pending changes sync completed');
  }

  // Helper method to create task on server without offline handling
  static Future<Result<Task>> _createTaskOnServer(Task task) async {
    final url = '$baseUrl${ApiModel.tasks}';
    debugPrint('POST $url (sync)');

    try {
      final requestBody = task.toJson();

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: ApiModel.timeoutInSec));

      debugPrint('Sync request body: ${jsonEncode(requestBody)}');
      debugPrint('Sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        final serverTaskId = responseJson['taskId'] as int;

        final createdTask = Task(
          id: serverTaskId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          ownerId: task.ownerId,
          assignedId: task.assignedId,
          dueDate: task.dueDate,
          isCompleted: task.isCompleted,
          isPending: false,
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );

        return Result.success(createdTask);
      } else {
        return Result.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return Result.error('Sync error: $e');
    }
  }

  // Helper method to update task on server without offline handling
  static Future<Result<Task>> _updateTaskOnServer(Task task) async {
    final url = '$baseUrl${ApiModel.tasks}/${task.id}';
    debugPrint('PUT $url (sync)');

    try {
      final requestBody = task.toJson();

      final response = await http
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(requestBody))
          .timeout(Duration(seconds: ApiModel.timeoutInSec));

      debugPrint('Sync request body: ${jsonEncode(requestBody)}');
      debugPrint('Sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Result.success(task);
      } else {
        return Result.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return Result.error('Sync error: $e');
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

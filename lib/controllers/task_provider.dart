import 'package:flutter/material.dart';
import 'dart:async';
import 'package:project/models/task_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/online_service.dart';
import 'package:project/utils/utils.dart';

import '../models/task_filter.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  BuildContext? _context;

  List<Task> get tasks => _tasks;

  bool get isLoading => _isLoading;

  String? get error => _error;

  TaskFilterSettings _filterSettings = const TaskFilterSettings();

  TaskFilterSettings get filterSettings => _filterSettings;

  final LocalDatabaseService _databaseService = LocalDatabaseService.instance;

  Timer? _refreshTimer;

  /// Set the context for showing SnackBar messages
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Show error in SnackBar if it's not authentication-related
  void _showErrorIfNotAuth(String errorMessage) {
    if (_context != null) {
      Utils.showErrorSnackBar(_context!, errorMessage);
    }
  }

  Future<void> loadTasks({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to get tasks from API and sync to local database
      if (forceRefresh) {
        _tasks = await ApiService.getTasks(forceRefresh: true);
      } else {
        // Check if we have tasks locally, if not fetch from API
        final hasLocalTasks = await _databaseService.hasTasks();
        if (!hasLocalTasks) {
          _tasks = await ApiService.getTasks();
        } else {
          // Load from local database with current filter settings
          _tasks = await _databaseService.getTasks(
            status: _filterSettings.status,
            sortType: _filterSettings.sortType,
          );
        }
      }
    } catch (e) {
      final errorMessage = 'Error loading tasks: $e';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);
      debugPrint('Error loading tasks: $e');
      // Fallback to local database even if API fails
      try {
        _tasks = await _databaseService.getTasks(
          status: _filterSettings.status,
          sortType: _filterSettings.sortType,
        );
      } catch (localError) {
        debugPrint('Error loading local tasks: $localError');
        _tasks = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterTasks(TaskStatus status) async {
    if (_filterSettings.status == status) return; // No change needed

    _filterSettings = _filterSettings.copyWith(status: status);
    await loadTasks();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(int taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  Future<void> refreshTasks() async {
    await loadTasks(forceRefresh: true);
  }

  Future<void> createTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.createTask(task);

    if (result.isSuccess) {
      // Add the task to local list
      _tasks.add(result.data!);

      // Sort tasks based on current filter settings
      if (_filterSettings.sortType == SortType.dueDate) {
        _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      } else if (_filterSettings.sortType == SortType.priority) {
        _tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      } else if (_filterSettings.sortType == SortType.createdDate) {
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      debugPrint('Task created successfully with ID: ${result.data!.id}');
    } else {
      debugPrint('Error creating task: ${result.errorMessage}');
      final errorMessage = result.errorMessage ?? 'Failed to create task';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);

      // If API fails, try to save locally for later sync
      try {
        final localId = await _databaseService.addTask(task);
        final taskWithLocalId = Task(
          id: localId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          ownerId: task.ownerId,
          assignedId: task.assignedId,
          dueDate: task.dueDate,
          isCompleted: task.isCompleted,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        );
        _tasks.add(taskWithLocalId);
      } catch (localError) {
        debugPrint('Failed to save task locally: $localError');
        final localErrorMessage = 'Failed to create task: $errorMessage';
        _error = localErrorMessage;
        _showErrorIfNotAuth(localErrorMessage);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.updateTask(task);

    if (result.isSuccess) {
      // Update the task in local list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }

      debugPrint('Task updated successfully with ID: ${task.id}');
    } else {
      debugPrint('Error updating task: ${result.errorMessage}');
      final errorMessage = result.errorMessage ?? 'Failed to update task';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);

      // If API fails, try to update locally for later sync
      try {
        await _databaseService.updateTask(task);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
        }

        debugPrint('Task updated locally for later sync');
      } catch (localError) {
        debugPrint('Failed to update task locally: $localError');
        final localErrorMessage = 'Failed to update task: $errorMessage';
        _error = localErrorMessage;
        _showErrorIfNotAuth(localErrorMessage);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Task? getTaskById(int? id) {
    if (id == null) return null;
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<TaskStatus, int>> getTasksCountByStatus() async {
    try {
      final counts = <TaskStatus, int>{};
      for (final status in TaskStatus.values) {
        if (status == TaskStatus.all) {
          counts[status] = _tasks.length;
        } else {
          final filteredTasks = await _databaseService.getTasks(status: status);
          counts[status] = filteredTasks.length;
        }
      }
      return counts;
    } catch (e) {
      final errorMessage = 'get tasks count by status error: $e';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void startPeriodicRefresh() {
    _refreshTimer?.cancel(); // Cancel any existing timer
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      refreshTasks();
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopPeriodicRefresh();
    super.dispose();
  }
}

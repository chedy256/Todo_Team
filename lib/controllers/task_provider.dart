import 'package:flutter/foundation.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/online_service.dart';

import '../models/task_filter.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;

  bool get isLoading => _isLoading;

  String? get error => _error;

  TaskFilterSettings _filterSettings = const TaskFilterSettings();

  TaskFilterSettings get filterSettings => _filterSettings;

  final LocalDatabaseService _databaseService = LocalDatabaseService.instance;

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
      _error = 'Error loading tasks: $e';
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

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
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

    try {
      // Create task via API and get the actual task with server-assigned ID
      final createdTask = await ApiService.createTask(task);

      // Add the task to local list
      _tasks.add(createdTask);

      // Sort tasks based on current filter settings
      if (_filterSettings.sortType == SortType.dueDate) {
        _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      } else if (_filterSettings.sortType == SortType.priority) {
        _tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      } else if (_filterSettings.sortType == SortType.createdDate) {
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      debugPrint('Task created successfully with ID: ${createdTask.id}');
    } catch (e) {
      debugPrint('Error creating task: $e');

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

        debugPrint('Task saved locally with ID: $localId for later sync');
      } catch (localError) {
        debugPrint('Failed to save task locally: $localError');
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _error = 'get tasks count by status error: $e';
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

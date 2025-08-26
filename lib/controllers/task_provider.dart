import 'package:flutter/foundation.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/local_database_service.dart';

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

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _databaseService.getTasks(
        status: _filterSettings.status,
        sortType: _filterSettings.sortType,
      );
    } catch (e) {
      _error = 'Error loading tasks: $e';
      debugPrint('Error loading tasks: $e');
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
    if (_filterSettings.sortType == SortType.dueDate) {
      _tasks.insert(0, task);
    }
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

  void refreshTasks() {
    loadTasks();
  }

  Task? getTaskById(int id) {
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

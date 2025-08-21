import 'package:flutter/foundation.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/local_database_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final LocalDatabaseService _databaseService = LocalDatabaseService.instance;

  Future<void> loadTasks() async {
    _setLoading(true);
    _error = null;
    
    try {
      _tasks = await _databaseService.getTasks();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des tâches: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
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

  void refreshTasks() {
    loadTasks();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

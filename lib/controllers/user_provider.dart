import 'package:flutter/foundation.dart';
import 'package:project/models/user_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/online_service.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final LocalDatabaseService _databaseService = LocalDatabaseService.instance;

  Future<void> loadUsers({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        _users = await _databaseService.getUsers();
        
        // If no users in local database, fetch from API
        if (_users.isEmpty) {
          await _fetchUsersFromApi();
        }
      } else {
        // Force refresh from API
        await _fetchUsersFromApi();
      }
    } catch (e) {
      _error = 'Error loading users: $e';
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUsersFromApi() async {
    try {
      _users = await ApiService.fetchUsers();
    } catch (e) {
      // If API fails, try to get users from local database as fallback
      _users = await _databaseService.getUsers();
      if (_users.isEmpty) {
        rethrow; // Re-throw if we have no fallback data
      }
    }
  }

  Future<void> refreshUsers() async {
    await loadUsers(forceRefresh: true);
  }

  User? getUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addOrUpdateUser(User user) async {
    try {
      await _databaseService.addOrUpdateUser(user);
      
      // Update local list
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
      } else {
        _users.add(user);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error adding/updating user: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool get hasUsers => _users.isNotEmpty;
}

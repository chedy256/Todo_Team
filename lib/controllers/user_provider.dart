import 'package:flutter/material.dart';
import 'package:project/models/user_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/online_service.dart';
import 'package:project/utils/utils.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  BuildContext? _context;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final LocalDatabaseService _databaseService = LocalDatabaseService.instance;

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

  Future<void> loadUsers({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the new ApiService.getUsers method that handles API fetching and local database fallback
      _users = await ApiService.getUsers(forceRefresh: forceRefresh);
    } catch (e) {
      final errorMessage = 'Error loading users: $e';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);
      debugPrint('Error loading users: $e');
      // Final fallback to empty list if everything fails
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final errorMessage = 'Error adding/updating user: $e';
      _error = errorMessage;
      _showErrorIfNotAuth(errorMessage);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool get hasUsers => _users.isNotEmpty;
}

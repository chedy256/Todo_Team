import 'package:flutter/cupertino.dart';
import 'package:project/models/current_user.dart';
import '../models/user_model.dart';

class AuthController {
  bool _isLoading = false;
  CurrentUser? _currentUser;

  static Future<bool> checkEmailExists(String email) async {
    // API call to check if email exists
    await Future.delayed(Duration(seconds: 1));
    List<String> existingEmails = ['test@example.com', 'user@gmail.com'];
    return existingEmails.contains(email.toLowerCase());
  }

  static Future<CurrentUser?> login(String email, String password) async {
    // Sign in logic
    await Future.delayed(Duration(seconds: 1));
    //return null;
    return CurrentUser(id: 123, name: "Frid", email: email,token: 123);
  }

  Future<CurrentUser?> signup(String email, String password, String name) async {
    // Sign up logic
    await Future.delayed(Duration(seconds: 1));
    return CurrentUser(id: 123, name: name, email: email,token: 123);
  }


  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

//to remove maybe
  static bool isValidEmail(String email){
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return email.isEmpty || regex.hasMatch(email) || email.contains('='' ');
  }

  static Future<User?> loginWithEmail(String email) async {
    if(!isValidEmail(email)) return null;
    await Future.delayed(Duration(seconds: 1));

    if (await checkEmailExists(email)) {
      return User(email: email, name: 'John Doe');
    }

    return null;
  }
  void handleNext(BuildContext context){

  }
}


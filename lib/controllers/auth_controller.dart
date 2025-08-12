import 'package:flutter/material.dart';
//import 'package:project/models/current_user.dart';

import '../main.dart';
import '../models/current_user.dart';

class AuthController {
  static bool isLoggedIn=false;
  static late String email;

  static Future<bool> checkEmailExists(
    String email,
    BuildContext context,
  ) async {
    //loading Circle
    showDialog(
      context: context,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    // API call to check if email exists
    await Future.delayed(Duration(seconds: 1));
    List<String> existingEmails = ['test@example.com', 'user@gmail.com'];
    //pops the loading Circle
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    return existingEmails.contains(email.toLowerCase());
  }

  static Future<void> login(String password, BuildContext context) async {
    //loading Circle
    showDialog(
      context: context,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    // Sign in logic
    await Future.delayed(Duration(seconds: 1));
    //return null;
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (password == 'admin' && context.mounted) {
      isLoggedIn=true;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/tasks', (route) => false,
      );
    }
  }

  static Future<void> signup(
    String password,
    String name,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    // Sign up logic
    await Future.delayed(Duration(seconds: 1));
    currentUser = CurrentUser(id: 123, name: name, email: email, token: 123);
    isLoggedIn=true;

    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/tasks',
            (route) => false,
      );
    }
  }
  static void logout(BuildContext context){
    //delete all the files or just the currentuser in case of re-login i can check between last user and new user (drop local storage for example)
    isLoggedIn=false;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/email',
          (route) => false,
    );
  }

  static Future<void> checkEmail(
    String emailInput,
    BuildContext context,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    if(context.mounted) {
      final bool exists = await checkEmailExists(emailInput, context);
      email=emailInput;
      if (exists && context.mounted) {
        Navigator.pushNamed(context, '/login');
      }
      if (!exists && context.mounted) {
        Navigator.pushNamed(context, '/signup');
      }
    }
  }
}

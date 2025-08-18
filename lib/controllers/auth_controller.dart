import 'package:flutter/material.dart';
import 'package:project/models/current_user.dart';
import 'package:project/services/dialogs_service.dart';

import '../main.dart';

class AuthController {
  static final AuthController instance = AuthController._constructor();

  static bool isLoggedIn = false;
  AuthController._constructor();

  Future<void> login(String email,String password, BuildContext context) async {
    //loading Circle
    showDialog(
      context: context,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    // Sign in logic
    await Future.delayed(Duration(seconds: 1));
    if (context.mounted) {
      Navigator.of(context).pop();
      if ( email=='user@gmail.com' && password == 'admin') {
        currentUser = CurrentUser(id: 123, name: 'admin', email: email, token: 122);
        isLoggedIn = true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tasks',
              (route) => false,
        );
      }
      else {
        DialogService.showInfoDialog(context, 'Connexion echouié', 'Email ou mot de passe incorrect');
      }
    }
  }
  Future<void> signup(
      String email,
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
    currentUser = CurrentUser(id: 123, name: name, email: email, token: 122);
    isLoggedIn = true;

    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/tasks',
            (route) => false,
      );
    }
  }
  void logout(BuildContext context) {
    //delete all the files or just the currentUser in case of re-login
    isLoggedIn = false;
    currentUser=null;
    Navigator.pushReplacementNamed(context, '/login');
  }
  void goSignUp(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signup');
  }
  void goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context,'/login');
  }
}

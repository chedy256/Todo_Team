import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';
import 'package:project/services/secure_storage.dart';

import '../models/user_model.dart';
import '../services/online_service.dart';

class AuthController {
  static final AuthController instance = AuthController._constructor();
  static User? currentUser;
  final SecureStorage secureStorage = SecureStorage.instance;
  AuthController._constructor();

    Future<void> login(String email,String password, BuildContext context) async {
    //loading Circle
    showDialog(
      context: context,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    ApiService.login(email: email, password: password);
    await Future.delayed(Duration(seconds: 1));
    if (context.mounted) {
      Navigator.of(context).pop();
      if ( email=='user@gmail.com' && password == 'admin') {
        currentUser=User(id: 123, username: 'admin', email: email);

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
    try {
      await ApiService.register(email: email, password: password, username: name);
    }catch(e){
      if (context.mounted) {
        DialogService.showErrorDialog(context, e.toString());
      }
    }

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
    secureStorage.deleteToken();
    currentUser = null;
    Navigator.pushReplacementNamed(context, '/login');
  }
  void goSignUp(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signup');
  }
  void goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context,'/login');
  }
}

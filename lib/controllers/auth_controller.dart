import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';

import '../models/current_user.dart';
import '../services/online_service.dart';

class AuthController {
  static final AuthController instance = AuthController._constructor();
  static CurrentUser? currentUser;
  AuthController._constructor();

  Future<void> login(String email, String password, BuildContext context) async {
    // Loading Circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final user = await ApiService.login(email: email, password: password);
      currentUser = user;

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tasks',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        DialogService.showInfoDialog(
          context,
          'Connexion échouée',
          'Email ou mot de passe incorrect'
        );
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
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final user = await ApiService.register(
        email: email,
        password: password,
        username: name
      );
      currentUser = user;

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tasks',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        DialogService.showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    await ApiService.logout();
    currentUser = null;
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // Check if user is logged in on app start
  Future<void> checkAuthStatus() async {
    currentUser=  await ApiService.isTokenValid()? currentUser : null;
  }

  void goSignUp(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  void goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}

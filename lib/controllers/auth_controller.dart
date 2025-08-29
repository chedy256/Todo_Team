import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';
import 'package:project/services/notif_service.dart';

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

    final result = await ApiService.login(email: email, password: password);

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (result.isSuccess) {
        currentUser = result.data;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tasks',
          (route) => false,
        );
      } else {
        DialogService.showErrorDialog(
          context,
          result.errorMessage ?? 'Erreur de connexion inconnue'
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

    final result = await ApiService.register(
      email: email,
      password: password,
      username: name
    );

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (result.isSuccess) {
        currentUser = result.data;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tasks',
          (route) => false,
        );
      } else {
        DialogService.showErrorDialog(
          context,
          result.errorMessage ?? 'Erreur d\'inscription inconnue'
        );
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    await ApiService.logout();
    NotifService().cancelAllNotifications();
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

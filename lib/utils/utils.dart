import 'package:flutter/material.dart';

class Utils {
  static String timeLeft(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Expiré';
    }
  }

  /// Shows an error message in a SnackBar
  /// Excludes authentication-related errors from SnackBar display
  static void showErrorSnackBar(BuildContext context, String message) {
    // Skip authentication-related errors
    if (_isAuthenticationError(message)) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success message in a SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Checks if an error message is authentication-related
  static bool _isAuthenticationError(String message) {
    final authKeywords = [
      'email ou mot de passe incorrect',
      'authentication',
      'login',
      'connexion',
      'authentification',
      'token',
      'unauthorized',
      '401',
      '403',
      'forbidden',
    ];

    final lowerMessage = message.toLowerCase();
    return authKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
}

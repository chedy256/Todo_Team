import 'package:flutter/material.dart';

class UIController extends ChangeNotifier{
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isValidEmail = false;
  //String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Password validation methods
  void validatePassword(String password) {
    //change to a widget change
    if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
    } else if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      _passwordError = 'Password must contain letters and numbers';
    } else {
      _passwordError = null;
    }
    _validatePasswordMatch(); // Check match when password changes
    notifyListeners();
  }

  void validateConfirmPassword(String confirmPassword) {
    _validatePasswordMatch();
    notifyListeners();
  }

  void _validatePasswordMatch() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (confirmPassword.isNotEmpty && password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
    } else {
      _confirmPasswordError = null;
    }
  }

  // Toggle visibility methods
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // Validation getters
  bool get isValidPassword => passwordController.text.isNotEmpty && _passwordError == null;
  bool get isPasswordMatch => confirmPasswordController.text.isNotEmpty && _confirmPasswordError == null;
  bool get canSignUp => isValidEmail && isValidPassword && isPasswordMatch;

  // Getters
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose(); // Don't forget this!
    nameController.dispose();
    super.dispose();
  }
}


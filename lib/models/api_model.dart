import 'package:project/models/task_model.dart';

class ApiModel{
  static const String status = '/status';
  static const String authRegister = '/auth/register';
  static const String authAuthenticate = '/auth/login';
  static const String authTest = '/v1/auth/test';
  static const String tasks = '/tasks';
  static const String users = '/users';
  static const int timeoutInSec = 60;
}

class PriorityMapping {
  static String toApiString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'MEDIUM';
      case Priority.high:
        return 'HIGH';
    }
  }

  static Priority fromApiString(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return Priority.low;
      case 'MEDIUM':
        return Priority.medium;
      case 'HIGH':
        return Priority.high;
      default:
        return Priority.low;
    }
  }
}
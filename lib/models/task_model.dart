import 'package:project/models/user_model.dart';

enum Priority { low, medium, high }

class Task {
  final int? id;
  final int ownerId;
  late final String title;
  String description;
  Priority priority;
  bool isCompleted = false;
  User? assignedId;
  DateTime dueDate, updatedAt;
  late final DateTime createdAt;
  Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.ownerId,
    this.assignedId,
    required this.isCompleted,
    required this.updatedAt,
    required this.createdAt,
  });

  // Factory method to create Task from API JSON response
  factory Task.fromApiJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: _priorityFromString(json['priority']),
      isCompleted: json['isCompleted'] ?? false,
      dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate'] * 1000), // API returns seconds, convert to milliseconds
      ownerId: json['ownerId'],
      assignedId: json['assignedId'] != null
          ? User(id: json['assignedId'], username: 'Loading...', email: '')
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['lastUpdate'] * 1000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['dueDate'] * 1000), // Use dueDate as fallback for createdAt
    );
  }

  // Convert Task to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': _priorityToString(priority),
      'dueDate': (dueDate.millisecondsSinceEpoch / 1000).round(),
      'assigneeId': assignedId?.id,
    };
  }

  static String _priorityToString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'NORMAL';
      case Priority.high:
        return 'HIGH';
    }
  }
  static Priority _priorityFromString(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return Priority.low;
      case 'NORMAL':
      case 'MEDIUM':
        return Priority.medium;
      case 'HIGH':
        return Priority.high;
      default:
        return Priority.low;
    }
  }

  void setAssignedId(User? user)=>assignedId = user;
  void setCompleted(bool value)=>isCompleted = value;
  set setDescription(String desc) => description = desc;
  set setPriority(Priority newPriority) => priority = newPriority;
  set setDueDate(DateTime newDueDate) => dueDate = newDueDate;
  String get getTitle => title;
  String get getDescription => description;
  int get getOwnerId => ownerId;
  int get getId => id!;
  DateTime get getDueDate => dueDate;
}

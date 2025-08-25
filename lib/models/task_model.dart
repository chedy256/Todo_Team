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

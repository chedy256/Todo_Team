enum Priority { low, medium, high }

class Task {
  final int id,ownerId;
  final String title;
  String description;
  Priority priority;
  bool isCompleted = false;
  int? assignedId;
  DateTime dueDate, updatedAt;
  late final DateTime createdAt;
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isCompleted,
    required this.dueDate,
    required this.ownerId,
    this.assignedId,
    required this.updatedAt,
    required this.createdAt,
  });
  void setAssignedId(int? id)=>assignedId = id;
  void setCompleted(bool value)=>isCompleted = value;
  set setDescription(String desc) => description = desc;
}

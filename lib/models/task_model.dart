class Task {
  final int id;
  final String title;
  final String? description;
  final int priority;
  //will be changed if it becomes status
  bool completed=false;
  int? assignedTo;
  late DateTime dueDate, updatedAt;
  late final DateTime createdAt;
  Task({required this.id, required this.title, this.description,required this.priority});
}

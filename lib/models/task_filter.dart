// Enums and models for task filtering and sorting

enum TaskStatus {
  all('Tous'),
  pending('En Attente'),
  inProgress('En Cours'),
  completed('Terminées');

  const TaskStatus(this.displayName);
  final String displayName;
}

enum SortType {
  createdDate('Date de création'),
  dueDate('Date d\'échéance'),
  priority('Priorité');

  const SortType(this.displayName);
  final String displayName;
}

class TaskFilterSettings {
  final TaskStatus status;
  final SortType sortType;

  const TaskFilterSettings({
    this.status = TaskStatus.all,
    this.sortType = SortType.priority,
  });

  TaskFilterSettings copyWith({TaskStatus? status, SortType? sortType}) {
    return TaskFilterSettings(
      status: status ?? this.status,
      sortType: sortType ?? this.sortType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilterSettings &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          sortType == other.sortType;

  @override
  int get hashCode => status.hashCode ^ sortType.hashCode;
}

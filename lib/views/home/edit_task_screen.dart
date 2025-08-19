import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/views/widgets/task_form_widget.dart';

class EditTaskScreen extends StatelessWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final databaseService = LocalDatabaseService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la tâche')),
      body: TaskFormWidget(
        initialTask: task,
        submitButtonText: 'Mettre à jour',
        onSubmit: (updatedTask) async {
          await databaseService.updateTask(updatedTask);
          if(context.mounted)Navigator.pop(context, true);
        },
      ),
    );
  }
}

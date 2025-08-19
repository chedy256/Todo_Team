import 'package:flutter/material.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/notif_service.dart';
import 'package:project/views/widgets/task_form_widget.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = LocalDatabaseService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une tâche')),
      body: TaskFormWidget(
        submitButtonText: 'Ajouter la tâche',
        onSubmit: (task) async {
          final taskId = await databaseService.addTask(task);
          NotifService().dueTaskNotification(task.dueDate, taskId, task.title);
          if(context.mounted) Navigator.pop(context, true);
        },
      ),
    );
  }
}

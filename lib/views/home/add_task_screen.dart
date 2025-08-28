import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/controllers/task_provider.dart';
import 'package:project/services/notif_service.dart';
import 'package:project/views/widgets/task_form_widget.dart';
//import '../../services/local_database_service.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //final databaseService = LocalDatabaseService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une tâche')),
      body: TaskFormWidget(
        submitButtonText: 'Ajouter la tâche',
        onSubmit: (task) async {
          await context.read<TaskProvider>().createTask(task);
          NotifService().dueTaskNotification(
            task.dueDate,
            task.id!,
            task.title,
          );

          if (context.mounted) Navigator.pop(context, true);
        },
      ),
    );
  }
}

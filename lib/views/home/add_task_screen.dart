import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/controllers/task_provider.dart';
import 'package:project/views/widgets/task_form_widget.dart';

import '../../controllers/user_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Set context for providers to show SnackBar messages
      context.read<TaskProvider>().setContext(context);
      context.read<UserProvider>().setContext(context);
      
      // Load users using the provider from the widget tree
      await context.read<UserProvider>().loadUsers(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une tâche')),
      body: TaskFormWidget(
        submitButtonText: 'Ajouter la tâche',
        onSubmit: (task) async {
          context.read<TaskProvider>().createTask(task);
          if (context.mounted) Navigator.pop(context, true);
        },
      ),
    );
  }
}

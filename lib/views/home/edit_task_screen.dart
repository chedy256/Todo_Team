import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/controllers/task_provider.dart';
import 'package:project/models/task_model.dart';
import 'package:project/views/widgets/task_form_widget.dart';
import 'package:project/services/notif_service.dart';
import 'package:project/utils/utils.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set context for TaskProvider to show SnackBar messages
      context.read<TaskProvider>().setContext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la tâche')),
      body: TaskFormWidget(
        initialTask: widget.task,
        submitButtonText: 'Mettre à jour',
        onSubmit: (updatedTask) async {
          // Check if due date has changed
          bool dueDateChanged = widget.task.dueDate != updatedTask.dueDate;

          if (dueDateChanged) {
            // Cancel the old notification first
            await NotifService().cancelNotification(widget.task.getId);
            // Schedule new notification with updated due date
            await NotifService().dueTaskNotification(
              updatedTask.dueDate,
              updatedTask.getId,
              updatedTask.title,
            );
          }

          if (context.mounted) {
            // Close the edit screen immediately for better UX
            Navigator.pop(context, true);

            // Get the TaskProvider and trigger update in background
            final taskProvider = context.read<TaskProvider>();

            // Trigger the update without waiting (fire and forget)
            taskProvider.updateTask(updatedTask).then((_) {
              // Check if update was successful after completion
              if (taskProvider.error == null) {
                // Success: Refresh the task list to show updated data
                taskProvider.refreshTasks();
                if (context.mounted) {
                  Utils.showSuccessSnackBar(context, 'Tâche mise à jour avec succès');
                }
              } else {
                // Error will be shown via the TaskProvider's SnackBar utility
                // Retry option for critical errors
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la mise à jour'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          // Retry the update
                          taskProvider.updateTask(updatedTask);
                        },
                      ),
                    ),
                  );
                }
              }
            });
          }
        },
      ),
    );
  }
}

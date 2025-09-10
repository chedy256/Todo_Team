import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';
import 'package:provider/provider.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/controllers/task_provider.dart';
import 'package:project/controllers/user_provider.dart';
import 'package:project/models/task_filter.dart';

import '../widgets/item_widget.dart';
import '../widgets/connectivity_status_widget.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<StatefulWidget> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final AuthController _authController = AuthController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set context for providers to show SnackBar messages
      context.read<TaskProvider>().setContext(context);
      context.read<UserProvider>().setContext(context);

      // Load both users and tasks when the screen initializes
      context.read<UserProvider>().loadUsers();
      context.read<TaskProvider>().loadTasks();

      // Start periodic refresh every 5 minutes
      context.read<TaskProvider>().startPeriodicRefresh();
    });
  }

  @override
  void dispose() {
    // Stop periodic refresh when screen is disposed
    context.read<TaskProvider>().stopPeriodicRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(254, 247, 255, 1),
        title: Text('ToDo Team', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          padding: EdgeInsets.all(5),
          onPressed: () async {
            if (await DialogService.showConfirmationDialog(
                  context,
                  "Se Déconnecter",
                  "Etes-vous sur de vous déconnecter ?",
                ) &&
                context.mounted) {
              _authController.logout(context);
            }
          },
          icon: Icon(Icons.logout_outlined, color: Colors.black),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
          ),
        ),
        actions: [const ConnectivityStatusWidget()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildFilterButtons()],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _buildTasksList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_task');
          if (result == true && context.mounted) {
            context.read<TaskProvider>().refreshTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final currentStatus = taskProvider.filterSettings.status;

        return Row(
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Row(
                children: TaskStatus.values.map((status) {
                  final isSelected = currentStatus == status;
                  return TextButton(
                    onPressed: () => _onFilterSelected(status),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.deepPurple.shade100
                          : Colors.transparent,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasksList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Handle error state
        if (taskProvider.error != null) {
          return _buildErrorState(taskProvider.error!);
        }

        // Handle initial loading state
        if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle empty state
        if (taskProvider.tasks.isEmpty && !taskProvider.isLoading) {
          return _buildEmptyState(taskProvider.filterSettings.status);
        }

        // Build the tasks list
        return RefreshIndicator(
          onRefresh: () async => taskProvider.refreshTasks(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: taskProvider.tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return ItemWidget(
                task: task,
                onTaskChanged: () => _refreshTasksList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskProvider>().clearError();
        await context.read<TaskProvider>().refreshTasks();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<TaskProvider>().clearError();
                  context.read<TaskProvider>().refreshTasks();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TaskStatus status) {
    String message;
    IconData icon;

    switch (status) {
      case TaskStatus.all:
        message = 'Aucune tâche trouvée.';
        icon = Icons.task_alt;
        break;
      case TaskStatus.pending:
        message = 'Aucune tâche en attente.';
        icon = Icons.pending_actions;
        break;
      case TaskStatus.inProgress:
        message = 'Aucune tâche en cours.';
        icon = Icons.work_outline;
        break;
      case TaskStatus.completed:
        message = 'Aucune tâche terminée.';
        icon = Icons.check_circle_outline;
        break;
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<TaskProvider>().refreshTasks(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _onFilterSelected(TaskStatus status) {
    context.read<TaskProvider>().filterTasks(status);
  }

  void _refreshTasksList() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.refreshTasks();
  }
}

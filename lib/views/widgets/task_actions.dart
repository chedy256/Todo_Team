import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';
import 'package:project/services/online_service.dart';
import 'package:project/utils/utils.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_model.dart';
import '../../services/local_database_service.dart';
import '../../services/notif_service.dart';
import '../home/edit_task_screen.dart';

class TaskActions extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChanged;
  final VoidCallback? onTaskDeleted;
  static bool isBottomSheetOpen = false;

  const TaskActions({
    super.key,
    required this.task,
    this.onTaskChanged,
    this.onTaskDeleted,
  });

  @override
  State<TaskActions> createState() => _TaskActionsState();
}

class _TaskActionsState extends State<TaskActions> {
  final LocalDatabaseService databaseService = LocalDatabaseService.instance;
  void _handleTaskChange() {
    if (mounted) {
      widget.onTaskChanged?.call(); // This will refresh the parent task list
      Navigator.pop(context);
    }
  }

  void _handleTaskDelete() async {
    final result = await ApiService.deleteTask(widget.task.getId);

    if (result.isSuccess) {
      // Cancel the notification for this task
      await NotifService().cancelNotification(widget.task.getId);

      if (mounted) {
        widget.onTaskDeleted?.call(); // This will refresh the entire task list
        Navigator.pop(context);
        Utils.showSuccessSnackBar(context, 'Tâche supprimée avec succès');
      }
    } else {
      // Show error in SnackBar if deletion failed (except authentication errors)
      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet first
        Utils.showErrorSnackBar(
          context,
          result.errorMessage ?? 'Erreur lors de la suppression de la tâche',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => {
              TaskActions.isBottomSheetOpen = false,
              Navigator.of(context).pop(),
            },
            icon: const Icon(Icons.close, size: 30),
          ),
          (AuthController.currentUser!.id == widget.task.ownerId)
              ? (widget.task.assignedId == null || widget.task.isCompleted)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            child: SizedBox(
                              width: 150,
                              height: 70,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  spacing: 10,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                    const Text("Supprimer"),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () async {
                              if (await DialogService.showConfirmationDialog(
                                context,
                                "Confirmation",
                                'êtes-vous sûr de vouloir supprimer cette tâche ?',
                              )) {
                                TaskActions.isBottomSheetOpen = false;
                                _handleTaskDelete(); // Use delete handler for list refresh
                              } else {
                                return;
                              }
                            },
                          ),
                          InkWell(
                            child: SizedBox(
                              width: 150,
                              height: 70,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  spacing: 10,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                    const Text("Modifier"),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () async {
                              TaskActions.isBottomSheetOpen = false;
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditTaskScreen(task: widget.task),
                                ),
                              );
                              if (result == true) {
                                // For task edits, we need to refresh the parent list to get updated task data
                                widget.onTaskChanged?.call();
                              }
                            },
                          ),
                        ],
                      )
                    : InkWell(
                        child: SizedBox(
                          width: 150,
                          height: 70,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                const Text("Modifier"),
                              ],
                            ),
                          ),
                        ),
                        onTap: () async {
                          TaskActions.isBottomSheetOpen = false;
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditTaskScreen(task: widget.task),
                            ),
                          );
                          if (result == true) {
                            // For task edits, we need to refresh the parent list to get updated task data
                            widget.onTaskChanged?.call();
                          }
                        },
                      )
              : const SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              !widget.task.isCompleted && widget.task.assignedId != null
                  ? InkWell(
                      child: SizedBox(
                        width: 150,
                        height: 70,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 30,
                              ),
                              Text("Terminée"),
                            ],
                          ),
                        ),
                      ),
                      onTap: () async {
                        widget.task.setCompleted(true);
                        widget.task.updatedAt = DateTime.now();
                        databaseService.updateTask(widget.task);

                        final result = await ApiService.updateTask(widget.task);
                        if (!result.isSuccess && context.mounted) {
                          Utils.showErrorSnackBar(
                            context,
                            result.errorMessage ?? 'Erreur lors de la mise à jour de la tâche',
                          );
                        }
                        _handleTaskChange();
                      },
                    )
                  : InkWell(
                      child: SizedBox(
                        width: 150,
                        height: 70,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_box_outlined,
                                color: Colors.cyan,
                                size: 30,
                              ),
                              Text(
                                "Prendre \nen charge",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () async {
                        widget.task.setAssignedId(AuthController.currentUser);
                        widget.task.updatedAt = DateTime.now();
                        databaseService.updateTask(widget.task);

                        final result = await ApiService.updateTask(widget.task);
                        if (!result.isSuccess && context.mounted) {
                          Utils.showErrorSnackBar(
                            context,
                            result.errorMessage ?? 'Erreur lors de la mise à jour de la tâche',
                          );
                        }
                        _handleTaskChange();
                      },
                    ),
              InkWell(
                child: SizedBox(
                  width: 150,
                  height: 70,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 30),
                        Text("Description", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                onTap: () => DialogService.showInfoDialog(
                  context,
                  'Description',
                  widget.task.description,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

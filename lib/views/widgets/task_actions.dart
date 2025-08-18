import 'package:flutter/material.dart';
import 'package:project/services/dialogs_service.dart';

import '../../controllers/auth_controller.dart';
import '../../models/task_model.dart';
import '../../services/local_database_service.dart';
import '../home/edit_task_screen.dart';

class TaskActions extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChanged;
  static bool isBottomSheetOpen = false;

  const TaskActions({super.key, required this.task, this.onTaskChanged});

  @override
  State<TaskActions> createState() => _TaskActionsState();
}

class _TaskActionsState extends State<TaskActions> {
  final LocalDatabaseService databaseService = LocalDatabaseService.instance;
  void _handleTaskChange() {
    widget.onTaskChanged
        ?.call(); // This will trigger timer restart in ItemWidget
    Navigator.pop(context);
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
                          databaseService.deleteTask(widget.task.getId);
                          _handleTaskChange();
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditTaskScreen(task: widget.task),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              widget.task.isCompleted
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
                                Icons.cancel_outlined,
                                color: Colors.orange,
                                size: 30,
                              ),
                              Text("Non terminée", textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        widget.task.setCompleted(false);
                        databaseService.updateTask(widget.task);
                        _handleTaskChange();
                      },
                    )
                  : widget.task.assigned != null
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
                      onTap: () {
                        widget.task.setCompleted(true);
                        databaseService.updateTask(widget.task);
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
                      onTap: () {
                        widget.task.setAssignedId(AuthController.currentUser);
                        databaseService.updateTask(widget.task);
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

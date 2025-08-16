import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:project/views/widgets/dialogs.dart';

import '../../models/task_model.dart';

class TaskActions extends StatelessWidget {
  final Task task;
  static bool isBottomSheetOpen = false;
  const TaskActions({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    isBottomSheetOpen = true;
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => {
              isBottomSheetOpen = false,
              Navigator.of(context).pop(),
            },
            icon: const Icon(Icons.close, size: 30),
          ),
          (currentUser?.id == task.ownerId)
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
                      onTap: () {},
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
                      onTap: () {},
                    ),
                  ],
                )
              : const SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              task.isCompleted
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
                      onTap: () =>{
                        task.setCompleted(false),
                        Navigator.pop(context)
                      },
                    )
                  : task.assignedId != null
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
                      onTap: () =>{
                        task.setCompleted(true),
                        Navigator.pop(context)
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
                      onTap: () => {
                        task.setAssignedId(currentUser?.id),
                        Navigator.pop(context)
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
                  task.description,
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

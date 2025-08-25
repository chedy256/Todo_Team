import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/models/task_model.dart';
import 'package:project/utils/utils.dart';
import 'package:project/views/widgets/task_actions.dart';
import 'package:project/controllers/task_provider.dart';

import '../../controllers/auth_controller.dart';

class ItemWidget extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChanged;
  const ItemWidget({super.key, required this.task, this.onTaskChanged});
  @override
  createState() => _ItemWidgetState();

}
class _ItemWidgetState extends State<ItemWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel existing timer
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {}); // Update the time display every minute
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Card(
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: (widget.task.title.length/49) *20+70,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.task.title,
              style: TextStyle(color: Colors.black87,fontWeight: FontWeight.w500,
                decoration: (widget.task.isCompleted) ? TextDecoration.lineThrough : null,
              ),
            ),
            Row(
              spacing: 10,
              children: [
                (widget.task.assignedId == null)
                    ? Icon(Icons.circle_outlined, color: Colors.black,size: 22,)
                    : Icon(
                  Icons.circle,size: 22,
                  color: (widget.task.isCompleted)
                      ? Colors.green
                      : (widget.task.assignedId?.getId == AuthController.currentUser?.getId)
                      ? Colors.blueAccent
                      : Colors.blueGrey
                ),
                Container(
                  height: 23,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  decoration:   BoxDecoration(
                    color: (widget.task.priority==Priority.low)?Colors.white:(widget.task.priority==Priority.medium)?Colors.amberAccent.shade100:Colors.redAccent.shade100, // background
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Utils.timeLeft(widget.task.dueDate),
                    style:const TextStyle(color: Colors.black, fontSize: 14,fontWeight:FontWeight.w400  ),
                  ),
                ),
              ],
            ),
          ],
        ),),
      ),
      ),
      onTap: () async {
        TaskActions.isBottomSheetOpen = true;
      showBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade200,
      builder: (BuildContext context) {
        return TaskActions(
          task: widget.task,
          onTaskChanged: () {
            if (mounted) {
              context.read<TaskProvider>().refreshTasks();
              widget.onTaskChanged?.call();
            }
          },
          onTaskDeleted: () {
            if (mounted) {
              context.read<TaskProvider>().refreshTasks();
              widget.onTaskChanged?.call();
            }
          },
        );
      },
    );
    TaskActions.isBottomSheetOpen = false;
      }
    );
  }
}

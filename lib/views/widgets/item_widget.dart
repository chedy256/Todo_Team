import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';
import 'package:project/utils/utils.dart';
import 'package:project/views/widgets/task_actions.dart';

import '../../controllers/auth_controller.dart';

class ItemWidget extends StatefulWidget {
  final Task task;
  const ItemWidget({super.key, required this.task});
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

    final duration = Duration(minutes: 1);
    _timer = Timer.periodic(duration, (timer) {
      if (mounted) {
        setState(() {});
        // Restart timer with new interval if time unit changed
        final currentInterval = Duration(minutes: 1);
        if (_timer != null && _shouldRestartTimer(currentInterval)) {
          _startTimer();
        }
      }
    });
  }

  bool _shouldRestartTimer(Duration newInterval) {
    final now = DateTime.now();
    final difference = widget.task.dueDate.difference(now);

    // Check if we've crossed a time boundary
    if (difference.inDays == 0 && newInterval != const Duration(minutes: 1)) {
      return true; // Switched from days to hours
    }
    if (difference.inHours == 0 && newInterval != const Duration(seconds: 30)) {
      return true; // Switched from hours to minutes
    }
    return false;
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
              style: TextStyle(color: Colors.black87,
                decoration: (widget.task.isCompleted) ? TextDecoration.lineThrough : null,
              ),
            ),
            Row(
              spacing: 10,
              children: [
                (widget.task.assigned == null)
                    ? Icon(Icons.circle_outlined, color: Colors.black)
                    : Icon(
                  Icons.circle,
                  color: (widget.task.isCompleted)
                      ? Colors.green
                      : (widget.task.assigned == AuthController.currentUser)
                      ? Colors.red
                      : Colors.blue,
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
                    style:const TextStyle(color: Colors.black, fontSize: 14 ),
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
              setState(() {}); // This will trigger timer restart
              _startTimer(); // Restart timer with new interval
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

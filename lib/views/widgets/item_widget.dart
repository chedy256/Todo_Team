import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';
import 'package:project/utils/utils.dart';
import 'package:project/views/widgets/task_actions.dart';

import '../../main.dart';

class ItemWidget extends StatefulWidget {
  final Task task;
  const ItemWidget({super.key, required this.task});
  @override
  createState() => _ItemWidgetState();

}
class _ItemWidgetState extends State<ItemWidget> {
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
                (widget.task.assignedId == null)
                    ? Icon(Icons.circle_outlined, color: Colors.black)
                    : Icon(
                  Icons.circle,
                  color: (widget.task.isCompleted)
                      ? Colors.green
                      : (widget.task.assignedId == currentUser!.id)
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
      onTap: ()=> {
        TaskActions.isBottomSheetOpen = true,
        showBottomSheet(context: context,backgroundColor: Colors.grey.shade200, builder: (BuildContext context){ return TaskActions(task: widget.task);})
      }
    );
  }
}

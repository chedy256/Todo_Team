import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';

import '../../controllers/auth_controller.dart';
import '../../main.dart';
import '../../services/local_database_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});
  @override
  State<StatefulWidget> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final LocalDatabaseService databaseService = LocalDatabaseService.instance;
  final TextEditingController _descriptionController = TextEditingController(),
      _dateController = TextEditingController(),
      _timeController = TextEditingController(),
      _assignedController = TextEditingController();

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;

  @override
  void dispose() {
    _timeController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Task task = widget.task;
    Priority priority = task.priority;
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la tâche')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: task.getTitle,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: task.getDescription ,
                  alignLabelWithHint: true, // keeps label aligned at top
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Priorité:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Basse'),
                    selected: priority == Priority.low,
                    selectedColor: Colors.green.shade200,
                    onSelected: (_) {
                      setState(() {
                        priority = Priority.low;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Moyenne'),
                    selected: priority == Priority.medium,
                    selectedColor: Colors.orange.shade300,
                    onSelected: (_) {
                      setState(() {
                        priority = Priority.medium;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Haute'),
                    selected: priority == Priority.high,
                    selectedColor: Colors.red.shade400,
                    onSelected: (_) {
                      setState(() {
                        priority = Priority.high;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Assigner à",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _assignedController,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: "Selectionnez la personne",
                  hintText: task.assigned != null ? task.assigned?.name : 'personne',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  final result = await showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(),
                  );

                  if (result != null) {
                    _assignedController.text = result;
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Date d'échéance",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      _pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (_pickedDate != null) {
                        setState(() {
                          _dateController.text =
                              "${_pickedDate!.day.toString().padLeft(2, '0')}/${_pickedDate!.month.toString().padLeft(2, '0')}/${_pickedDate!.year}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: '${task.dueDate.hour}:${task.dueDate.minute}',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      _pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (_pickedTime != null) {
                        setState(() {
                          _timeController.text =
                              "${_pickedTime!.hour.toString().padLeft(2, '0')}:${_pickedTime!.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  DateTime originalDueDate = task.dueDate;

                  // Create new due date using picked values or original values
                  final dueDate = DateTime(
                    _pickedDate?.year ?? originalDueDate.year,
                    _pickedDate?.month ?? originalDueDate.month,
                    _pickedDate?.day ?? originalDueDate.day,
                    _pickedTime?.hour ?? originalDueDate.hour,
                    _pickedTime?.minute ?? originalDueDate.minute,
                  );

                  // Only update due date if it's different from original
                  if (dueDate != originalDueDate) {
                    task.dueDate = dueDate;
                  }
                  task.priority = priority;
                  task.updatedAt = DateTime.now();

                  databaseService.updateTask(task);
                  Navigator.pop(context, true);
                },
                child: const Text('Changer la tâche'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  List<String> searchTerms = [
    'personne',
    'Moi même: ${AuthController.currentUser?.name}',
    'chedy',
    'admin',
    'yassine',
    'bilel',
    'mohamed',
  ];//TODO Refactor: will be replaced with user.name to access user.id
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, 'personne');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchingTerms = searchTerms
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: matchingTerms.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(matchingTerms[index]),
          onTap: () {
            close(context, matchingTerms[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchingTerms = searchTerms
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: matchingTerms.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(matchingTerms[index]),
          onTap: () {
            close(context, matchingTerms[index]);
          },
        );
      },
    );
  }
}

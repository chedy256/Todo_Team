import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';
import 'package:project/services/dialogs_service.dart';

import '../../main.dart';
import '../../services/local_database_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<StatefulWidget> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  Priority _priority = Priority.low;
  final TextEditingController _titleController = TextEditingController(),
      _descriptionController = TextEditingController(),
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
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalDatabaseService databaseService = LocalDatabaseService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Creer une tâche')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Titre',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: null, // grows with content
                minLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  alignLabelWithHint: true, // keeps label aligned at top
                  border: OutlineInputBorder(),
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
                    selected: _priority == Priority.low,
                    selectedColor: Colors.grey.shade300,
                    onSelected: (_) {
                      setState(() {
                        _priority = Priority.low;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Moyenne'),
                    selected: _priority == Priority.medium,
                    selectedColor: Colors.orange.shade200,
                    onSelected: (_) {
                      setState(() {
                        _priority = Priority.medium;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Haute'),
                    selected: _priority == Priority.high,
                    selectedColor: Colors.red.shade400,
                    onSelected: (_) {
                      setState(() {
                        _priority = Priority.high;
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
                      labelText: "Selectionnez la date",
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _pickedDate = pickedDate;
                          _dateController.text =
                              "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
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
                      labelText: "Selectionnez l'heure",
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _pickedTime = pickedTime;
                          _timeController.text =
                              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if(_titleController.text.isEmpty){
                    DialogService.showErrorDialog(
                      context,
                      "Le titre est obligatoire.",
                    );
                  }
                  else if (_pickedDate == null || _pickedTime == null) {
                    DialogService.showErrorDialog(
                      context,
                      "Veuillez sélectionner une date et une heure valides.",
                    );
                  } else {
                    final dueDate = DateTime(
                      _pickedDate!.year,
                      _pickedDate!.month,
                      _pickedDate!.day,
                      _pickedTime!.hour,
                      _pickedTime!.minute,
                    );
                    databaseService.addTask(
                      Task(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        priority: _priority,
                        dueDate: dueDate,
                        ownerId: currentUser!.getId,
                        isCompleted: false,
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Ajouter la tâche'),
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
    'Moi même: ${currentUser?.name}',
    'chedy',
    'admin',
    'yassine',
    'bilel',
    'mohamed',
  ]; //will be replaced with user.name to access user.id
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

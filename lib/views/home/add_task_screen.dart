import 'package:flutter/material.dart';
import 'package:project/models/task_model.dart';

import '../../main.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<StatefulWidget> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  Priority? _priority = Priority.low;
  final TextEditingController _titleController = TextEditingController(),
      _descriptionController = TextEditingController(),
      _dateController = TextEditingController(),
      _timeController = TextEditingController(),
      _assignedController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _priority = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                minLines: 5, // minimum height
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
                    borderRadius: BorderRadius.circular(16), // can't be const
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
                      TimeOfDay? pickedDate = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _timeController.text =
                              "${pickedDate.hour.toString().padLeft(2, '0')}:${pickedDate.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Logic to add the task
                  Navigator.pop(context);
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
  ];//will be replaced with user.name to access user.id
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

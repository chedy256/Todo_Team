import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/models/task_model.dart';
import 'package:project/models/user_model.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/controllers/user_provider.dart';
import 'package:project/services/local_database_service.dart';

class TaskFormWidget extends StatefulWidget {
  final Task? initialTask;
  final Function(Task task) onSubmit;
  final String submitButtonText;

  const TaskFormWidget({
    super.key,
    this.initialTask,
    required this.onSubmit,
    required this.submitButtonText,
  });

  @override
  State<TaskFormWidget> createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  late Priority _priority;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _assignedController;

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  User? _assignedUser;
  List<User> _availableUsers = []; // Store users from database

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Defer the user loading until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    try {
      // Try to refresh users from API first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUsers();

      // Get the updated users from the provider
      _availableUsers = userProvider.users;

      if (mounted) setState(() {});
    } catch (e) {
      // If refresh fails, fallback to local database
      debugPrint('Failed to refresh users from API: $e');
      try {
        _availableUsers = await LocalDatabaseService.instance.getUsers();
        if (mounted) setState(() {});
      } catch (localError) {
        debugPrint('Failed to load users from local database: $localError');
        _availableUsers = []; // Empty list if all fails
        if (mounted) setState(() {});
      }
    }
  }

  void _initializeControllers() {
    final task = widget.initialTask;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _assignedController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();

    _priority = task?.priority ?? Priority.low;
    _assignedUser = task?.assignedId;

    if (_assignedUser != null) {
      // Show username (email) for other users, just username for current user
      if (_assignedUser?.id == AuthController.currentUser?.id) {
        _assignedController.text = _assignedUser!.username;
      } else {
        _assignedController.text = '${_assignedUser!.username} (${_assignedUser!.email})';
      }
    } else {
      _assignedController.text = "personne";
    }

    if (task?.dueDate != null) {
      _pickedDate = task!.dueDate;
      _pickedTime = TimeOfDay.fromDateTime(task.dueDate);
      _dateController.text = "${task.dueDate.day.toString().padLeft(2, '0')}/${task.dueDate.month.toString().padLeft(2, '0')}/${task.dueDate.year}";
      _timeController.text = "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildPrioritySection(),
            const SizedBox(height: 20),
            _buildAssignedSection(),
            const SizedBox(height: 20),
            _buildDateTimeSection(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Titre',
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: null,
      minLines: 5,
      decoration: const InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      children: [
        const Text(
          'Priorité:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _buildPriorityChip('Basse', Priority.low, Colors.grey.shade300),
            _buildPriorityChip('Moyenne', Priority.medium, Colors.orange.shade200),
            _buildPriorityChip('Haute', Priority.high, Colors.red.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String label, Priority priority, Color selectedColor) {
    return ChoiceChip(
      label: Text(label),
      selected: _priority == priority,
      selectedColor: selectedColor,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _priority = priority;
          });
        }
      },
    );
  }

  Widget _buildAssignedSection() {
    bool isTaskAlreadyAssigned = widget.initialTask?.assignedId != null;

    return Column(
      children: [
        const Text(
          "Assigner à",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _assignedController,
          readOnly: true,
          enabled: !isTaskAlreadyAssigned, // Disable if already assigned
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            labelText: isTaskAlreadyAssigned
                ? "Personne assignée"
                : "Selectionnez la personne",
            hintText: !isTaskAlreadyAssigned
                ? "Tapez pour sélectionner"
                : null,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          style: TextStyle(
            color: isTaskAlreadyAssigned ? Colors.grey.shade700 : Colors.black,
            fontWeight: isTaskAlreadyAssigned ? FontWeight.w500 : FontWeight.normal,
          ),
          onTap: isTaskAlreadyAssigned ? null : () async {
            final result = await showSearch(
              context: context,
              delegate: CustomSearchDelegate(_availableUsers),
            );
            if (result != null) {
              setState(() {
                if (result == 'personne') {
                  _assignedUser = null;
                  _assignedController.text = 'personne';
                } else {
                  // Extract username from "username (email)" format
                  final username = result.split(' (').first;
                  _assignedUser = _availableUsers.firstWhere(
                    (user) => user.username == username,
                    orElse: () => _availableUsers.isNotEmpty ? _availableUsers.first : User(id: 0, username: 'personne', email: ''),
                  );

                  if (_assignedUser?.id == AuthController.currentUser?.id) {
                    _assignedController.text = 'moi même: ${_assignedUser!.username}';
                  } else {
                    _assignedController.text = '${_assignedUser!.username} (${_assignedUser!.email})';
                  }
                }
              });
            }
          },
        ),
        if (isTaskAlreadyAssigned)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "Cette tâche est déjà assignée et ne peut pas être modifiée",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      children: [
        const Text(
          "Date d'échéance",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            labelText: "Selectionnez la date",
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: _selectDate,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _timeController,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            labelText: "Selectionnez l'heure",
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: _selectTime,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _handleSubmit,
      child: Text(widget.submitButtonText),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (pickedDate != null) {
      setState(() {
        _pickedDate = pickedDate;
        _dateController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _pickedTime = pickedTime;
        _timeController.text = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _handleSubmit() {
    if (_titleController.text.isEmpty) {
      _showErrorDialog("Le titre est obligatoire.");
      return;
    }
    if (_pickedDate == null || _pickedTime == null) {
      _showErrorDialog("Veuillez sélectionner une date et une heure valides.");
      return;
    }

    final dueDate = DateTime(
      _pickedDate!.year,
      _pickedDate!.month,
      _pickedDate!.day,
      _pickedTime!.hour,
      _pickedTime!.minute,
    );

    final task = Task(
      id: widget.initialTask?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _priority,
      dueDate: dueDate,
      ownerId: AuthController.currentUser!.getId,
      assignedId: _assignedUser, // Include the assigned user
      isCompleted: widget.initialTask?.isCompleted ?? false,
      updatedAt: DateTime.now(),
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(task);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final List<User> availableUsers;

  CustomSearchDelegate(this.availableUsers);

  List<String> get searchTerms {
    List<String> terms = ['personne'];

    // Add all users (including current user) with email format
    for (User user in availableUsers) {
      terms.add('${user.username} (${user.email})');
    }

    return terms;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, 'personne'),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final matchingTerms = searchTerms
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: matchingTerms.length,
      itemBuilder: (context, index) {
        final term = matchingTerms[index];
        return ListTile(
          title: Text(
            term,
            style: const TextStyle(fontSize: 16),
          ),
          leading: _buildLeadingIcon(term),
          onTap: () => close(context, term),
        );
      },
    );
  }

  Widget _buildLeadingIcon(String term) {
    if (term == 'personne') {
      return const Icon(Icons.person_off, color: Colors.grey);
    } else if (term.contains('(${AuthController.currentUser?.email})')) {
      return const Icon(Icons.person, color: Colors.blue);
    } else {
      return const Icon(Icons.person_outline, color: Colors.green);
    }
  }
}

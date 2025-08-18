import 'package:flutter/material.dart';
import 'package:project/controllers/auth_controller.dart';
//import 'package:project/main.dart';
//import 'package:project/models/user_model.dart';

import '../../services/local_database_service.dart';
import '../widgets/item_widget.dart';
//import '../../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<StatefulWidget> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final AuthController _authController = AuthController.instance;
  final LocalDatabaseService databaseService = LocalDatabaseService.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(254, 247, 255, 1),
        title: Text('ToDo Team', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          padding: EdgeInsets.all(5),
          onPressed: () => _authController.logout(context),
          icon: Icon(Icons.logout_outlined, color: Colors.black),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
          ),
        ),
        actions: [
          //depending on the connection state
          /*
          const Text('Hors ligne',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(width: 12),
          const Icon(Icons.offline_pin_outlined,
              color: Colors.red, size: 20),
          */
          const Text(
            'En ligne',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.wifi, color: Colors.green, size: 20),
          const SizedBox(width: 18),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.purple.withOpacity(
                                0.5,
                              ), // Set background color here
                            ),
                            child: const Text(
                              'Tous',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'En Attente',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'En Cours',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Terminées',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list, size: 26),),//TODO: add filter
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            SizedBox(height: 5),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _tasksList()
                /*Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    ItemWidget(
                      task: Task(
                        title: 'tâche : terminée et non créée par lui',
                        assigned: currentUser,
                        isCompleted: true,
                        ownerId: 123,
                        description:
                            "description de la tâche : terminée et non créée par lui",
                        priority: Priority.high,
                        dueDate: DateTime.now().add(const Duration(days: 3)),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    ItemWidget(
                      task: Task(
                        title: "tâche : terminée et créée par lui",
                        assigned: currentUser,
                        isCompleted: true,
                        description: "description de la tâche",
                        ownerId: currentUser!.id,
                        priority: Priority.high,
                        dueDate: DateTime.now().add(const Duration(days: 3)),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    ItemWidget(
                      task: Task(
                        title:
                            "tâche : non terminée et assignée qlq d'autre dont il est le owner",
                        assigned: User( id: 10,name: 'name', email: 'email'),
                        isCompleted: false,
                        description: "description de la tâche",
                        ownerId: currentUser!.id,
                        priority: Priority.medium,
                        dueDate: DateTime.now().add(const Duration(hours: 3)),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    ItemWidget(
                      task: Task(
                        title: "tâche : non terminée et assignée à lui même",
                        assigned: currentUser,
                        isCompleted: false,
                        description: '',
                        ownerId: currentUser!.id,
                        priority: Priority.low,
                        dueDate: DateTime.now().add(const Duration(minutes: 3)),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    ItemWidget(
                      task: Task(
                        title: "tâche : non terminée et assignée à lui (crée par qlq'un d'autre)",
                        assigned: currentUser,
                        isCompleted: false,
                        description: '',
                        ownerId:  124,
                        priority: Priority.low,
                        dueDate: DateTime.now().add(const Duration(minutes: 3)),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    ItemWidget(
                      task: Task(
                        title: "tâche : non terminée et non assignée",
                        assigned: null,
                        isCompleted: false,
                        description: 'description de la tâche',
                        ownerId: currentUser!.id,
                        priority: Priority.low,
                        dueDate: DateTime.now(),
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),*/
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_task'),
        child: const Icon(Icons.add),
      ),
    );
  }
  Widget _tasksList () {
     return FutureBuilder(
      future: databaseService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune tâche trouvée.'));
        } else {
          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return ItemWidget(task: tasks[index]);
            },
          );
        }
      },
    );
  }
}

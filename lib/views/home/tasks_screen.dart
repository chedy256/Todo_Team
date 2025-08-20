import 'package:flutter/material.dart';
import 'package:project/controllers/auth_controller.dart';

import '../../services/local_database_service.dart';
import '../widgets/item_widget.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<StatefulWidget> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final AuthController _authController = AuthController.instance;
  final LocalDatabaseService databaseService = LocalDatabaseService.instance;
  
  UniqueKey _futureBuilderKey = UniqueKey();

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 5),
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
                              backgroundColor: Colors.purple.shade200,
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
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _tasksList()
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_task');
          if (result == true) {
            // Refresh the tasks list
            _refreshTasksList();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tasksList () {
     return FutureBuilder(
      key: _futureBuilderKey,
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
              return ItemWidget(
                task: tasks[index],
                onTaskChanged: _refreshTasksList,
              );
            },
          );
        }
      },
    );
  }
  
  void _refreshTasksList() {
    setState(() {
      _futureBuilderKey = UniqueKey();
    });
  }
}

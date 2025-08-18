import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/models/current_user.dart';

import 'package:project/views/auth/login_screen.dart';
import 'package:project/views/auth/sign_up_screen.dart';
import 'package:project/views/home/add_task_screen.dart';
import 'package:project/views/home/tasks_screen.dart';

CurrentUser? currentUser;//= CurrentUser(id: 123, name: "name", email: "email", token: 122); //remove this line before commiting

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo Team',
      initialRoute: AuthController.isLoggedIn ? '/tasks':'/login', //remove ! before commiting
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/add_task': (context) => const AddTaskScreen(),
      },
    );
  }
}
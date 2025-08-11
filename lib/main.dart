import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/models/current_user.dart';

import 'package:project/views/auth/email_screen.dart';
import 'package:project/views/auth/login_screen.dart';
import 'package:project/views/auth/sign_up_screen.dart';
import 'package:project/views/home/tasks_screen.dart';

late final CurrentUser currentUser;
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
      initialRoute: AuthController.isLoggedIn ? '/tasks':'/email',
      routes: {
        '/email': (context) => const EmailScreen(),
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/tasks': (context) => const TasksScreen(),
      },
    );
  }
}
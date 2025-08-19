import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/services/notif_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:project/controllers/auth_controller.dart';
import 'package:project/services/secure_storage.dart';
import 'package:project/views/auth/login_screen.dart';
import 'package:project/views/auth/sign_up_screen.dart';
import 'package:project/views/home/add_task_screen.dart';
import 'package:project/views/home/tasks_screen.dart';

final SecureStorage secureStorage = SecureStorage.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
  await NotifService().initNotification();
  final currentUser = await SecureStorage.instance.readCurrentUser();
  AuthController.currentUser=currentUser;
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
      initialRoute: AuthController.currentUser!=null
          ? '/tasks'
          : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/add_task': (context) => const AddTaskScreen(),
      },
    );
  }
}

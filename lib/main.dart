import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:project/services/notif_service.dart';
import 'package:project/controllers/task_provider.dart';
import 'package:project/controllers/user_provider.dart';
import 'package:project/controllers/auth_controller.dart';
import 'package:project/services/secure_storage.dart';
import 'package:project/views/auth/login_screen.dart';
import 'package:project/views/auth/sign_up_screen.dart';
import 'package:project/views/home/add_task_screen.dart';
import 'package:project/views/home/tasks_screen.dart';

import 'models/firebase_options.dart';

final SecureStorage secureStorage = SecureStorage.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotifService().initFCM();
  await NotifService().initNotification();
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ToDo Team',
        initialRoute: AuthController.currentUser!=null ? '/tasks' : '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/tasks': (context) => const TasksScreen(),
          '/add_task': (context) => const AddTaskScreen(),
        },
      ),
    );
  }
}

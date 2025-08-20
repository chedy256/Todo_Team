import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../utils/utils.dart';

class NotifService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //Initialize the notification service
  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initSettingsIOS =
        DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await notificationPlugin.initialize(initSettings);

    // Request notification permission on Android 13+
    final androidImplementation = notificationPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();

    // Request notification permission on iOS
    final iosImplementation = notificationPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
  }

  //Notif details
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'soon_task_id',
        'Soon Task',
        channelDescription: 'Tasks that are due soon',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }
    await notificationPlugin.show(id, title, body, notificationDetails());
  }
  //On notif tap

  //Schedule notification
  Future<void> dueTaskNotification(
    DateTime dueDate,
    int taskId,
    String taskTitle,
  ) async {
    if (!_isInitialized) {
      await initNotification();
      _isInitialized = true;
    }

    final diff = dueDate.difference(DateTime.now());

    if (diff.isNegative) {
      return;
    } else {
      if (diff.inHours < 24) {
        await showNotification(
          id: taskId,
          title: "Date Delai de la tâche s'approche",
          body:
              'La tâche "$taskTitle" se termine en ${Utils.timeLeft(dueDate)}',
        );
      } else {
        final scheduledTime = tz.TZDateTime.now(tz.local).add(
          Duration(
            hours: diff.inHours-24,
            minutes: diff.inMinutes % 60,
            seconds: 10,
          ),
        );
        await notificationPlugin.zonedSchedule(
          taskId,
          "Date Delai de la tâche s'approche",
          'La tâche "$taskTitle" se termine en ${Utils.timeLeft(dueDate)}',
          scheduledTime,
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  //Cancel notification
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) {
      await initNotification();
    }
    await notificationPlugin.cancel(id);
  }
  Future <void> cancelAllNotifications() async => await notificationPlugin.cancelAll();

}

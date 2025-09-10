import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
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
      // Task is already past due, no notification needed
      return;
    } else {
      if (diff.inHours < 24) {
        // Schedule notification to show immediately for tasks due within 24 hours
        final scheduledTime = tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 2), // Small delay to ensure proper scheduling
        );
        await notificationPlugin.zonedSchedule(
          taskId,
          "Date Delai de la tâche s'approche",
          'La tâche "$taskTitle" se termine en ${Utils.timeLeft(dueDate)}',
          scheduledTime,
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        // Schedule notification 24 hours before due date
        final scheduledTime = tz.TZDateTime.now(tz.local).add(
          Duration(
            hours: diff.inHours - 24,
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initFCM() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Get FCM token in background without blocking app launch
      _getFCMTokenWithTimeout();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Received a message while in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          await showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.notification!.title ?? 'New Message',
          body: message.notification!.body ?? 'You have a new message',
          );
        }
      });

      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Get FCM token with timeout and retry mechanism
  Future<void> _getFCMTokenWithTimeout() async {
    // Run in background without blocking
    Future.delayed(Duration.zero, () async {
      int maxRetries = 3;
      int retryCount = 0;

      while (retryCount < maxRetries && _fcmToken == null) {
        try {
          // Add timeout to prevent indefinite waiting
          final fcmToken = await _firebaseMessaging.getToken()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('FCM token request timed out');
                  return null;
                },
              );

          if (fcmToken != null) {
            _fcmToken = fcmToken;
            debugPrint('FCM Token: $fcmToken');
            // Token retrieved successfully, break the retry loop
            break;
          }
        } catch (e) {
          debugPrint('Error getting FCM token (attempt ${retryCount + 1}): $e');
        }

        retryCount++;
        if (retryCount < maxRetries) {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }

      if (_fcmToken == null) {
        debugPrint('Failed to get FCM token after $maxRetries attempts');
      }
    });
  }

  /// Manually retry getting FCM token when connection is restored
  Future<void> retryFCMToken() async {
    if (_fcmToken == null) {
      debugPrint('Retrying FCM token retrieval...');
      await _getFCMTokenWithTimeout();
    }
  }
}
Future <void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint(message.notification?.title);
}

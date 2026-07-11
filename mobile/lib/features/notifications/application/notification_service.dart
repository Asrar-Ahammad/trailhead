import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> scheduleStreakNudge(String message, DateTime scheduledTime) async {
    // Cancel any existing scheduled nudge (assuming ID 1 for streak nudges)
    await _flutterLocalNotificationsPlugin.cancel(id: 1);

    final androidDetails = const AndroidNotificationDetails(
      'trailhead_streak_nudge',
      'Streak Nudges',
      channelDescription: 'Reminders to keep your running streak alive',
      importance: Importance.high,
      priority: Priority.high,
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Trailhead',
      body: message,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

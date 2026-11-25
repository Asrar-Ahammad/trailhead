import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notifications_request_model_streak_nudge.dart';

class NotificationsStreakNudgeService {
  NotificationsStreakNudgeService(this._plugin);

  static const _streakNudgeId = 1;
  static const _settings = InitializationSettings(
    android: AndroidInitializationSettings('launcher_icon'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'trailhead_streak_nudge',
      'Streak Nudges',
      channelDescription: 'Reminders to keep your running streak alive',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  Future<void> initialize() =>
      _initialization ??= _initialize().onError<Object>((error, stackTrace) {
        _initialization = null;
        Error.throwWithStackTrace(error, stackTrace);
      });

  Future<void> _initialize() async {
    tz.initializeTimeZones();
    await _plugin.initialize(settings: _settings);
  }

  Future<void> schedule(StreakNudgeRequestModel request) async {
    await initialize();
    await _plugin.cancel(id: _streakNudgeId);
    await _plugin.zonedSchedule(
      id: _streakNudgeId,
      title: 'Trailhead',
      body: request.message,
      scheduledDate: tz.TZDateTime.from(request.scheduledTime, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

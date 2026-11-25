import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart';
import 'package:trailhead_mobile/features/notifications/data/notifications_repository_implementation_streak_nudge.dart';
import 'package:trailhead_mobile/features/notifications/data/notifications_service_streak_nudge.dart';

void main() {
  test(
    'Streak reminders initialize once and replace the same notification',
    () async {
      final plugin = _NotificationPlugin();
      final repository = NotificationsRepositoryImplementation(
        NotificationsStreakNudgeService(plugin),
      );
      final when = DateTime.utc(2026, 2, 3, 17);
      await Future.wait([repository.initialize(), repository.initialize()]);
      await repository.scheduleStreakNudge('Keep the streak', when);
      await repository.scheduleStreakNudge('Go for a run', when);
      expect(plugin.calls, [
        'initialize',
        'cancel:1',
        'schedule:1',
        'cancel:1',
        'schedule:1',
      ]);
      expect(plugin.body, 'Go for a run');
      expect(plugin.scheduledDate!.isAtSameMomentAs(when), isTrue);
    },
  );

  test(
    'Notification initialization retries after a plugin exception',
    () async {
      final plugin = _NotificationPlugin()..failNextInitialization = true;
      final service = NotificationsStreakNudgeService(plugin);
      await expectLater(service.initialize(), throwsStateError);
      await service.initialize();
      expect(plugin.calls, ['initialize', 'initialize']);
    },
  );
}

class _NotificationPlugin implements FlutterLocalNotificationsPlugin {
  final calls = <String>[];
  bool failNextInitialization = false;
  String? body;
  TZDateTime? scheduledDate;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add('initialize');
    if (failNextInitialization) {
      failNextInitialization = false;
      throw StateError('Plugin temporarily unavailable');
    }
    return true;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async =>
      calls.add('cancel:$id');

  @override
  Future<void> zonedSchedule({
    required int id,
    required TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    calls.add('schedule:$id');
    this.body = body;
    this.scheduledDate = scheduledDate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

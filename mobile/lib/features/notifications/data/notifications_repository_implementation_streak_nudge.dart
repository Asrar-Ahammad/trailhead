import '../domain/notifications_repository_streak_nudge.dart';
import 'notifications_request_model_streak_nudge.dart';
import 'notifications_service_streak_nudge.dart';

class NotificationsRepositoryImplementation implements NotificationsRepository {
  const NotificationsRepositoryImplementation(this._service);

  final NotificationsStreakNudgeService _service;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> scheduleStreakNudge(String message, DateTime scheduledTime) =>
      _service.schedule(StreakNudgeRequestModel(message, scheduledTime));
}

abstract interface class NotificationsRepository {
  Future<void> initialize();

  Future<void> scheduleStreakNudge(String message, DateTime scheduledTime);
}

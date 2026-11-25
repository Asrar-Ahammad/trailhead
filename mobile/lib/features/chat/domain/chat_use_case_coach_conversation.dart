import '../../run_tracking/application/run_format_utils.dart';
import 'chat_entity_coach_conversation.dart';
import 'chat_repository_coach_conversation.dart';

class ChatCoachConversation {
  const ChatCoachConversation(this._repository);

  final ChatRepository _repository;

  bool get isConfigured => _repository.isConfigured;

  Future<ChatMessage> buildContext({required bool useMiles}) async {
    final activities = await _repository.loadRecentActivities(limit: 10);
    const introduction =
        'You are a fitness coach for the Trailhead app. Keep responses concise and encouraging.';
    if (activities.isEmpty) {
      return (
        role: ChatRole.system,
        text:
            '$introduction Give general advice and encourage running or walking.',
      );
    }

    final prompt = StringBuffer(introduction)
      ..writeln()
      ..writeln('Use these recent activities to personalize your advice:');
    final unit = RunFormatUtils.getUnitString(useMiles);
    for (final activity in activities) {
      final date =
          activity.startTime?.toIso8601String().split('T').first ??
          'Unknown date';
      final distance = RunFormatUtils.formatDistance(
        activity.distanceMeters,
        useMiles,
      );
      final minutes = activity.durationSeconds ~/ 60;
      prompt.writeln(
        '- $date: ${activity.type}, $distance $unit in $minutes mins.',
      );
    }
    return (role: ChatRole.system, text: prompt.toString());
  }

  Stream<String> reply(List<ChatMessage> messages) async* {
    var hasReply = false;
    try {
      await for (final chunk in _repository.streamReply(messages)) {
        if (!hasReply && chunk.trim().isEmpty) continue;
        hasReply = true;
        yield chunk;
      }
    } catch (_) {
      if (hasReply) rethrow;
    }
    if (hasReply) return;

    final fallback = (await _repository.loadReply(messages))?.trim();
    if (fallback != null && fallback.isNotEmpty) yield fallback;
  }
}

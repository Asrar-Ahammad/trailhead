import 'package:isar/isar.dart';

import '../../../shared/state_management/global/ai_config_cubit.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../domain/chat_entity_coach_conversation.dart';
import '../domain/chat_repository_coach_conversation.dart';
import 'chat_request_model_coach_reply.dart';
import 'chat_service_coach_reply.dart';

class ChatRepositoryImplementation implements ChatRepository {
  const ChatRepositoryImplementation(this._isar, this._config, this._service);

  final Isar _isar;
  final AiConfigCubit _config;
  final ChatCoachReplyService _service;

  @override
  bool get isConfigured => _config.state.isConfigured;

  @override
  Future<List<ChatActivity>> loadRecentActivities({required int limit}) async {
    final runs = await _isar.runIsars
        .where()
        .sortByStartTimeDesc()
        .limit(limit)
        .findAll();
    return [
      for (final run in runs)
        (
          type: run.activityType ?? 'run',
          startTime: run.startTime,
          distanceMeters: run.distanceM ?? 0.0,
          durationSeconds: run.durationS ?? 0,
        ),
    ];
  }

  @override
  Stream<String> streamReply(List<ChatMessage> messages) => _service
      .streamReply(_config.state, ChatReplyRequestModel(messages))
      .map((response) => response.text);

  @override
  Future<String?> loadReply(List<ChatMessage> messages) async =>
      (await _service.loadReply(
        _config.state,
        ChatReplyRequestModel(messages),
      ))?.text;
}

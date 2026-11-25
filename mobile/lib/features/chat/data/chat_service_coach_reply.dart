import '../../ai/domain/ai_config.dart';
import '../../ai/domain/ai_repository_provider_reply.dart';
import 'chat_request_model_coach_reply.dart';
import 'chat_response_model_coach_reply.dart';

class ChatCoachReplyService {
  const ChatCoachReplyService(this._ai);

  final AiReplyRepository _ai;

  Stream<ChatReplyResponseModel> streamReply(
    AiConfig config,
    ChatReplyRequestModel request,
  ) => _ai.stream(config, request.messages).map(ChatReplyResponseModel.new);

  Future<ChatReplyResponseModel?> loadReply(
    AiConfig config,
    ChatReplyRequestModel request,
  ) async {
    final reply = await _ai.complete(config, request.messages);
    return reply == null ? null : ChatReplyResponseModel(reply);
  }
}

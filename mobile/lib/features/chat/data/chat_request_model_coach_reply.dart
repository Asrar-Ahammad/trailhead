import '../../ai/domain/ai_repository_provider_reply.dart';
import '../domain/chat_entity_coach_conversation.dart';

class ChatReplyRequestModel {
  ChatReplyRequestModel(List<ChatMessage> messages)
    : messages = [
        for (final message in messages)
          (role: message.role.name, content: message.text),
      ];

  final List<AiMessage> messages;
}

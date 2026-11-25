import 'chat_entity_coach_conversation.dart';

abstract interface class ChatRepository {
  bool get isConfigured;
  Future<List<ChatActivity>> loadRecentActivities({required int limit});
  Stream<String> streamReply(List<ChatMessage> messages);
  Future<String?> loadReply(List<ChatMessage> messages);
}

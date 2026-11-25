import '../domain/ai_config.dart';
import '../domain/ai_repository_provider_reply.dart';

class AiProviderRequestModel {
  const AiProviderRequestModel(this.config, [this.messages = const []]);

  final AiConfig config;
  final List<AiMessage> messages;

  List<Map<String, String>> toMessages() => [
    for (final message in messages)
      {'role': message.role, 'content': message.content},
  ];
}

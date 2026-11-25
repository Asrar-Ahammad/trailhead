import '../data/ai_repository_implementation_provider_reply.dart';
import '../data/ai_service_provider_reply.dart';
import '../domain/ai_config.dart';
import '../domain/ai_repository_provider_reply.dart';

export '../domain/ai_repository_provider_reply.dart' show AiTestResult;

// Keeps existing run analysis and summary callers on the shared AI transport.
class AiClient {
  const AiClient(this._config);

  final AiConfig _config;
  static const _repository = AiReplyRepositoryImplementation(
    AiProviderReplyService(),
  );

  Future<String?> chat(List<Map<String, dynamic>> messages) =>
      _repository.complete(_config, _typedMessages(messages));

  Stream<String> streamChat(List<Map<String, dynamic>> messages) =>
      _repository.stream(_config, _typedMessages(messages));

  Future<AiTestResult> testConnection() => _repository.checkConnection(_config);

  List<AiMessage> _typedMessages(List<Map<String, dynamic>> messages) => [
    for (final message in messages)
      (role: message['role'] as String, content: message['content'] as String),
  ];
}

import '../domain/ai_config.dart';
import '../domain/ai_repository_provider_reply.dart';
import 'ai_request_model_provider_reply.dart';
import 'ai_service_provider_reply.dart';

class AiReplyRepositoryImplementation implements AiReplyRepository {
  const AiReplyRepositoryImplementation(this._service);

  final AiProviderReplyService _service;

  @override
  Future<String?> complete(AiConfig config, List<AiMessage> messages) async =>
      (await _service.complete(AiProviderRequestModel(config, messages)))?.text;

  @override
  Stream<String> stream(AiConfig config, List<AiMessage> messages) => _service
      .stream(AiProviderRequestModel(config, messages))
      .map((reply) => reply.text);

  @override
  Future<AiTestResult> checkConnection(AiConfig config) async {
    final response = await _service.checkConnection(
      AiProviderRequestModel(config),
    );
    return AiTestResult(success: response.success, message: response.message);
  }
}

import 'ai_config.dart';

typedef AiMessage = ({String role, String content});

class AiTestResult {
  const AiTestResult({required this.success, required this.message});

  final bool success;
  final String message;
}

abstract interface class AiReplyRepository {
  Future<String?> complete(AiConfig config, List<AiMessage> messages);
  Stream<String> stream(AiConfig config, List<AiMessage> messages);
  Future<AiTestResult> checkConnection(AiConfig config);
}

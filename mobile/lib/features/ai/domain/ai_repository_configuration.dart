import 'ai_config.dart';

abstract interface class AiConfigurationRepository {
  AiConfig load();
  Future<void> save(AiConfig config);
}

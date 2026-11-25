import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_config.dart';
import '../domain/ai_repository_configuration.dart';
import '../domain/ai_use_case_select_provider.dart';

class AiConfigurationRepositoryImplementation
    implements AiConfigurationRepository {
  const AiConfigurationRepositoryImplementation(this._preferences);

  final SharedPreferences _preferences;
  static const _providerKey = 'ai_provider';
  static const _modelKey = 'ai_model';
  static const _apiKey = 'ai_api_key';

  @override
  AiConfig load() {
    final options = AiProviderOptions.forProvider(
      _preferences.getString(_providerKey) ?? '',
    );
    return AiConfig(
      provider: options.id,
      model: _preferences.getString(_modelKey) ?? options.defaultModel,
      apiKey: _preferences.getString(_apiKey) ?? '',
    );
  }

  @override
  Future<void> save(AiConfig config) async {
    final saved = await Future.wait([
      _preferences.setString(_providerKey, config.provider),
      _preferences.setString(_modelKey, config.model),
      _preferences.setString(_apiKey, config.apiKey),
    ]);
    if (saved.contains(false)) {
      throw StateError('Could not save AI configuration.');
    }
  }
}

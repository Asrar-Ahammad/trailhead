import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConfig {
  final String provider; // 'openai', 'gemini', 'anthropic'
  final String model;
  final String apiKey;

  AiConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
  });

  bool get isConfigured => apiKey.isNotEmpty;
}

class AiConfigNotifier extends StateNotifier<AiConfig> {
  AiConfigNotifier() : super(AiConfig(provider: 'openai', model: 'gpt-5', apiKey: '')) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    state = AiConfig(
      provider: prefs.getString('ai_provider') ?? 'openai',
      model: prefs.getString('ai_model') ?? 'gpt-5',
      apiKey: prefs.getString('ai_api_key') ?? '',
    );
  }

  Future<void> updateConfig({String? provider, String? model, String? apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    if (provider != null) await prefs.setString('ai_provider', provider);
    if (model != null) await prefs.setString('ai_model', model);
    if (apiKey != null) await prefs.setString('ai_api_key', apiKey);
    
    state = AiConfig(
      provider: provider ?? state.provider,
      model: model ?? state.model,
      apiKey: apiKey ?? state.apiKey,
    );
  }
}

final aiConfigProvider = StateNotifierProvider<AiConfigNotifier, AiConfig>((ref) {
  return AiConfigNotifier();
});

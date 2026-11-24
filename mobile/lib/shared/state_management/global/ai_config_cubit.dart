import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/ai/domain/ai_config.dart';

class AiConfigCubit extends Cubit<AiConfig> {
  AiConfigCubit({required SharedPreferences preferences, required AiConfig initial})
    : _preferences = preferences,
      super(initial);

  final SharedPreferences _preferences;

  Future<void> updateConfig({String? provider, String? model, String? apiKey}) async {
    if (provider != null) await _preferences.setString('ai_provider', provider);
    if (model != null) await _preferences.setString('ai_model', model);
    if (apiKey != null) await _preferences.setString('ai_api_key', apiKey);

    emit(AiConfig(
      provider: provider ?? state.provider,
      model: model ?? state.model,
      apiKey: apiKey ?? state.apiKey,
    ));
  }
}

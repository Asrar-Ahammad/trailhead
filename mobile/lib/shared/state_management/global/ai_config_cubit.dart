import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/ai/domain/ai_config.dart';
import '../../../features/ai/domain/ai_repository_configuration.dart';
import '../../../features/ai/domain/ai_use_case_select_provider.dart';

class AiConfigCubit extends Cubit<AiConfig> {
  AiConfigCubit(this._repository) : super(_repository.load());

  final AiConfigurationRepository _repository;
  Future<void> _pendingSave = Future<void>.value();
  bool _lastSaveFailed = false;

  void reloadPreference() {
    if (!isClosed) emit(_repository.load());
  }

  Future<void> updateConfig({String? provider, String? model, String? apiKey}) {
    final next = AiConfig(
      provider: provider ?? state.provider,
      model:
          model ??
          (provider == null
              ? state.model
              : AiProviderOptions.forProvider(provider).defaultModel),
      apiKey: apiKey ?? state.apiKey,
    );
    final unchanged = next.provider == state.provider &&
        next.model == state.model &&
        next.apiKey == state.apiKey;
    if (unchanged && !_lastSaveFailed) return _pendingSave;
    if (!unchanged) emit(next);
    _pendingSave = _pendingSave
        .then((_) async {
          await _repository.save(next);
          _lastSaveFailed = false;
        })
        .onError<Object>((error, trace) {
          _lastSaveFailed = true;
          if (!isClosed) addError(error, trace);
        });
    return _pendingSave;
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/haptics/domain/haptics_repository_feedback.dart';
import '../../../features/haptics/domain/haptics_use_case_play_feedback.dart';

class HapticsCubit extends Cubit<bool> {
  HapticsCubit(this._repository, this._play) : super(_repository.isEnabled);

  final HapticsRepository _repository;
  final PlayHapticFeedback _play;
  bool _saving = false;

  void reloadPreference() {
    if (!isClosed) emit(_repository.isEnabled);
  }

  Future<void> setEnabled(bool enabled) async {
    if (_saving || state == enabled) return;

    _saving = true;
    try {
      if (!await _repository.setEnabled(enabled)) {
        throw StateError('Could not save the haptics preference.');
      }
      if (isClosed) return;
      emit(enabled);
      if (enabled) await lightImpact();
    } finally {
      _saving = false;
    }
  }

  Future<void> lightImpact() => _play(HapticEffect.light, enabled: state);
  Future<void> mediumImpact() => _play(HapticEffect.medium, enabled: state);
  Future<void> heavyImpact() => _play(HapticEffect.heavy, enabled: state);
  Future<void> selectionClick() =>
      _play(HapticEffect.selection, enabled: state);
  Future<void> vibrate() => _play(HapticEffect.vibration, enabled: state);
}

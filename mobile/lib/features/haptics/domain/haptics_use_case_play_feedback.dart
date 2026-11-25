import 'haptics_repository_feedback.dart';

class PlayHapticFeedback {
  const PlayHapticFeedback(this._repository);

  final HapticsRepository _repository;

  Future<void> call(HapticEffect effect, {required bool enabled}) async {
    if (enabled) await _repository.play(effect);
  }
}

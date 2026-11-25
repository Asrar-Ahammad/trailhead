import 'audio_repository_ui_sounds.dart';

class PlayUiSound {
  const PlayUiSound(this._repository);

  final AudioRepository _repository;

  Future<void> call(AudioCue cue, {required bool enabled}) async {
    if (enabled) await _repository.play(cue);
  }
}

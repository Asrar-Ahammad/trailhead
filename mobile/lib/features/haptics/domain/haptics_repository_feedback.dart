enum HapticEffect { light, medium, heavy, selection, vibration }

abstract interface class HapticsRepository {
  bool get isEnabled;
  Future<bool> setEnabled(bool enabled);
  Future<void> play(HapticEffect effect);
}

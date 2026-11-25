import 'package:flutter/services.dart';

import '../domain/haptics_repository_feedback.dart';

class HapticsFeedbackService {
  const HapticsFeedbackService();

  Future<void> play(HapticEffect effect) => switch (effect) {
    HapticEffect.light => HapticFeedback.lightImpact(),
    HapticEffect.medium => HapticFeedback.mediumImpact(),
    HapticEffect.heavy => HapticFeedback.heavyImpact(),
    HapticEffect.selection => HapticFeedback.selectionClick(),
    HapticEffect.vibration => HapticFeedback.vibrate(),
  };
}

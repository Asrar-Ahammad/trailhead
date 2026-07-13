import 'package:flutter_riverpod/flutter_riverpod.dart';

class DistanceUnitNotifier extends StateNotifier<bool> {
  // Always defaults to false (kilometers only)
  DistanceUnitNotifier() : super(false);

  void setUseMiles(bool useMiles) {
    // Intentionally forced to false, to remove miles functionality
    state = false;
  }
}

final distanceUnitProvider = StateNotifierProvider<DistanceUnitNotifier, bool>((ref) {
  return DistanceUnitNotifier();
});

import 'package:flutter/material.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';

/// A [NavigatorObserver] that plays the retro back sound whenever any route
/// is popped from the navigation stack — covers system back gesture, AppBar
/// back arrow, and programmatic [Navigator.pop] calls throughout the app.
class SoundNavigatorObserver extends NavigatorObserver {
  final SoundService soundService;

  SoundNavigatorObserver({required this.soundService});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Only play when we're actually going back to a previous screen
    // (skip dialog/bottom-sheet pops that return values, and popUntil chains)
    if (previousRoute != null) {
      soundService.playSystemBack();
    }
  }
}

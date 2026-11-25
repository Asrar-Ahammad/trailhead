import 'package:flutter/material.dart';

/// A [NavigatorObserver] that plays the retro back sound whenever any route
/// is popped from the navigation stack — covers system back gesture, AppBar
/// back arrow, and programmatic [Navigator.pop] calls throughout the app.
class SoundNavigatorObserver extends NavigatorObserver {
  final Future<void> Function() playBackSound;

  SoundNavigatorObserver({required this.playBackSound});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Skip the final pop when there is no route to return to.
    if (previousRoute != null) {
      playBackSound();
    }
  }
}

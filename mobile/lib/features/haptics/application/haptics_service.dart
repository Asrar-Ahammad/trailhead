import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hapticsServiceProvider = Provider((ref) => HapticsService());

class HapticsService {
  bool? _hapticsEnabled;

  HapticsService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true; // Default to true
  }

  Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
  }

  Future<void> _ensureInit() async {
    if (_hapticsEnabled == null) {
      await _init();
    }
  }

  bool get isEnabled => _hapticsEnabled ?? true;

  Future<void> lightImpact() async {
    await _ensureInit();
    if (!(_hapticsEnabled ?? true)) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    await _ensureInit();
    if (!(_hapticsEnabled ?? true)) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    await _ensureInit();
    if (!(_hapticsEnabled ?? true)) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selectionClick() async {
    await _ensureInit();
    if (!(_hapticsEnabled ?? true)) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> vibrate() async {
    await _ensureInit();
    if (!(_hapticsEnabled ?? true)) return;
    await HapticFeedback.vibrate();
  }
}

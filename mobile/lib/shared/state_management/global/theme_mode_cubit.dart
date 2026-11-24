import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit({required SharedPreferences preferences, required ThemeMode initialMode})
    : _preferences = preferences,
      super(initialMode);

  final SharedPreferences _preferences;

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _preferences.setString('themeMode', mode.name);
  }
}

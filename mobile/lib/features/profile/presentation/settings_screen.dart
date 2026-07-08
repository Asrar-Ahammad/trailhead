import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_colors.dart';
import '../../audio/application/sound_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uiSoundsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uiSoundsEnabled = prefs.getBool('ui_sounds_enabled') ?? false;
    });
  }

  Future<void> _toggleUiSounds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ui_sounds_enabled', value);
    setState(() {
      _uiSoundsEnabled = value;
    });
    
    // Notify the sound service to reload settings
    await ref.read(soundServiceProvider).reloadSettings();
    if (value) {
      await ref.read(soundServiceProvider).playNavBlip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: Text(
              'Retro UI Sounds',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Play 8-bit sound effects on interaction.',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            value: _uiSoundsEnabled,
            onChanged: _toggleUiSounds,
            activeColor: colors.accent,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../haptics/application/haptics_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../audio/application/sound_service.dart';
import '../../../main.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/presentation/auth_wrapper.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../../shared/theme/app_themes.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uiSoundsEnabled = false;
  bool _hapticsEnabled = true;
  double? _userWeightKg;
  String? _userName;
  String? _userDob; // ISO8601 string
  String? _userGender;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uiSoundsEnabled = prefs.getBool('ui_sounds_enabled') ?? false;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _userWeightKg = prefs.getDouble('user_weight_kg');
      _userName = prefs.getString('user_name');
      _userDob = prefs.getString('user_dob');
      _userGender = prefs.getString('user_gender');
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

  Future<void> _toggleHaptics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', value);
    setState(() {
      _hapticsEnabled = value;
    });
    
    await ref.read(hapticsServiceProvider).reloadSettings();
    if (value) {
      await ref.read(hapticsServiceProvider).lightImpact();
    }
  }

  Future<void> _updateWeight() async {
    final controller = TextEditingController(text: _userWeightKg?.toString() ?? '');
    final colors = Theme.of(context).extension<AppColors>()!;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Body Weight (kg)', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.spaceGrotesk(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 70.5',
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Save', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final weight = double.tryParse(result);
      if (weight != null && weight > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_weight_kg', weight);
        setState(() {
          _userWeightKg = weight;
        });
      }
    }
  }

  Future<void> _updateName() async {
    final controller = TextEditingController(text: _userName ?? '');
    final colors = Theme.of(context).extension<AppColors>()!;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Name', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.spaceGrotesk(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Save', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result.trim());
      setState(() {
        _userName = result.trim();
      });
    }
  }

  Future<void> _updateDob() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final initialDate = _userDob != null ? DateTime.tryParse(_userDob!) ?? DateTime(1990) : DateTime(1990);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.accent,
              onPrimary: colors.background,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = picked.toIso8601String();
      await prefs.setString('user_dob', dateStr);
      setState(() {
        _userDob = dateStr;
      });
    }
  }

  Future<void> _updateGender() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: colors.surface,
        title: Text('Gender', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        children: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(g),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(g, style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16)),
          ),
        )).toList(),
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_gender', result);
      setState(() {
        _userGender = result;
      });
    }
  }

  int? _calculateAge() {
    if (_userDob == null) return null;
    final dob = DateTime.tryParse(_userDob!);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeMode = ref.watch(themeModeProvider);
    
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
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'PROFILE',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ListTile(
            title: Text(
              'Name',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _userName?.isNotEmpty == true ? _userName! : 'Not set',
              style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14),
            ),
            trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary),
            onTap: _updateName,
          ),
          Divider(color: colors.border, height: 1),
          ListTile(
            title: Text(
              'Date of Birth',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _userDob != null ? '${_userDob!.split('T').first} (${_calculateAge()} years)' : 'Not set',
              style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14),
            ),
            trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary),
            onTap: _updateDob,
          ),
          Divider(color: colors.border, height: 1),
          ListTile(
            title: Text(
              'Gender',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _userGender ?? 'Not set',
              style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14),
            ),
            trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary),
            onTap: _updateGender,
          ),
          Divider(color: colors.border, height: 1),
          ListTile(
            title: Text(
              'Body Weight',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _userWeightKg != null ? '${_userWeightKg!.toStringAsFixed(1)} kg' : 'Not set (Required for Calories)',
              style: GoogleFonts.spaceGrotesk(
                color: _userWeightKg != null ? colors.textSecondary : colors.error,
                fontSize: 14,
              ),
            ),
            trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary),
            onTap: _updateWeight,
          ),
          Divider(color: colors.border, height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'PREFERENCES',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
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
          Divider(color: colors.border, height: 1),
          SwitchListTile(
            title: Text(
              'Haptic Feedback',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Vibrate on UI interactions.',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            value: _hapticsEnabled,
            onChanged: _toggleHaptics,
            activeColor: colors.accent,
          ),
          Divider(color: colors.border, height: 1),
          ListTile(
            title: Text(
              'App Theme',
              style: GoogleFonts.spaceGrotesk(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: ThemeSwitcher(
              builder: (context) => DropdownButton<ThemeMode>(
                value: themeMode,
                dropdownColor: colors.surface,
                style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).setMode(mode);
                    
                    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
                    final newTheme = isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
                    
                    ThemeSwitcher.of(context).changeTheme(theme: newTheme);
                  }
                },
              ),
            ),
          ),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.error.withOpacity(0.5)),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.spaceGrotesk(
                color: colors.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

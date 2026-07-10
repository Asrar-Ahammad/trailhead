import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
import '../../sync/data/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uiSoundsEnabled = false;
  bool _hapticsEnabled = true;
  bool _audioCuesEnabled = true;
  double _audioCueFrequency = 1.0;
  int _restDaysLimit = 0;
  String? _lastRestDaysUpdate;
  double? _userWeightKg;
  String? _userName;
  String? _userEmail;
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
      _audioCuesEnabled = prefs.getBool('audio_cues_enabled') ?? true;
      _audioCueFrequency = prefs.getDouble('audio_cue_frequency') ?? 1.0;
      _restDaysLimit = prefs.getInt('rest_days_limit') ?? 0;
      _lastRestDaysUpdate = prefs.getString('last_rest_days_update');
      _userWeightKg = prefs.getDouble('user_weight_kg');
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      _userDob = prefs.getString('user_dob');
      _userGender = prefs.getString('user_gender');
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.client.get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['email'] != null) await prefs.setString('user_email', data['email']);
        if (data['name'] != null) await prefs.setString('user_name', data['name']);
        if (data['dob'] != null) await prefs.setString('user_dob', data['dob']);
        if (data['gender'] != null) await prefs.setString('user_gender', data['gender']);
        if (data['weightKg'] != null) await prefs.setDouble('user_weight_kg', (data['weightKg'] as num).toDouble());

        if (mounted) {
          setState(() {
            if (data['email'] != null) _userEmail = data['email'];
            if (data['name'] != null) _userName = data['name'];
            if (data['dob'] != null) _userDob = data['dob'];
            if (data['gender'] != null) _userGender = data['gender'];
            if (data['weightKg'] != null) _userWeightKg = (data['weightKg'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
    }
  }

  Future<void> _updateRestDays() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    if (_lastRestDaysUpdate != null) {
      final lastUpdate = DateTime.parse(_lastRestDaysUpdate!);
      final now = DateTime.now();
      if (lastUpdate.year == now.year && lastUpdate.month == now.month) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rest days can only be updated once per month.',
                style: GoogleFonts.spaceGrotesk(color: colors.background),
              ),
              backgroundColor: colors.textPrimary,
            ),
          );
        }
        return;
      }
    }

    final controller = TextEditingController(text: _restDaysLimit.toString());
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Monthly Rest Days', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.spaceGrotesk(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 4',
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
      final val = int.tryParse(result);
      if (val != null && val >= 0 && val <= 31) {
        final prefs = await SharedPreferences.getInstance();
        final nowStr = DateTime.now().toIso8601String();
        await prefs.setInt('rest_days_limit', val);
        await prefs.setString('last_rest_days_update', nowStr);
        
        setState(() {
          _restDaysLimit = val;
          _lastRestDaysUpdate = nowStr;
        });

        try {
          final api = ref.read(apiClientProvider);
          await api.client.put('/streak', data: {'restDaysLimit': val});
        } catch (e) {
          debugPrint('Failed to sync rest days to backend: $e');
        }
      }
    }
  }

  Future<void> _toggleAudioCues(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_cues_enabled', value);
    setState(() {
      _audioCuesEnabled = value;
    });
    
    await ref.read(soundServiceProvider).playToggleSwitch();
  }

  Future<void> _updateAudioCueFrequency(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_cue_frequency', value);
    setState(() {
      _audioCueFrequency = value;
    });
    
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'update_settings',
        'audioCueFrequency': value,
      });
    } catch (_) {}
    
    await ref.read(soundServiceProvider).playToggleSwitch();
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
      await ref.read(soundServiceProvider).playToggleSwitch();
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
    await ref.read(soundServiceProvider).playToggleSwitch();
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

        try {
          final api = ref.read(apiClientProvider);
          await api.client.put('/auth/me', data: {'weightKg': weight});
        } catch (e) {
          debugPrint('Failed to sync weight to backend: $e');
        }
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

      try {
        final api = ref.read(apiClientProvider);
        await api.client.put('/auth/me', data: {'name': result.trim()});
      } catch (e) {
        debugPrint('Failed to sync name to backend: $e');
      }
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

      try {
        final api = ref.read(apiClientProvider);
        await api.client.put('/auth/me', data: {'dob': dateStr});
      } catch (e) {
        debugPrint('Failed to sync dob to backend: $e');
      }
    }
  }

  Future<void> _updateGender() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: colors.surface,
        title: Text('Gender', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        children: ['Male', 'Female', 'Prefer not to say'].map((g) => SimpleDialogOption(
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

      try {
        final api = ref.read(apiClientProvider);
        await api.client.put('/auth/me', data: {'gender': result});
      } catch (e) {
        debugPrint('Failed to sync gender to backend: $e');
      }
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authServiceProvider).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionGroup(List<Widget> children, AppColors colors) {
    final List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(color: colors.border.withOpacity(0.5), height: 1, indent: 16, endIndent: 16));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: items,
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('PROFILE', colors),
          _buildSectionGroup([
            ListTile(
              title: Text('Email', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text(_userEmail?.isNotEmpty == true ? _userEmail! : 'Not set', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              trailing: Icon(PhosphorIcons.envelopeSimple(), color: colors.textSecondary, size: 20),
            ),
            ListTile(
              title: Text('Name', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text(_userName?.isNotEmpty == true ? _userName! : 'Not set', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary, size: 20),
              onTap: _updateName,
            ),
            ListTile(
              title: Text('Date of Birth', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text(_userDob != null ? '${_userDob!.split('T').first} (${_calculateAge()} years)' : 'Not set', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary, size: 20),
              onTap: _updateDob,
            ),
            ListTile(
              title: Text('Gender', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text(_userGender ?? 'Not set', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary, size: 20),
              onTap: _updateGender,
            ),
            ListTile(
              title: Text('Body Weight', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text(_userWeightKg != null ? '${_userWeightKg!.toStringAsFixed(1)} kg' : 'Not set (Required for Calories)', style: GoogleFonts.spaceGrotesk(color: _userWeightKg != null ? colors.textSecondary : colors.error, fontSize: 14)),
              trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary, size: 20),
              onTap: _updateWeight,
            ),
          ], colors),

          _buildSectionHeader('WORKOUT', colors),
          _buildSectionGroup([
            SwitchListTile(
              title: Text('Audio Cues', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text('Announce distance and pace.', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              value: _audioCuesEnabled,
              onChanged: _toggleAudioCues,
              activeColor: colors.accent,
            ),
            if (_audioCuesEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cue Frequency', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                    DropdownButton<double>(
                      value: _audioCueFrequency,
                      dropdownColor: colors.surface,
                      style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 1.0, child: Text('Every 1 km')),
                        DropdownMenuItem(value: 0.5, child: Text('Every 0.5 km')),
                      ],
                      onChanged: (value) {
                        if (value != null) _updateAudioCueFrequency(value);
                      },
                    ),
                  ],
                ),
              ),
            ListTile(
              title: Text('Monthly Rest Days', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text('$_restDaysLimit days/month', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              trailing: Icon(PhosphorIcons.caretRight(), color: colors.textSecondary, size: 20),
              onTap: _updateRestDays,
            ),
          ], colors),

          _buildSectionHeader('APP PREFERENCES', colors),
          _buildSectionGroup([
            SwitchListTile(
              title: Text('Retro UI Sounds', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text('Play 8-bit sound effects.', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              value: _uiSoundsEnabled,
              onChanged: _toggleUiSounds,
              activeColor: colors.accent,
            ),
            SwitchListTile(
              title: Text('Haptic Feedback', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text('Vibrate on UI interactions.', style: GoogleFonts.spaceGrotesk(color: colors.textSecondary, fontSize: 14)),
              value: _hapticsEnabled,
              onChanged: _toggleHaptics,
              activeColor: colors.accent,
            ),
            ListTile(
              title: Text('App Theme', style: GoogleFonts.spaceGrotesk(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                      
                      if (isDark) {
                        ref.read(soundServiceProvider).playThemeDark();
                      } else {
                        ref.read(soundServiceProvider).playThemeLight();
                      }
                      
                      ThemeSwitcher.of(context).changeTheme(theme: newTheme);
                    }
                  },
                ),
              ),
            ),
          ], colors),

          const SizedBox(height: 32),
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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

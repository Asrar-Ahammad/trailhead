import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:trailhead_mobile/shared/theme/app_themes.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/theme_mode_cubit.dart';
import 'package:trailhead_mobile/features/shoes/presentation/shoe_management_screen.dart';
import 'package:trailhead_mobile/features/ai/presentation/ai_panel_configuration.dart';
import 'package:trailhead_mobile/features/data_management/presentation/data_management_panel_backups.dart';
import 'package:trailhead_mobile/features/onboarding/presentation/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _audioCuesEnabled = true;
  double _audioCueFrequency = 1.0;
  int _restDaysLimit = 0;
  String? _lastRestDaysUpdate;
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
    if (!mounted) return;

    setState(() {
      _audioCuesEnabled = prefs.getBool('audio_cues_enabled') ?? true;
      _audioCueFrequency = prefs.getDouble('audio_cue_frequency') ?? 1.0;
      _restDaysLimit = prefs.getInt('rest_days_limit') ?? 0;
      _lastRestDaysUpdate = prefs.getString('last_rest_days_update');
      _userWeightKg = prefs.getDouble('user_weight_kg');
      _userName = prefs.getString('user_name');
      _userDob = prefs.getString('user_dob');
      _userGender = prefs.getString('user_gender');
    });
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
                style: AppTextStyles.bodyMedium(color: colors.background),
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
        title: Text('Monthly Rest Days', style: AppTextStyles.title(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 4',
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => AppNavigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => AppNavigator.pop(context, controller.text),
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
        
        if (mounted) {
          setState(() {
            _restDaysLimit = val;
            _lastRestDaysUpdate = nowStr;
          });
        }
      }
    }
  }

  Future<void> _toggleAudioCues(bool value) async {
    final audio = context.read<AudioCubit>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_cues_enabled', value);
    if (!mounted) return;
    setState(() {
      _audioCuesEnabled = value;
    });
    await audio.playToggleSwitch();
  }

  Future<void> _updateAudioCueFrequency(double value) async {
    final audio = context.read<AudioCubit>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_cue_frequency', value);
    if (mounted) {
      setState(() {
        _audioCueFrequency = value;
      });
    }
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'update_settings',
        'audioCueFrequency': value,
      });
    } catch (_) {}
    await audio.playToggleSwitch();
  }

  Future<void> _toggleUiSounds(bool value) async {
    try {
      await context.read<AudioCubit>().setEnabled(value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update UI sounds.')),
      );
    }
  }

  Future<void> _toggleHaptics(bool value) async {
    final sound = context.read<AudioCubit>();
    try {
      await context.read<HapticsCubit>().setEnabled(value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update haptics.')),
      );
      return;
    }
    await sound.playToggleSwitch();
  }

  Future<void> _updateWeight() async {
    final controller = TextEditingController(text: _userWeightKg?.toString() ?? '');
    final colors = Theme.of(context).extension<AppColors>()!;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Body Weight (kg)', style: AppTextStyles.title(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium(color: colors.textPrimary),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. 70.5',
            hintStyle: TextStyle(color: colors.textSecondary),
            suffixText: 'kg',
            suffixStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
          ),
        ),
        actions: [
          if (_userWeightKg != null)
            TextButton(
              onPressed: () => AppNavigator.pop(context, 'CLEAR'),
              child: Text('Reset to Not set', style: TextStyle(color: colors.error)),
            ),
          TextButton(
            onPressed: () => AppNavigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => AppNavigator.pop(context, controller.text),
            child: Text('Save', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      if (result == 'CLEAR' || result.trim().isEmpty) {
        await prefs.remove('user_weight_kg');
        setState(() {
          _userWeightKg = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Body weight cleared (Not set).', style: AppTextStyles.bodyMedium(color: colors.background)),
              backgroundColor: colors.textPrimary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final weight = double.tryParse(result.trim());
        if (weight != null && weight > 0) {
          await prefs.setDouble('user_weight_kg', weight);
          setState(() {
            _userWeightKg = weight;
          });
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
        title: Text('Name', style: AppTextStyles.title(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => AppNavigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => AppNavigator.pop(context, controller.text),
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
        title: Text('Gender', style: AppTextStyles.title(color: colors.textPrimary)),
        children: ['Male', 'Female', 'Prefer not to say'].map((g) => SimpleDialogOption(
          onPressed: () => AppNavigator.pop(context, g),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(g, style: AppTextStyles.bodyLarge(color: colors.textPrimary)),
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

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(title, style: AppTextStyles.labelCaps(color: colors.accent)),
    );
  }

  Widget _buildSectionGroup(List<Widget> children, AppColors colors) {
    final List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(color: colors.border.withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeMode = context.watch<ThemeModeCubit>().state;
    
    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Settings',
          style: AppTextStyles.title(color: colors.textPrimary),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          left: 16,
          right: 16,
          bottom: 32,
        ),
        children: [
          _buildSectionHeader('PROFILE', colors),
          _buildSectionGroup([
            ListTile(
              title: Text('Name', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text(_userName?.isNotEmpty == true ? _userName! : 'Not set', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: _updateName,
            ),
            ListTile(
              title: Text('Date of Birth', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text(_userDob != null ? '${_userDob!.split('T').first} (${_calculateAge()} years)' : 'Not set', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: _updateDob,
            ),
            ListTile(
              title: Text('Gender', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text(_userGender ?? 'Not set', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: _updateGender,
            ),
            ListTile(
              title: Text('Body Weight', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text(_userWeightKg != null ? '${_userWeightKg!.toStringAsFixed(1)} kg' : 'Not set (Required for Calories)', style: AppTextStyles.bodyMedium(color: _userWeightKg != null ? colors.textSecondary : colors.error)),
              trailing: _userWeightKg != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIcons.trash, color: colors.textSecondary, size: 18),
                          tooltip: 'Clear weight',
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('user_weight_kg');
                            setState(() {
                              _userWeightKg = null;
                            });
                          },
                        ),
                        Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
                      ],
                    )
                  : Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: _updateWeight,
            ),
          ], colors),

          _buildSectionHeader('WORKOUT', colors),
          _buildSectionGroup([
            ListTile(
              title: Text('My Shoes / Gear', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Manage running shoes & track mileage.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: () {
                context.read<HapticsCubit>().lightImpact();
                AppNavigator.push(context,
                  AppNavigator.materialPageRoute(builder: (_) => const ShoeManagementScreen()),
                );
              },
            ),
            SwitchListTile(
              title: Text('Audio Cues', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Announce distance and pace.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
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
                    Text('Cue Frequency', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
                    DropdownButton<double>(
                      value: _audioCueFrequency,
                      dropdownColor: colors.surface,
                      style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(value: 1.0, child: Text('Every 1 ${context.watch<DistanceUnitCubit>().state ? 'mi' : 'km'}')),
                        DropdownMenuItem(value: 0.5, child: Text('Every 0.5 ${context.watch<DistanceUnitCubit>().state ? 'mi' : 'km'}')),
                      ],
                      onChanged: (value) {
                        if (value != null) _updateAudioCueFrequency(value);
                      },
                    ),
                  ],
                ),
              ),
            ListTile(
              title: Text('Monthly Rest Days', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('$_restDaysLimit days/month', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary, size: 20),
              onTap: _updateRestDays,
            ),
          ], colors),

          _buildSectionHeader('AI CONFIGURATION', colors),
          _buildSectionGroup([const AiConfigurationPanel()], colors),

          _buildSectionHeader('DATA MANAGEMENT', colors),
          _buildSectionGroup([
            DataManagementPanel(
              onRestored: _loadSettings,
              onExportComplete: () {
                context.read<HapticsCubit>().mediumImpact();
                context.read<AudioCubit>().playToggleSwitch();
              },
            ),
          ], colors),

          _buildSectionHeader('APP PREFERENCES', colors),
          _buildSectionGroup([
            SwitchListTile(
              title: Text('Retro UI Sounds', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Play 8-bit sound effects.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              value: context.watch<AudioCubit>().state,
              onChanged: _toggleUiSounds,
              activeColor: colors.accent,
            ),
            SwitchListTile(
              title: Text('Haptic Feedback', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Vibrate on UI interactions.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              value: context.watch<HapticsCubit>().state,
              onChanged: _toggleHaptics,
              activeColor: colors.accent,
            ),
            ListTile(
              title: Text('App Theme', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              trailing: ThemeSwitcher(
                builder: (context) => DropdownButton<ThemeMode>(
                  value: themeMode,
                  dropdownColor: colors.surface,
                  style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      context.read<ThemeModeCubit>().setMode(mode);
                      final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
                      final newTheme = isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
                      
                      if (isDark) {
                        context.read<AudioCubit>().playThemeDark();
                      } else {
                        context.read<AudioCubit>().playThemeLight();
                      }
                      
                      ThemeSwitcher.of(context).changeTheme(theme: newTheme);
                    }
                  },
                ),
              ),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.sparkleFill, color: colors.accent),
              title: Text('App Tour & Features', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Revisit the onboarding guide & feature overview.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary),
              onTap: () {
                context.read<HapticsCubit>().lightImpact();
                AppNavigator.push(context,
                  AppNavigator.materialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
          ], colors),
        ],
      ),
    );
  }
}

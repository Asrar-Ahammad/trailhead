import 'package:trailhead_mobile/shared/widgets/app_bar_backdrop.dart';
import '../domain/profile_repository_settings.dart';
import '../state_management/profile_bloc_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateProfileBloc>()(),
    child: const _SettingsContent(),
  );
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();
  @override
  State<_SettingsContent> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsContent> {
  ProfileSettings get _settings => context.read<ProfileBloc>().state.settings;

  void _edit(ProfileSetting setting, Object? value) {
    context.read<ProfileBloc>().add(EditProfileSetting(setting, value));
  }

  Future<void> _editText(
    ProfileSetting setting,
    String title,
    String initialValue,
    String hint, {
    TextInputType? keyboardType,
    bool canClear = false,
  }) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    var value = initialValue;
    final result = await AppNavigator.dialog<String>(
      context,
      (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          title,
          style: AppTextStyles.title(color: colors.textPrimary),
        ),
        content: TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          onChanged: (text) => value = text,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          if (canClear)
            TextButton(
              onPressed: () => AppNavigator.pop(context, ''),
              child: const Text('Reset to Not set'),
            ),
          TextButton(
            onPressed: () => AppNavigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => AppNavigator.pop(context, value),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (mounted && result != null) _edit(setting, result);
  }

  void _updateRestDays() {
    if (!canEditRestDays(_settings.lastRestDaysUpdate, DateTime.now())) {
      _showMessage('Rest days can only be updated once per month.');
      return;
    }
    _editText(
      ProfileSetting.restDays,
      'Monthly Rest Days',
      _settings.restDays.toString(),
      'e.g. 4',
      keyboardType: TextInputType.number,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  void _updateWeight() => _editText(
    ProfileSetting.weight,
    'Body Weight (kg)',
    _settings.weight?.toString() ?? '',
    'e.g. 70.5',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    canClear: _settings.weight != null,
  );

  void _updateName() => _editText(
    ProfileSetting.name,
    'Name',
    _settings.name ?? '',
    'Enter your name',
  );

  Future<void> _updateDob() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final storedDate = _settings.birthDate;
    final now = DateTime.now();
    final initialDate =
        storedDate != null &&
            !storedDate.isBefore(DateTime(1900)) &&
            !storedDate.isAfter(now)
        ? storedDate
        : DateTime(1990);
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

    if (mounted && picked != null) _edit(ProfileSetting.birthDate, picked);
  }

  Future<void> _updateGender() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final result = await AppNavigator.dialog<String>(
      context,
      (context) => SimpleDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Gender',
          style: AppTextStyles.title(color: colors.textPrimary),
        ),
        children: ['Male', 'Female', 'Prefer not to say']
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => AppNavigator.pop(context, g),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    g,
                    style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (mounted && result != null) _edit(ProfileSetting.gender, result);
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
        items.add(
          Divider(
            color: colors.border.withValues(alpha: 0.5),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
        );
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
      child: Column(children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeMode = context.watch<ThemeModeCubit>().state;
    final distanceUnit = context.watch<DistanceUnitCubit>().state ? 'mi' : 'km';

    final settings = context.watch<ProfileBloc>().state.settings;
    final birthday = settings.birthDate;
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.message case final message?) _showMessage(message);
        if (state.updated == ProfileSetting.weight &&
            state.settings.weight == null) {
          _showMessage('Body weight cleared (Not set).');
        }
        if (state.updated == ProfileSetting.audioCues ||
            state.updated == ProfileSetting.cueFrequency) {
          context.read<AudioCubit>().playToggleSwitch();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: colors.surface.withValues(alpha: 0.7),
          elevation: 0,
          flexibleSpace: const AppBarBackdrop(),
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
                title: Text(
                  'Name',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  settings.name?.isNotEmpty == true
                      ? settings.name!
                      : 'Not set',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onTap: _updateName,
              ),
              ListTile(
                title: Text(
                  'Date of Birth',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  birthday != null
                      ? '${birthday.toIso8601String().split('T').first} (${ageOnDate(birthday, DateTime.now())} years)'
                      : 'Not set',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onTap: _updateDob,
              ),
              ListTile(
                title: Text(
                  'Gender',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  settings.gender ?? 'Not set',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onTap: _updateGender,
              ),
              ListTile(
                title: Text(
                  'Body Weight',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  settings.weight != null
                      ? '${settings.weight!.toStringAsFixed(1)} kg'
                      : 'Not set (Required for Calories)',
                  style: AppTextStyles.bodyMedium(
                    color: settings.weight != null
                        ? colors.textSecondary
                        : colors.error,
                  ),
                ),
                trailing: settings.weight != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.trash,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            tooltip: 'Clear weight',
                            onPressed: () => _edit(ProfileSetting.weight, null),
                          ),
                          Icon(
                            PhosphorIcons.caretRight,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                        ],
                      )
                    : Icon(
                        PhosphorIcons.caretRight,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                onTap: _updateWeight,
              ),
            ], colors),

            _buildSectionHeader('WORKOUT', colors),
            _buildSectionGroup([
              ListTile(
                title: Text(
                  'My Shoes / Gear',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Manage running shoes & track mileage.',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  context.read<HapticsCubit>().lightImpact();
                  AppNavigator.push(
                    context,
                    AppNavigator.materialPageRoute(
                      builder: (_) => const ShoeManagementScreen(),
                    ),
                  );
                },
              ),
              SwitchListTile(
                title: Text(
                  'Audio Cues',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Announce distance and pace.',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                value: settings.audioCues,
                onChanged: (value) => _edit(ProfileSetting.audioCues, value),
                activeThumbColor: colors.accent,
              ),
              if (settings.audioCues)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 6, children: [Text('Cue Frequency',
                        style: AppTextStyles.bodyLargeBold(
                          color: colors.textPrimary,
                        ),
                      ),
                      DropdownButton<double>(
                        value: settings.cueFrequency,
                        dropdownColor: colors.surface,
                        style: AppTextStyles.bodyLarge(
                          color: colors.textPrimary,
                        ),
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(
                            value: 1.0,
                            child: Text(
                              'Every 1 $distanceUnit',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 0.5,
                            child: Text(
                              'Every 0.5 $distanceUnit',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            _edit(ProfileSetting.cueFrequency, value);
                        },
                      ),
                    ],
                  ),
                ),
              ListTile(
                title: Text(
                  'Monthly Rest Days',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  '${settings.restDays} days/month',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onTap: _updateRestDays,
              ),
            ], colors),

            _buildSectionHeader('AI CONFIGURATION', colors),
            _buildSectionGroup([const AiConfigurationPanel()], colors),

            _buildSectionHeader('DATA MANAGEMENT', colors),
            _buildSectionGroup([
              DataManagementPanel(
                onRestored: () async =>
                    context.read<ProfileBloc>().add(const ReloadProfile()),
                onExportComplete: () {
                  context.read<HapticsCubit>().mediumImpact();
                  context.read<AudioCubit>().playToggleSwitch();
                },
              ),
            ], colors),

            _buildSectionHeader('APP PREFERENCES', colors),
            _buildSectionGroup([
              SwitchListTile(
                title: Text(
                  'Retro UI Sounds',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Play 8-bit sound effects.',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                value: context.watch<AudioCubit>().state,
                onChanged: _toggleUiSounds,
                activeThumbColor: colors.accent,
              ),
              SwitchListTile(
                title: Text(
                  'Haptic Feedback',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Vibrate on UI interactions.',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                value: context.watch<HapticsCubit>().state,
                onChanged: _toggleHaptics,
                activeThumbColor: colors.accent,
              ),
              ListTile(
                title: Text(
                  'App Theme',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                trailing: ThemeSwitcher(
                  builder: (context) => ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.37), child: DropdownButton<ThemeMode>(isExpanded: true,
                    value: themeMode,
                    dropdownColor: colors.surface,
                    style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<ThemeModeCubit>().setMode(mode);
                        final isDark =
                            mode == ThemeMode.dark ||
                            (mode == ThemeMode.system &&
                                WidgetsBinding
                                        .instance
                                        .platformDispatcher
                                        .platformBrightness ==
                                    Brightness.dark);
                        final newTheme = isDark
                            ? AppThemes.darkTheme
                            : AppThemes.lightTheme;

                        if (isDark) {
                          context.read<AudioCubit>().playThemeDark();
                        } else {
                          context.read<AudioCubit>().playThemeLight();
                        }

                        ThemeSwitcher.of(context).changeTheme(theme: newTheme);
                      }
                    },
                  )),
                ),
              ),
              ListTile(
                leading: Icon(PhosphorIcons.sparkleFill, color: colors.accent),
                title: Text(
                  'App Tour & Features',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Revisit the onboarding guide & feature overview.',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
                trailing: Icon(
                  PhosphorIcons.caretRight,
                  color: colors.textSecondary,
                ),
                onTap: () {
                  context.read<HapticsCubit>().lightImpact();
                  AppNavigator.push(
                    context,
                    AppNavigator.materialPageRoute(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  );
                },
              ),
            ], colors),
          ],
        ),
      ),
    );
  }
}

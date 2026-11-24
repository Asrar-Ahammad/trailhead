import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../haptics/application/haptics_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../audio/application/sound_service.dart';
import '../../../main.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../../shared/theme/app_themes.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import '../../shoes/presentation/shoe_management_screen.dart';
import '../../ai/application/ai_config_provider.dart';
import '../../ai/application/ai_client.dart';
import '../../data_management/application/data_export_service.dart';
import '../../data_management/application/data_import_service.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

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
  String? _userDob; // ISO8601 string
  String? _userGender;

  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _isTestingApiKey = false;
  AiTestResult? _lastAiTestResult;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final aiConfig = ref.read(aiConfigProvider);
    _apiKeyController.text = aiConfig.apiKey;

    setState(() {
      _uiSoundsEnabled = prefs.getBool('ui_sounds_enabled') ?? false;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
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
              onPressed: () => Navigator.of(context).pop('CLEAR'),
              child: Text('Reset to Not set', style: TextStyle(color: colors.error)),
            ),
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
        title: Text('Gender', style: AppTextStyles.title(color: colors.textPrimary)),
        children: ['Male', 'Female', 'Prefer not to say'].map((g) => SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(g),
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

  Future<void> _testApiKey() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter an API key first.',
              style: AppTextStyles.bodyMedium(color: colors.background),
            ),
            backgroundColor: colors.warning,
          ),
        );
      }
      return;
    }

    await ref.read(aiConfigProvider.notifier).updateConfig(apiKey: key);
    final currentConfig = ref.read(aiConfigProvider);

    setState(() {
      _isTestingApiKey = true;
      _lastAiTestResult = null;
    });

    final client = AiClient(currentConfig);
    final result = await client.testConnection();

    if (!mounted) return;

    setState(() {
      _isTestingApiKey = false;
      _lastAiTestResult = result;
    });

    if (result.success) {
      ref.read(hapticsServiceProvider).lightImpact();
    } else {
      ref.read(hapticsServiceProvider).mediumImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: AppTextStyles.bodyMedium(color: colors.background),
        ),
        backgroundColor: result.success ? colors.success : colors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveBackupToDownloads() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    try {
      ref.read(hapticsServiceProvider).lightImpact();
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted && !status.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      }

      final exportService = DataExportService(isarInstance);
      final file = await exportService.saveBackupToDownloads();
      ref.read(hapticsServiceProvider).mediumImpact();
      ref.read(soundServiceProvider).playToggleSwitch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.success,
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                Icon(PhosphorIcons.checkCircleFill, color: colors.surface, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved to Downloads:\n${file.path.split('/').last}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.surface,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'SHARE',
              textColor: colors.surface,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.error,
            content: Text('Failed to save to Downloads: $e', style: TextStyle(color: colors.background)),
          ),
        );
      }
    }
  }

  Future<void> _exportAllGpxToDownloads() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    try {
      ref.read(hapticsServiceProvider).lightImpact();
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted && !status.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      }

      final exportService = DataExportService(isarInstance);
      final count = await exportService.exportAllRunsGpxToDownloads();
      ref.read(hapticsServiceProvider).mediumImpact();
      ref.read(soundServiceProvider).playToggleSwitch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.success,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(PhosphorIcons.checkCircleFill, color: colors.surface, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count > 0
                        ? 'Saved $count GPX routes to Downloads/Trailhead_GPX/'
                        : 'No completed GPS runs found to export.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.error,
            content: Text('Failed to export GPX: $e', style: TextStyle(color: colors.background)),
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    try {
      final exportService = DataExportService(isarInstance);
      final file = await exportService.exportData();
      await Share.shareXFiles([XFile(file.path)], text: 'Trailhead Data Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e', style: TextStyle(color: colors.background))),
        );
      }
    }
  }

  Future<void> _importData() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text('Import Option', style: AppTextStyles.title(color: colors.textPrimary)),
            content: Text('Do you want to overwrite your existing local data, or merge?', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Merge', style: TextStyle(color: colors.accent)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Overwrite', style: TextStyle(color: colors.error)),
              ),
            ],
          ),
        ) ?? false;

        final importService = DataImportService(isarInstance);
        final importResult = await importService.importData(file, clearExisting: shouldClear);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                importResult.success 
                    ? 'Successfully imported ${importResult.runs} runs and ${importResult.shoes} shoes!'
                    : 'Import failed: ${importResult.message}',
                style: TextStyle(color: colors.background),
              ),
              backgroundColor: importResult.success ? colors.accent : colors.error,
            ),
          );
          if (importResult.success) {
            _loadSettings();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import data: $e', style: TextStyle(color: colors.background))),
        );
      }
    }
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
    final themeMode = ref.watch(themeModeProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    
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
                ref.read(hapticsServiceProvider).lightImpact();
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
                        DropdownMenuItem(value: 1.0, child: Text('Every 1 ${ref.watch(distanceUnitProvider) ? 'mi' : 'km'}')),
                        DropdownMenuItem(value: 0.5, child: Text('Every 0.5 ${ref.watch(distanceUnitProvider) ? 'mi' : 'km'}')),
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
          _buildSectionGroup([
            ListTile(
              title: Text('AI Provider', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              trailing: DropdownButton<String>(
                value: aiConfig.provider,
                dropdownColor: colors.surface,
                style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                  DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                  DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    final defaultModel = val == 'openai'
                        ? 'gpt-5'
                        : (val == 'gemini' ? 'gemini-3.8-flash' : 'claude-5-sonnet');
                    ref.read(aiConfigProvider.notifier).updateConfig(provider: val, model: defaultModel);
                  }
                },
              ),
            ),
            ListTile(
              title: Text('AI Model', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              trailing: DropdownButton<String>(
                value: aiConfig.model,
                dropdownColor: colors.surface,
                style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                underline: const SizedBox.shrink(),
                items: () {
                  final List<DropdownMenuItem<String>> list;
                  if (aiConfig.provider == 'openai') {
                    list = const [
                      DropdownMenuItem(value: 'gpt-5', child: Text('gpt-5')),
                      DropdownMenuItem(value: 'gpt-5-mini', child: Text('gpt-5-mini')),
                      DropdownMenuItem(value: 'gpt-5-pro', child: Text('gpt-5-pro')),
                      DropdownMenuItem(value: 'gpt-4o', child: Text('gpt-4o')),
                      DropdownMenuItem(value: 'o3-mini', child: Text('o3-mini')),
                    ];
                  } else if (aiConfig.provider == 'gemini') {
                    list = const [
                      DropdownMenuItem(value: 'gemini-3.8-flash', child: Text('gemini-3.8-flash')),
                      DropdownMenuItem(value: 'gemini-3.8-flash-lite', child: Text('gemini-3.8-flash-lite')),
                      DropdownMenuItem(value: 'gemini-3.8-pro', child: Text('gemini-3.8-pro')),
                      DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('gemini-2.0-flash')),
                      DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('gemini-1.5-pro')),
                    ];
                  } else {
                    list = const [
                      DropdownMenuItem(value: 'claude-5-sonnet', child: Text('claude-5-sonnet')),
                      DropdownMenuItem(value: 'claude-5-opus', child: Text('claude-5-opus')),
                      DropdownMenuItem(value: 'claude-4-5-haiku', child: Text('claude-4-5-haiku')),
                      DropdownMenuItem(value: 'claude-3-7-sonnet', child: Text('claude-3-7-sonnet')),
                      DropdownMenuItem(value: 'claude-3-5-sonnet', child: Text('claude-3-5-sonnet')),
                      DropdownMenuItem(value: 'claude-3-5-haiku', child: Text('claude-3-5-haiku')),
                    ];
                  }
                  if (!list.any((item) => item.value == aiConfig.model)) {
                    return [
                      ...list,
                      DropdownMenuItem(value: aiConfig.model, child: Text(aiConfig.model)),
                    ];
                  }
                  return list;
                }(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(aiConfigProvider.notifier).updateConfig(model: val);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _apiKeyController,
                obscureText: _apiKeyObscured,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
                  suffixIcon: IconButton(
                    icon: Icon(_apiKeyObscured ? Icons.visibility_off : Icons.visibility, color: colors.textSecondary),
                    onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                  ),
                ),
                onChanged: (val) {
                  ref.read(aiConfigProvider.notifier).updateConfig(apiKey: val.trim());
                },
              ),
            ),
            ListTile(
              leading: Icon(
                _lastAiTestResult == null
                    ? PhosphorIcons.lightning
                    : (_lastAiTestResult!.success
                        ? PhosphorIcons.checkCircle
                        : PhosphorIcons.warningCircle),
                color: _lastAiTestResult == null
                    ? colors.accent
                    : (_lastAiTestResult!.success ? colors.success : colors.error),
                size: 20,
              ),
              title: Text(
                'Test API Key',
                style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
              ),
              subtitle: Text(
                _isTestingApiKey
                    ? 'Testing connection...'
                    : (_lastAiTestResult != null
                        ? _lastAiTestResult!.message
                        : 'Verify credentials with provider'),
                style: AppTextStyles.bodyMedium(
                  color: _lastAiTestResult != null
                      ? (_lastAiTestResult!.success ? colors.success : colors.error)
                      : colors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _isTestingApiKey
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accent,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Test',
                        style: AppTextStyles.label(color: colors.accent),
                      ),
                    ),
              onTap: _isTestingApiKey ? null : _testApiKey,
            ),
          ], colors),

          _buildSectionHeader('DATA MANAGEMENT', colors),
          _buildSectionGroup([
            ListTile(
              title: Text('Save Backup to Downloads', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Save JSON database backup directly to your local Downloads folder.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.download, color: colors.accent, size: 22),
              onTap: _saveBackupToDownloads,
            ),
            ListTile(
              title: Text('Export All Routes (GPX) to Downloads', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Save all GPS runs as .gpx files to Downloads/Trailhead_GPX/.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.path, color: colors.textSecondary, size: 20),
              onTap: _exportAllGpxToDownloads,
            ),
            ListTile(
              title: Text('Share Backup File', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Share JSON backup via Drive, AirDrop, or messaging apps.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.shareNetwork, color: colors.textSecondary, size: 20),
              onTap: _exportData,
            ),
            ListTile(
              title: Text('Import Local Data', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Restore runs, shoes, & goals from a JSON backup file.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.upload, color: colors.textSecondary, size: 20),
              onTap: _importData,
            ),
          ], colors),

          _buildSectionHeader('APP PREFERENCES', colors),
          _buildSectionGroup([
            SwitchListTile(
              title: Text('Retro UI Sounds', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Play 8-bit sound effects.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              value: _uiSoundsEnabled,
              onChanged: _toggleUiSounds,
              activeColor: colors.accent,
            ),
            SwitchListTile(
              title: Text('Haptic Feedback', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Vibrate on UI interactions.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              value: _hapticsEnabled,
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
            ListTile(
              leading: Icon(PhosphorIcons.sparkleFill, color: colors.accent),
              title: Text('App Tour & Features', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Revisit the onboarding guide & feature overview.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: Icon(PhosphorIcons.caretRight, color: colors.textSecondary),
              onTap: () {
                ref.read(hapticsServiceProvider).lightImpact();
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

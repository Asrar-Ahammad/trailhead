import '../state_management/run_tracking_bloc_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../profile/presentation/settings_screen.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import '../../navigation/presentation/navigation_scaffold_main_tabs.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/retro_loading_indicator.dart';
import '../../../shared/theme/app_colors.dart';

class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateRunPermissionsBloc>()(),
    child: const _PermissionGateContent(),
  );
}

class _PermissionGateContent extends StatefulWidget {
  const _PermissionGateContent();
  @override
  State<_PermissionGateContent> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<_PermissionGateContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check permission status on startup; if already granted, skip the gate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPermissionsAndNavigate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app lifecycle changes. Re-check permissions on resume
  /// so the gate dismisses automatically if the user granted access in the
  /// system settings and then returned to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RunTrackerCubit>().recheckPermissions();
    }
  }

  void _checkPermissionsAndNavigate() {
    final state = context.read<RunTrackerCubit>().state;
    if (state.permissionsGranted) {
      AppNavigator.replace(context,
        AppNavigator.materialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<RunPermissionsBloc>().state;
    final requestingForeground = permission.pending == RunPermissionRequest.foreground;
    final requestingBackground = permission.pending == RunPermissionRequest.background;
    final error = permission.error;
    final trackerState = context.watch<RunTrackerCubit>().state;
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    if (!trackerState.permissionsChecked) {
      return Scaffold(
        backgroundColor: retroColors.background,
        body: const Center(child: RetroLoadingIndicator(text: 'INITIALIZING')),
      );
    }

    return Scaffold(
      backgroundColor: retroColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // App logo/name
              // App logo/name and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance for settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.navigationArrowFill,
                        color: retroColors.accent,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRAILHEAD',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: retroColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.gear, color: retroColors.textPrimary),
                    onPressed: () {
                      AppNavigator.push(context,
                        AppNavigator.materialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Informational card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: retroColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: retroColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(
                        PhosphorIcons.shieldCheckBold,
                        color: retroColors.accent,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Permissions Required',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: retroColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Trailhead requires these permissions to work perfectly:\n\n• Location: To accurately map your route and calculate your pace.\n• Background Location: To keep tracking even when your screen is locked.\n• Physical Activity: To count your steps and track your cadence.\n• Notifications: To send you important milestone alerts and audio cues.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: retroColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: retroColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Permission actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PressableScale(
                    onTap: permission.pending != null ? null : () => context.read<RunPermissionsBloc>().add(RunPermissionRequest.foreground),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: retroColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: requestingForeground
                          ? const RetroLoadingIndicator(text: 'REQUESTING')
                          : Text(
                              '1. Grant Required Permissions',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PressableScale(
                    onTap: permission.pending != null ? null : () => context.read<RunPermissionsBloc>().add(RunPermissionRequest.background),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: retroColors.accent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: requestingBackground
                          ? const RetroLoadingIndicator(text: 'REQUESTING')
                          : Text(
                              '2. Allow Background Tracking',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: retroColors.accent,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: Please select "Allow all the time" in the system settings dialog for background tracking to work.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: retroColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

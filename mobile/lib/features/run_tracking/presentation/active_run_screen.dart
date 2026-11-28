import 'widgets/run_tracking_widget_location_button.dart';
import 'widgets/run_tracking_widget_stop_sheet.dart';
import 'widgets/run_tracking_widget_actions.dart';
import 'widgets/run_tracking_widget_live_stats.dart';
import '../state_management/run_tracking_bloc_workout_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'dart:ui';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import '../application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'post_run_summary_screen.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/live_run_map.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/app_spacing.dart';

/// Active run screen — shows live map, hero stats, and playback controls.
///
/// All formatting delegated to [RunFormatUtils].
/// All colors sourced from [AppColors] via ThemeExtension.
/// All spacing uses [AppSpacing] constants.
class ActiveRunScreen extends StatelessWidget {
  const ActiveRunScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateWorkoutActionsBloc>()(),
    child: BlocListener<WorkoutActionsBloc, WorkoutActionState>(
      listener: (context, state) {
        if (state.workout case final workout?) {
          AppNavigator.push(
            context,
            AppNavigator.materialPageRoute(
              builder: (_) => PostRunSummaryScreen(
                run: workout.run,
                points: workout.points,
              ),
            ),
          );
        } else if (state.error case final error?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: Builder(builder: _buildActiveRun),
    ),
  );

  Widget _buildActiveRun(BuildContext context) {
    final trackerState = context.watch<RunTrackerCubit>().state;
    final colors = Theme.of(context).extension<AppColors>()!;

    if (!trackerState.permissionsChecked) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background Map (Shifted up to center point above cards)
          Positioned(
            top: -300,
            bottom: 0,
            left: 0,
            right: 0,
            child: LiveRunMap(
              initialLocation: trackerState.initialPosition != null
                  ? LatLng(
                      trackerState.initialPosition!.latitude,
                      trackerState.initialPosition!.longitude,
                    )
                  : null,
            ),
          ),

          // Floating Elements overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top area: GPS warning (if any)
                if (trackerState.gpsWeak)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.warningBold,
                            color: colors.background,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'NO GPS SIGNAL',
                              style: AppTextStyles.labelCaps(
                                color: colors.background,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Bottom area: Stats card + Controls sheet
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location Button
                        RunLocationButton(colors: colors),
                        RunLiveStats(
                          trackerState: trackerState,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                        RunActionControls(
                          trackerState: trackerState,
                          colors: colors,
                          onStop: () {
                            context.read<RunTrackerCubit>().pauseRun();
                            _showStopSheet(
                              context,
                              colors,
                              trackerState.activityType,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStopSheet(
    BuildContext context,
    AppColors colors,
    String activityType,
  ) async {
    final result = await AppNavigator.bottomSheet<String>(
      context,
      (ctx) => RunStopSheet(colors: colors, activityType: activityType),
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    );

    if (!context.mounted) return;

    final notifier = context.read<RunTrackerCubit>();
    final audio = context.read<AudioCubit>();

    if (result == 'save') {
      audio.playRunFinish();
      context.read<WorkoutActionsBloc>().add(WorkoutAction.finish);
    } else if (result == 'discard') {
      final confirm = await AppNavigator.dialog<bool>(
        context,
        (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Discard $activityType?',
            style: AppTextStyles.title(color: colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to discard this ${activityType.toLowerCase()}? This action cannot be undone.',
            style: AppTextStyles.bodyMedium(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => AppNavigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyLarge(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => AppNavigator.pop(ctx, true),
              child: Text(
                'Discard',
                style: AppTextStyles.bodyLargeBold(color: colors.error),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        audio.playRunDiscard();
        notifier.discardRun();
      } else {
        audio.playPauseResume();
        notifier.resumeRun();
      }
    } else {
      // Dismissed or 'resume' — resume tracking
      audio.playPauseResume();
      notifier.resumeRun();
    }
  }
}

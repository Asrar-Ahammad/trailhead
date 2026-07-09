import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../application/run_tracker_controller.dart';
import '../application/run_format_utils.dart';
import '../application/route_provider.dart';
import '../application/location_service_task.dart';
import '../../audio/application/sound_service.dart';
import 'permission_gate_screen.dart';
import 'post_run_summary_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/live_run_map.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/app_spacing.dart';

/// Active run screen — shows live map, hero stats, and playback controls.
///
/// All formatting delegated to [RunFormatUtils].
/// All colors sourced from [AppColors] via ThemeExtension.
/// All spacing uses [AppSpacing] constants.
class ActiveRunScreen extends ConsumerWidget {
  const ActiveRunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(runTrackerProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    // Redirect to permission gate if permissions are lost
    if (!trackerState.permissionsGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PermissionGateScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // GPS weak banner
            if (trackerState.gpsWeak) _GpsWeakBanner(colors: colors),

            // Top status bar
            _StatusBar(trackerState: trackerState, colors: colors),

            // Live map — 40% of available height
            Expanded(
              flex: 4,
              child: LiveRunMap(
                initialLocation: trackerState.initialPosition != null 
                    ? LatLng(trackerState.initialPosition!.latitude, trackerState.initialPosition!.longitude)
                    : null,
              ),
            ),

            // Stats panel
            Expanded(
              flex: 5,
              child: _StatPanel(trackerState: trackerState, colors: colors),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: _RunControls(
                trackerState: trackerState,
                colors: colors,
                onStop: () {
                  ref.read(runTrackerProvider.notifier).pauseRun();
                  _showStopSheet(context, ref, colors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopSheet(BuildContext context, WidgetRef ref, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _StopBottomSheet(colors: colors, ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets — one logical block each, kept private to this feature
// ---------------------------------------------------------------------------

class _GpsWeakBanner extends StatelessWidget {
  const _GpsWeakBanner({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.warning,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.bold),
            color: colors.background,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'GPS SIGNAL WEAK',
            style: AppTextStyles.labelCaps(color: colors.background),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  Color _statusColor() {
    switch (trackerState.status) {
      case 'running':
        return colors.success;
      case 'paused':
        return colors.warning;
      default:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            trackerState.status.toUpperCase(),
            style: AppTextStyles.labelCaps(color: _statusColor()),
          ),
          if (trackerState.status != 'idle')
            Row(
              children: [
                Icon(
                  PhosphorIcons.footprints(PhosphorIconsStyle.fill),
                  color: colors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${trackerState.stepCount}',
                  style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}



class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero distance
          Text(
            RunFormatUtils.formatDistanceKm(trackerState.distanceM),
            style: AppTextStyles.displayHero(color: colors.textPrimary),
          ),
          Text(
            'KILOMETERS',
            style: AppTextStyles.labelCaps(color: colors.textSecondary),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Duration | Pace row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      RunFormatUtils.formatDuration(trackerState.durationS),
                      style: AppTextStyles.displayStat(color: colors.textPrimary),
                    ),
                    Text(
                      'TIME',
                      style: AppTextStyles.labelCaps(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: colors.border,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      trackerState.currentSplitPaceSPerKm != null
                          ? '${(trackerState.currentSplitPaceSPerKm! / 60).floor()}:${(trackerState.currentSplitPaceSPerKm! % 60).toString().padLeft(2, '0')}'
                          : RunFormatUtils.formatPace(trackerState.distanceM, trackerState.durationS),
                      style: AppTextStyles.displayStat(
                        color: _getPaceColor(trackerState, colors),
                      ),
                    ),
                    Text(
                      trackerState.currentSplitPaceSPerKm != null ? 'SPLIT PACE' : 'AVG PACE /KM',
                      style: AppTextStyles.labelCaps(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaceColor(RunTrackerState trackerState, AppColors colors) {
    if (trackerState.targetPaceSPerKm == null || trackerState.currentSplitPaceSPerKm == null) {
      return colors.textPrimary;
    }
    if (trackerState.currentSplitPaceSPerKm! <= trackerState.targetPaceSPerKm!) {
      return colors.accent; // Green/Accent - Ahead or on pace
    } else {
      return colors.error; // Red/Coral - Behind pace
    }
  }
}

class _RunControls extends StatelessWidget {
  const _RunControls({
    required this.trackerState,
    required this.colors,
    required this.onStop,
  });

  final RunTrackerState trackerState;
  final AppColors colors;
  final VoidCallback onStop;

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final notifier = ref.read(runTrackerProvider.notifier);
        final status = trackerState.status;
        final isIdle = status == 'idle';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isIdle
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: _TargetPaceSelector(
                        trackerState: trackerState,
                        colors: colors,
                        notifier: notifier,
                        ref: ref,
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                const double spacing = 16.0;
                final double halfWidth = (width - spacing) / 2;
                final isPaused = status == 'paused';

                return SizedBox(
                  height: 64,
                  child: Stack(
                    children: [
                      // Left Button (Start / Pause / Resume)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: isIdle ? 0 : halfWidth + spacing,
                        child: PressableScale(
                          onTap: () {
                            if (isIdle) {
                              ref.read(soundServiceProvider).playRunStart();
                              notifier.startRun();
                            } else if (isPaused) {
                              ref.read(soundServiceProvider).playPauseResume();
                              notifier.resumeRun();
                            } else {
                              ref.read(soundServiceProvider).playPauseResume();
                              notifier.pauseRun();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isIdle || isPaused ? colors.accent : colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isIdle || isPaused ? colors.accent : colors.border,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isIdle ? 'START RUN' : (isPaused ? 'RESUME' : 'PAUSE'),
                                style: AppTextStyles.bodyLargeBold(
                                  color: isIdle || isPaused ? Colors.white : colors.textPrimary,
                                ).copyWith(letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Right Button (Stop)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        left: isIdle ? width : halfWidth + spacing,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isIdle ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: isIdle,
                            child: PressableScale(
                              onTap: onStop,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'STOP',
                                    style: AppTextStyles.bodyLargeBold(color: Colors.white).copyWith(letterSpacing: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TargetPaceSelector extends StatelessWidget {
  const _TargetPaceSelector({
    required this.trackerState,
    required this.colors,
    required this.notifier,
    required this.ref,
  });

  final RunTrackerState trackerState;
  final AppColors colors;
  final RunTrackerController notifier;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final currentPace = trackerState.targetPaceSPerKm;
    final String paceStr = currentPace != null 
        ? '${(currentPace / 60).floor()}:${(currentPace % 60).toString().padLeft(2, '0')} /km'
        : 'Set Target Pace';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(PhosphorIcons.minus(), color: colors.textPrimary),
            onPressed: () {
              ref.read(hapticsServiceProvider).lightImpact();
              final newPace = (currentPace ?? 360) + 10; // Slower pace = more seconds
              notifier.setTargetPace(newPace);
            },
          ),
          const SizedBox(width: 8),
          Text(
            paceStr,
            style: AppTextStyles.bodyLarge(color: colors.textPrimary),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(PhosphorIcons.plus(), color: colors.textPrimary),
            onPressed: () {
              ref.read(hapticsServiceProvider).lightImpact();
              final newPace = (currentPace ?? 360) - 10; // Faster pace = less seconds
              if (newPace > 0) notifier.setTargetPace(newPace);
            },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.size,
    required this.color,
    required this.child,
    this.borderColor,
  });

  final double size;
  final Color color;
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _StopBottomSheet extends StatelessWidget {
  const _StopBottomSheet({required this.colors, required this.ref});

  final AppColors colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(runTrackerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Finish Workout?',
              style: AppTextStyles.headline(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Resume
            PressableScale(
              onTap: () {
                Navigator.pop(context);
                ref.read(soundServiceProvider).playPauseResume();
                notifier.resumeRun();
              },
              child: _SheetButton(
                label: 'Resume Tracking',
                backgroundColor: colors.surfaceRaised,
                textColor: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Save
            PressableScale(
              onTap: () async {
                Navigator.pop(context);
                ref.read(soundServiceProvider).playRunFinish();
                
                // Fetch points before stopping the run (which clears the tracker state)
                final pointsAsync = ref.read(routePointsProvider);
                final points = pointsAsync.valueOrNull ?? [];

                final savedRun = await notifier.stopRun();
                if (savedRun != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostRunSummaryScreen(
                        run: savedRun,
                        points: points,
                      ),
                    ),
                  );
                }
              },
              child: _SheetButton(
                label: 'Finish & Save',
                backgroundColor: colors.accent,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Discard
            PressableScale(
              onTap: () {
                Navigator.pop(context);
                notifier.discardRun();
              },
              child: _SheetButton(
                label: 'Discard Run',
                backgroundColor: Colors.transparent,
                textColor: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.bodyLargeBold(color: textColor),
      ),
    );
  }
}

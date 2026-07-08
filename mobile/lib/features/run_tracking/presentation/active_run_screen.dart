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
              child: trackerState.status != 'idle'
                  ? const LiveRunMap()
                  : _IdleMapPlaceholder(colors: colors),
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

class _IdleMapPlaceholder extends StatelessWidget {
  const _IdleMapPlaceholder({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.mapTrifold(PhosphorIconsStyle.regular),
            color: colors.textDisabled,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Map shows once tracking starts',
            style: AppTextStyles.bodyMedium(color: colors.textDisabled),
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
                      RunFormatUtils.formatPace(
                        trackerState.distanceM,
                        trackerState.durationS,
                      ),
                      style: AppTextStyles.displayStat(color: colors.textPrimary),
                    ),
                    Text(
                      'PACE /KM',
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
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final notifier = ref.read(runTrackerProvider.notifier);

        if (trackerState.status == 'idle') {
          return Center(
            child: PressableScale(
              onTap: () {
                ref.read(soundServiceProvider).playRunStart();
                notifier.startRun();
              },
              child: _CircleButton(
                size: 72,
                color: colors.accent,
                child: Icon(
                  PhosphorIcons.play(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          );
        }

        if (trackerState.status == 'running') {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PressableScale(
                onTap: () {
                  ref.read(soundServiceProvider).playPauseResume();
                  notifier.pauseRun();
                },
                child: _CircleButton(
                  size: 72,
                  color: colors.surface,
                  borderColor: colors.border,
                  child: Icon(
                    PhosphorIcons.pause(PhosphorIconsStyle.fill),
                    color: colors.textPrimary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              PressableScale(
                onTap: onStop,
                child: _CircleButton(
                  size: 72,
                  color: colors.error,
                  child: Icon(
                    PhosphorIcons.stop(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          );
        }

        if (trackerState.status == 'paused') {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PressableScale(
                onTap: () {
                  ref.read(soundServiceProvider).playPauseResume();
                  notifier.resumeRun();
                },
                child: _CircleButton(
                  size: 72,
                  color: colors.accent,
                  child: Icon(
                    PhosphorIcons.play(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              PressableScale(
                onTap: onStop,
                child: _CircleButton(
                  size: 72,
                  color: colors.error,
                  child: Icon(
                    PhosphorIcons.stop(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
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
                final savedRun = await notifier.stopRun();
                if (savedRun != null && context.mounted) {
                  final pointsAsync = ref.read(routePointsProvider);
                  final points = pointsAsync.valueOrNull ?? [];
                  Navigator.of(context).pushReplacement(
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../application/run_tracker_controller.dart';
import '../application/run_format_utils.dart';
import '../application/route_provider.dart';
import '../../audio/application/sound_service.dart';
import 'post_run_summary_screen.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/live_run_map.dart';
import 'widgets/countdown_overlay.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../shoes/application/shoe_service.dart';
import '../../shoes/presentation/shoe_management_screen.dart';
import '../../shoes/data/models/shoe_isar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  ? LatLng(trackerState.initialPosition!.latitude, trackerState.initialPosition!.longitude)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.warningBold, color: colors.background, size: 16),
                          const SizedBox(width: 8),
                          Text('NO GPS SIGNAL', style: AppTextStyles.labelCaps(color: colors.background)),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Bottom area: Stats card + Controls sheet
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Button
                    _LocationButton(colors: colors),
                    _StatPanel(trackerState: trackerState, colors: colors),
                    const SizedBox(height: 16),
                    _RunControls(
                      trackerState: trackerState,
                      colors: colors,
                      onStop: () {
                        ref.read(runTrackerProvider.notifier).pauseRun();
                        _showStopSheet(context, ref, colors, trackerState.activityType);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStopSheet(BuildContext context, WidgetRef ref, AppColors colors, String activityType) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => _StopBottomSheet(colors: colors, activityType: activityType),
    );

    debugPrint('[SAVE_DEBUG] Bottom sheet returned: $result');
    debugPrint('[SAVE_DEBUG] context.mounted: ${context.mounted}');

    if (!context.mounted) return;

    final notifier = ref.read(runTrackerProvider.notifier);

    if (result == 'save') {
      debugPrint('[SAVE_DEBUG] Starting save flow...');
      ref.read(soundServiceProvider).playRunFinish();

      // Read points BEFORE stopping the run (while ref is still valid)
      final pointsAsync = ref.read(routePointsProvider);
      final points = pointsAsync.valueOrNull ?? [];
      debugPrint('[SAVE_DEBUG] Points count: ${points.length}');

      try {
        final savedRun = await notifier.stopRun();
        debugPrint('[SAVE_DEBUG] stopRun returned: ${savedRun?.clientRunId}, status=${savedRun?.status}');
        debugPrint('[SAVE_DEBUG] context.mounted after stopRun: ${context.mounted}');
        if (savedRun != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostRunSummaryScreen(
                run: savedRun,
                points: points,
              ),
            ),
          );
        } else {
          debugPrint('[SAVE_DEBUG] Navigation skipped - savedRun: $savedRun, mounted: ${context.mounted}');
        }
      } catch (e, stack) {
        debugPrint('[SAVE_DEBUG] stopRun THREW: $e');
        debugPrint('[SAVE_DEBUG] Stack: $stack');
      }
    } else if (result == 'discard') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Discard $activityType?', style: AppTextStyles.title(color: colors.textPrimary)),
          content: Text('Are you sure you want to discard this ${activityType.toLowerCase()}? This action cannot be undone.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: AppTextStyles.bodyLarge(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Discard', style: AppTextStyles.bodyLargeBold(color: colors.error)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        ref.read(soundServiceProvider).playRunDiscard();
        notifier.discardRun();
      } else {
        ref.read(soundServiceProvider).playPauseResume();
        notifier.resumeRun();
      }
    } else {
      // Dismissed or 'resume' — resume tracking
      ref.read(soundServiceProvider).playPauseResume();
      notifier.resumeRun();
    }
  }
}

/// Shows a weight input sheet if the user hasn't set their weight yet.
/// After confirming (or skipping), runs the countdown overlay and starts the activity.
Future<void> _maybePromptWeightAndStart(
  BuildContext context,
  WidgetRef ref,
  AppColors colors,
  RunTrackerController notifier,
) async {
  final prefs = await SharedPreferences.getInstance();
  final existingWeight = prefs.getDouble('user_weight_kg');

  if (existingWeight == null && context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => _WeightInputSheet(colors: colors),
    );
  }

  // Once weight prompt is handled (or if weight already exists), run countdown then start run
  if (context.mounted) {
    await CountdownOverlay.show(context);
    ref.read(soundServiceProvider).playRunStart();
    notifier.startRun();
  }
}

// ---------------------------------------------------------------------------
// Weight Input Sheet — prompts user to enter weight for calorie accuracy
// ---------------------------------------------------------------------------

class _WeightInputSheet extends StatefulWidget {
  const _WeightInputSheet({required this.colors});
  final AppColors colors;

  @override
  State<_WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<_WeightInputSheet> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final weight = double.tryParse(text);
    if (weight == null || weight < 20 || weight > 300) {
      setState(() => _error = 'Enter a valid weight between 20–300 kg');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_weight_kg', weight);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
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
          const SizedBox(height: 24),

          // Icon + headline
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center_rounded, color: colors.accent, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Your Weight',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used to estimate calories burned during your activity. You can update this anytime in Settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Weight input field
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            autofocus: true,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '70',
              hintStyle: GoogleFonts.spaceGrotesk(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary.withValues(alpha: 0.4),
              ),
              suffixText: 'kg',
              suffixStyle: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.accent, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.error, width: 2),
              ),
              errorText: _error,
              fillColor: colors.surfaceRaised,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),

          // Save button
          GestureDetector(
            onTap: _saving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 54,
              decoration: BoxDecoration(
                color: _saving ? colors.accent.withValues(alpha: 0.6) : colors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _saving
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: colors.surface, strokeWidth: 2.5),
                    )
                  : Text(
                      'SAVE & START',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colors.surface,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                'Skip for now',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets — one logical block each, kept private to this feature
// ---------------------------------------------------------------------------

class _GpsWeakBanner extends ConsumerWidget {
  const _GpsWeakBanner({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    return Container(
      color: colors.warning,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warningBold,
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

class _StatusBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
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
                  PhosphorIcons.footprintsFill,
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



class _StatPanel extends ConsumerStatefulWidget {
  const _StatPanel({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  @override
  ConsumerState<_StatPanel> createState() => _StatPanelState();
}

class _StatPanelState extends ConsumerState<_StatPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final useMiles = ref.watch(distanceUnitProvider);
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0 && !_isExpanded) {
          // Swipe down
          setState(() => _isExpanded = true);
        } else if (details.primaryVelocity! < 0 && _isExpanded) {
          // Swipe up
          setState(() => _isExpanded = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.colors.surface.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.45,
                ), // Glass effect
                border: Border.all(
                  color: widget.colors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Icon(
                        _isExpanded ? PhosphorIcons.caretDownBold : PhosphorIcons.caretUpBold,
                        color: widget.colors.textSecondary.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Time
                        _StatColumn(
                          value: RunFormatUtils.formatDuration(widget.trackerState.durationS),
                          label: 'Time',
                          colors: widget.colors,
                        ),
                        
                        // Pace
                        _StatColumn(
                          value: widget.trackerState.currentSplitPaceSPerKm != null
                              ? '${(widget.trackerState.currentSplitPaceSPerKm! / 60).floor()}:${(widget.trackerState.currentSplitPaceSPerKm! % 60).toString().padLeft(2, '0')}'
                              : RunFormatUtils.formatPace(widget.trackerState.distanceM, widget.trackerState.durationS, useMiles),
                          label: widget.trackerState.currentSplitPaceSPerKm != null ? 'Split avg. (/km)' : 'Pace (/km)',
                          colors: widget.colors,
                          isCenter: true,
                        ),

                        // Distance
                        _StatColumn(
                          value: RunFormatUtils.formatDistance(widget.trackerState.distanceM, useMiles),
                          label: 'Distance (km)',
                          colors: widget.colors,
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Steps
                          _StatColumn(
                            value: widget.trackerState.stepCount.toString(),
                            label: 'Steps',
                            colors: widget.colors,
                          ),
                          
                          // Cadence
                          _StatColumn(
                            value: widget.trackerState.currentCadence > 0 ? widget.trackerState.currentCadence.toString() : '--',
                            label: 'Cadence (spm)',
                            colors: widget.colors,
                          ),

                          // Calories
                          _StatColumn(
                            value: widget.trackerState.caloriesKcal > 0 ? widget.trackerState.caloriesKcal.toString() : '--',
                            label: 'Calories',
                            colors: widget.colors,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends ConsumerWidget {
  const _StatColumn({required this.value, required this.label, required this.colors, this.isCenter = false});
  final String value;
  final String label;
  final AppColors colors;
  final bool isCenter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.displayStat(color: colors.textPrimary).copyWith(fontSize: 40),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaceComparisonBadge extends ConsumerWidget {
  const _PaceComparisonBadge({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    final target = trackerState.targetPaceSPerKm!;
    // Use split pace if available, else fall back to average pace
    final int? currentRaw = trackerState.currentSplitPaceSPerKm ??
        (trackerState.distanceM > 0 && trackerState.durationS > 0
            ? (trackerState.durationS / (trackerState.distanceM / 1000.0)).round()
            : null);

    if (currentRaw == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.timer, color: colors.textSecondary, size: 14),
            const SizedBox(width: 6),
            Text(
              'CALCULATING PACE…',
              style: AppTextStyles.labelCaps(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final int diffS = currentRaw - target; // negative = ahead, positive = behind
    final bool ahead = diffS <= -3;
    final bool behind = diffS >= 3;
    final bool onPace = !ahead && !behind;

    final Color badgeColor = ahead
        ? colors.accent
        : behind
            ? colors.error
            : const Color(0xFFF5A623); // amber for "on pace"

    final IconData icon = ahead
        ? Icons.arrow_upward_rounded
        : behind
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

    final String label = ahead ? 'AHEAD' : behind ? 'BEHIND' : 'ON PACE';

    final String diffLabel = onPace
        ? '± 0s/km'
        : '${diffS.abs()}s/km ${ahead ? 'faster' : 'slower'}';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: badgeColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelCaps(color: badgeColor),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 14, color: badgeColor.withOpacity(0.4)),
            const SizedBox(width: 8),
            Text(
              diffLabel,
              style: AppTextStyles.label(color: badgeColor),
            ),
          ],
        ),
      ),
    );
  }
}



class _RunControls extends ConsumerStatefulWidget {
  const _RunControls({
    required this.trackerState,
    required this.colors,
    required this.onStop,
  });

  final RunTrackerState trackerState;
  final AppColors colors;
  final VoidCallback onStop;

  @override
  ConsumerState<_RunControls> createState() => _RunControlsState();
}

class _RunControlsState extends ConsumerState<_RunControls> {

  @override
  Widget build(BuildContext context) {
    final useMiles = ref.watch(distanceUnitProvider);
    final trackerState = widget.trackerState;
    final colors = widget.colors;
    final onStop = widget.onStop;

    final notifier = ref.read(runTrackerProvider.notifier);
    final status = trackerState.status;
    final isIdle = status == 'idle';
    final isPaused = status == 'paused';

    final isRun = trackerState.activityType == 'run';

    return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.45,
                  ), // Glass effect
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isIdle) ...[
                _buildShoeSelector(context, ref, colors, trackerState),
                const SizedBox(height: 16),
              ],
              if (!isIdle) const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left Action (Activity Toggle or Stop)
                  _CircularAction(
                    icon: isIdle ? (isRun ? PhosphorIcons.personSimpleRun : PhosphorIcons.personSimpleWalk) : PhosphorIcons.stopFill,
                    label: isIdle ? (isRun ? 'Run' : 'Walk') : 'Stop',
                    color: colors.surface.withValues(alpha: 0.45),
                    iconColor: isIdle ? colors.accent : colors.error,
                    textColor: colors.textPrimary,
                    onTap: () {
                      if (isIdle) {
                        ref.read(hapticsServiceProvider).lightImpact();
                        notifier.setActivityType(isRun ? 'walk' : 'run');
                      } else {
                        onStop();
                      }
                    },
                  ),

                  // Center Action (Start / Pause / Resume)
                  PressableScale(
                    onTap: () {
                      if (isIdle) {
                        if (!trackerState.permissionsGranted) {
                          notifier.requestForegroundPermission().then((granted) {
                            if (granted) {
                              _maybePromptWeightAndStart(context, ref, colors, notifier);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location permission required to track runs.'),
                                  ),
                                );
                              }
                            }
                          });
                        } else {
                          _maybePromptWeightAndStart(context, ref, colors, notifier);
                        }
                      } else if (isPaused) {
                        ref.read(soundServiceProvider).playPauseResume();
                        notifier.resumeRun();
                      } else {
                        ref.read(soundServiceProvider).playPauseResume();
                        notifier.pauseRun();
                      }
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                              isIdle || isPaused ? PhosphorIcons.playFill : PhosphorIcons.pauseFill,
                              color: Colors.white,
                              size: 56,
                            ),
                    ),
                  ),

                  // Right Action (Target Pace)
                  _CircularAction(
                    icon: PhosphorIcons.target,
                    label: 'Pace',
                    color: colors.surface.withValues(alpha: 0.45),
                    iconColor: colors.textPrimary,
                    textColor: colors.textPrimary,
                    onTap: () {
                      if (isIdle) {
                        ref.read(hapticsServiceProvider).lightImpact();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withValues(alpha: 0.35),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          builder: (ctx) => _TargetPaceSelectorSheet(colors: colors),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildShoeSelector(BuildContext context, WidgetRef ref, AppColors colors, RunTrackerState state) {
    final activeShoesAsync = ref.watch(activeShoesProvider);
    return activeShoesAsync.when(
      data: (shoes) {
        if (shoes.isEmpty) {
          return GestureDetector(
            onTap: () {
              ref.read(hapticsServiceProvider).lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoeManagementScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.sneaker, color: colors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text('Add Gear', style: AppTextStyles.bodyMediumBold(color: colors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final selectedShoe = state.selectedShoeId != null
            ? shoes.cast<ShoeIsar?>().firstWhere((s) => s?.clientShoeId == state.selectedShoeId, orElse: () => null)
            : null;

        return GestureDetector(
          onTap: () {
            ref.read(hapticsServiceProvider).lightImpact();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              barrierColor: colors.background.withValues(alpha: 0.6),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (ctx) => _ShoeSelectorSheet(colors: colors, shoes: shoes, selectedShoeId: state.selectedShoeId),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedShoe != null && selectedShoe.imageUrl != null)
                  _buildShoeThumb(selectedShoe.imageUrl!, 20, colors.accent, colors)
                else
                  Icon(PhosphorIcons.sneaker, color: selectedShoe != null ? colors.accent : colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  selectedShoe != null ? selectedShoe.name! : 'Select Shoe',
                  style: AppTextStyles.bodyMediumBold(color: selectedShoe != null ? colors.textPrimary : colors.textSecondary),
                ),
                const SizedBox(width: 4),
                Icon(PhosphorIcons.caretDown, color: colors.textSecondary, size: 12),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CircularAction extends ConsumerWidget {
  const _CircularAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TargetPaceSelector extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    final currentPace = trackerState.targetPaceSPerKm;
    final String paceStr = currentPace != null 
        ? '${(currentPace / 60).floor()}:${(currentPace % 60).toString().padLeft(2, '0')} /km'
        : 'Set Target Pace';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(PhosphorIcons.minus, color: colors.textPrimary),
            onPressed: () {
              ref.read(hapticsServiceProvider).lightImpact();
              ref.read(soundServiceProvider).playPaceDown();
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
            icon: Icon(PhosphorIcons.plus, color: colors.textPrimary),
            onPressed: () {
              ref.read(hapticsServiceProvider).lightImpact();
              ref.read(soundServiceProvider).playPaceUp();
              final newPace = (currentPace ?? 360) - 10; // Faster pace = less seconds
              if (newPace > 0) notifier.setTargetPace(newPace);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityTypeSelector extends ConsumerWidget {
  const _ActivityTypeSelector({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    final isRun = trackerState.activityType == 'run';

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: isRun ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildSegment(
                  title: 'Run',
                  icon: PhosphorIcons.personSimpleRun,
                  isSelected: isRun,
                  onTap: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    ref.read(soundServiceProvider).playSwitchRun();
                    notifier.setActivityType('run');
                  },
                ),
              ),
              Expanded(
                child: _buildSegment(
                  title: 'Walk',
                  icon: PhosphorIcons.personSimpleWalk,
                  isSelected: !isRun,
                  onTap: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    ref.read(soundServiceProvider).playSwitchWalk();
                    notifier.setActivityType('walk');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyLargeBold(
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
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

class _StopBottomSheet extends ConsumerWidget {
  const _StopBottomSheet({required this.colors, required this.activityType});

  final AppColors colors;
  final String activityType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    final activityStr = activityType.toLowerCase() == 'walk' ? 'Walk' : 'Run';
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
              onTap: () => Navigator.pop(context, 'resume'),
              child: _SheetButton(
                label: 'Resume Tracking',
                backgroundColor: colors.surfaceRaised,
                textColor: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Save
            PressableScale(
              onTap: () => Navigator.pop(context, 'save'),
              child: _SheetButton(
                label: 'Finish & Save',
                backgroundColor: colors.accent,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Discard
            PressableScale(
              onTap: () => Navigator.pop(context, 'discard'),
              child: _SheetButton(
                label: 'Discard $activityStr',
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

class _SheetButton extends ConsumerWidget {
  const _SheetButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMiles = ref.watch(distanceUnitProvider);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        boxShadow: backgroundColor == Colors.transparent ? null : [
          BoxShadow(
            color: backgroundColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.bodyLargeBold(color: textColor),
      ),
    );
  }
}

class _TargetPaceSelectorSheet extends ConsumerWidget {
  const _TargetPaceSelectorSheet({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(runTrackerProvider);
    final notifier = ref.read(runTrackerProvider.notifier);
    
    final currentPace = trackerState.targetPaceSPerKm;
    final String paceStr = currentPace != null 
        ? '${(currentPace / 60).floor()}:${(currentPace % 60).toString().padLeft(2, '0')}'
        : 'None';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.85 : 0.90),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Target Pace',
                    style: AppTextStyles.headline(color: colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIcons.minusCircleFill, color: colors.accent, size: 48),
                        onPressed: () {
                          ref.read(hapticsServiceProvider).lightImpact();
                          ref.read(soundServiceProvider).playPaceDown();
                          final newPace = (currentPace ?? 360) + 10;
                          notifier.setTargetPace(newPace);
                        },
                      ),
                      Text(paceStr, style: AppTextStyles.displayHero(color: colors.textPrimary)),
                      IconButton(
                        icon: Icon(PhosphorIcons.plusCircleFill, color: colors.accent, size: 48),
                        onPressed: () {
                          ref.read(hapticsServiceProvider).lightImpact();
                          ref.read(soundServiceProvider).playPaceUp();
                          final newPace = (currentPace ?? 360) - 10;
                          if (newPace > 0) notifier.setTargetPace(newPace);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () {
                      if (currentPace == null) {
                        notifier.setTargetPace(360);
                      } else {
                        notifier.setTargetPace(null); // Clear pace
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.surface.withValues(alpha: 0.4),
                      foregroundColor: colors.textPrimary,
                      elevation: 0,
                      side: BorderSide(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      currentPace == null ? 'Set Default (6:00/km)' : 'Clear Target Pace',
                      style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends ConsumerStatefulWidget {
  final AppColors colors;
  const _LocationButton({required this.colors});

  @override
  ConsumerState<_LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends ConsumerState<_LocationButton> {
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 12),
        child: FloatingActionButton(
          heroTag: 'manual_location',
          mini: true,
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: widget.colors.surface.withValues(alpha: 0.45),
          onPressed: _isFetching ? null : () async {
            setState(() => _isFetching = true);
            ref.read(hapticsServiceProvider).lightImpact();
            // 1️⃣ Signal the map to re-center immediately on the currently
            //    known position — this works even if coordinates haven't
            //    changed (user panned away and wants to come back).
            ref.read(recenterSignalProvider.notifier).state++;
            try {
              // 2️⃣ Also fetch a fresh GPS fix so the position updates if the
              //    user has moved since the last known fix. force=true bypasses
              //    the "already have position" guard in fetchInitialLocation().
              await ref.read(runTrackerProvider.notifier).fetchInitialLocation(force: true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not fetch location. Check GPS is enabled.')),
                );
              }
            } finally {
              if (mounted) setState(() => _isFetching = false);
            }
          },
          child: _isFetching
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.colors.accent),
                )
              : Icon(Icons.gps_fixed, color: widget.colors.accent),
        ),
      ),
    );
  }
}


class _ShoeSelectorSheet extends ConsumerWidget {
  const _ShoeSelectorSheet({
    required this.colors,
    required this.shoes,
    required this.selectedShoeId,
  });

  final AppColors colors;
  final List<ShoeIsar> shoes;
  final String? selectedShoeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: isDark ? 0.85 : 0.90),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 48, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Gear', style: AppTextStyles.headline(color: colors.textPrimary)),
                    IconButton(
                      icon: Icon(PhosphorIcons.x, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () {
                    ref.read(runTrackerProvider.notifier).setSelectedShoe(null);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.prohibit, color: colors.textSecondary),
                        const SizedBox(width: 16),
                        Text('No Shoe', style: AppTextStyles.bodyLarge(color: colors.textPrimary)),
                        const Spacer(),
                        if (selectedShoeId == null) Icon(PhosphorIcons.checkCircleFill, color: colors.accent),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: colors.border.withValues(alpha: 0.4)),
                ),
                
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: shoes.length,
                    itemBuilder: (ctx, i) {
                      final shoe = shoes[i];
                      final isSelected = shoe.clientShoeId == selectedShoeId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accent.withValues(alpha: 0.18)
                              : colors.surfaceRaised.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colors.accent.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            ref.read(runTrackerProvider.notifier).setSelectedShoe(shoe.clientShoeId);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            child: Row(
                              children: [
                                if (shoe.imageUrl != null)
                                  _buildShoeThumb(shoe.imageUrl!, 24, isSelected ? colors.accent : colors.textSecondary, colors)
                                else
                                  Icon(PhosphorIcons.sneaker, color: isSelected ? colors.accent : colors.textSecondary),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(shoe.name ?? '', style: AppTextStyles.bodyLarge(color: colors.textPrimary)),
                                    if (shoe.brand != null && shoe.brand!.isNotEmpty)
                                      Text(shoe.brand!, style: AppTextStyles.label(color: colors.textSecondary)),
                                  ],
                                ),
                                const Spacer(),
                                if (isSelected) Icon(PhosphorIcons.checkCircleFill, color: colors.accent),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.surfaceRaised,
                    foregroundColor: colors.textPrimary,
                    elevation: 0,
                    side: BorderSide(
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoeManagementScreen()));
                  },
                  child: Text('Manage Gear', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a shoe image thumbnail, handling both local file paths and network URLs.
Widget _buildShoeThumb(String imageUrl, double size, Color fallbackColor, AppColors colors) {
  if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
    final file = File(imageUrl);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(PhosphorIcons.sneaker, color: fallbackColor, size: size),
        ),
      );
    }
    return Icon(PhosphorIcons.sneaker, color: fallbackColor, size: size);
  }
  return CachedNetworkImage(
    imageUrl: imageUrl,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorWidget: (_, __, ___) => Icon(PhosphorIcons.sneaker, color: fallbackColor, size: size),
  );
}

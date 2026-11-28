import 'package:trailhead_mobile/features/run_tracking/domain/run_tracking_use_case_format_activity.dart';
import 'package:trailhead_mobile/shared/widgets/inset_sheet_body.dart';
import 'package:trailhead_mobile/shared/widgets/shoe_photo.dart';
import 'package:trailhead_mobile/features/run_tracking/state_management/run_tracking_bloc_workout_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'dart:ui';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/countdown_overlay.dart';
import 'package:trailhead_mobile/shared/widgets/pressable_scale.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:trailhead_mobile/shared/state_management/global/shoes_cubit_inventory.dart';
import 'package:trailhead_mobile/features/shoes/presentation/shoe_management_screen.dart';
import 'package:trailhead_mobile/features/shoes/domain/shoes_repository_inventory.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _maybePromptWeightAndStart(
  BuildContext context,
  AppColors colors,
  RunTrackerCubit notifier,
) async {
  final actions = context.read<WorkoutActionsBloc>();
  if (actions.needsWeight) {
    await AppNavigator.bottomSheet<void>(
      context,
      (ctx) => _WeightInputSheet(colors: colors, save: actions.saveWeight),
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    );
  }

  // Once weight prompt is handled (or if weight already exists), run countdown then start run
  if (context.mounted) {
    await CountdownOverlay.show(context);
    if (!context.mounted) return;
    context.read<AudioCubit>().playRunStart();
    notifier.startRun();
  }
}

// ---------------------------------------------------------------------------
// Weight Input Sheet — prompts user to enter weight for calorie accuracy
// ---------------------------------------------------------------------------

class _WeightInputSheet extends StatefulWidget {
  const _WeightInputSheet({required this.colors, required this.save});
  final Future<void> Function(String) save;
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
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(_controller.text);
      if (mounted) AppNavigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is FormatException
            ? error.message
            : 'Could not save body weight.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return InsetSheetBody(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
              child: Icon(
                Icons.fitness_center_rounded,
                color: colors.accent,
                size: 28,
              ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
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
                color: _saving
                    ? colors.accent.withValues(alpha: 0.6)
                    : colors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: colors.surface,
                        strokeWidth: 2.5,
                      ),
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
            onTap: () => AppNavigator.pop(context),
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

class RunActionControls extends StatefulWidget {
  const RunActionControls({
    required this.trackerState,
    required this.colors,
    required this.onStop,
  });

  final RunTrackerState trackerState;
  final AppColors colors;
  final VoidCallback onStop;

  @override
  State<RunActionControls> createState() => RunActionControlsState();
}

class RunActionControlsState extends State<RunActionControls> {
  @override
  Widget build(BuildContext context) {
    final trackerState = widget.trackerState;
    final colors = widget.colors;
    final onStop = widget.onStop;

    final notifier = context.read<RunTrackerCubit>();
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
            padding: const EdgeInsets.only(
              top: 12,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.45,
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
                  _buildShoeSelector(context, colors, trackerState),
                  const SizedBox(height: 16),
                ],
                if (!isIdle) const SizedBox(height: 12),

                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  runSpacing: 12,
                  children: [
                    // Left Action (Activity Toggle or Stop)
                    _CircularAction(
                      icon: isIdle
                          ? (isRun
                                ? PhosphorIcons.personSimpleRun
                                : PhosphorIcons.personSimpleWalk)
                          : PhosphorIcons.stopFill,
                      label: isIdle ? (isRun ? 'Run' : 'Walk') : 'Stop',
                      color: colors.surface.withValues(alpha: 0.45),
                      iconColor: isIdle ? colors.accent : colors.error,
                      textColor: colors.textPrimary,
                      onTap: () {
                        if (isIdle) {
                          context.read<HapticsCubit>().lightImpact();
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
                            notifier.requestForegroundPermission().then((
                              granted,
                            ) {
                              if (granted) {
                                if (context.mounted) {
                                  _maybePromptWeightAndStart(
                                    context,
                                    colors,
                                    notifier,
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Location permission required to track runs.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          } else {
                            _maybePromptWeightAndStart(
                              context,
                              colors,
                              notifier,
                            );
                          }
                        } else if (isPaused) {
                          context.read<AudioCubit>().playPauseResume();
                          notifier.resumeRun();
                        } else {
                          context.read<AudioCubit>().playPauseResume();
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
                          isIdle || isPaused
                              ? PhosphorIcons.playFill
                              : PhosphorIcons.pauseFill,
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
                          context.read<HapticsCubit>().lightImpact();
                          AppNavigator.bottomSheet(
                            context,
                            (ctx) => _TargetPaceSelectorSheet(colors: colors),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black.withValues(alpha: 0.35),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
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

  Widget _buildShoeSelector(
    BuildContext context,
    AppColors colors,
    RunTrackerState state,
  ) {
    final activeShoesAsync = context.watch<ShoesCubit>().state;
    return activeShoesAsync.when(
      data: (inventory) {
        final shoes = inventory
            .where((shoe) => shoe.isActive)
            .toList(growable: false);
        if (shoes.isEmpty) {
          return GestureDetector(
            onTap: () {
              context.read<HapticsCubit>().lightImpact();
              AppNavigator.push(
                context,
                AppNavigator.materialPageRoute(
                  builder: (_) => const ShoeManagementScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.sneaker,
                    color: colors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Gear',
                    style: AppTextStyles.bodyMediumBold(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final selectedShoe = state.selectedShoeId != null
            ? shoes.cast<ShoeGear?>().firstWhere(
                (s) => s?.clientShoeId == state.selectedShoeId,
                orElse: () => null,
              )
            : null;

        return GestureDetector(
          onTap: () {
            context.read<HapticsCubit>().lightImpact();
            AppNavigator.bottomSheet(
              context,
              (ctx) => _ShoeSelectorSheet(
                colors: colors,
                shoes: shoes,
                selectedShoeId: state.selectedShoeId,
              ),
              backgroundColor: Colors.transparent,
              barrierColor: colors.background.withValues(alpha: 0.6),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedShoe != null && selectedShoe.imageUrl != null)
                  ShoePhoto(
                    source: selectedShoe.imageUrl,
                    size: 20,
                    color: colors.accent,
                    radius: 4,
                  )
                else
                  Icon(
                    PhosphorIcons.sneaker,
                    color: selectedShoe != null
                        ? colors.accent
                        : colors.textSecondary,
                    size: 16,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedShoe?.name ?? 'Select Shoe',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMediumBold(
                      color: selectedShoe != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIcons.caretDown,
                  color: colors.textSecondary,
                  size: 12,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 32,
        width: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CircularAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

class _TargetPaceSelectorSheet extends StatelessWidget {
  const _TargetPaceSelectorSheet({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final trackerState = context.watch<RunTrackerCubit>().state;
    final notifier = context.read<RunTrackerCubit>();

    final currentPace = trackerState.targetPaceSPerKm;
    final String paceStr = currentPace != null
        ? RunFormatUtils.formatPaceSeconds(
            currentPace.toDouble(),
            useMiles: false,
          )
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
          child: InsetSheetBody(
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
                      icon: Icon(
                        PhosphorIcons.minusCircleFill,
                        color: colors.accent,
                        size: 48,
                      ),
                      onPressed: () {
                        context.read<HapticsCubit>().lightImpact();
                        context.read<AudioCubit>().playPaceDown();
                        final newPace = (currentPace ?? 360) + 10;
                        notifier.setTargetPace(newPace);
                      },
                    ),
                    Flexible(
                      child: Text(
                        paceStr,
                        style: AppTextStyles.displayHero(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.plusCircleFill,
                        color: colors.accent,
                        size: 48,
                      ),
                      onPressed: () {
                        context.read<HapticsCubit>().lightImpact();
                        context.read<AudioCubit>().playPaceUp();
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    currentPace == null
                        ? 'Set Default (6:00/km)'
                        : 'Clear Target Pace',
                    style: AppTextStyles.bodyLargeBold(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoeSelectorSheet extends StatelessWidget {
  const _ShoeSelectorSheet({
    required this.colors,
    required this.shoes,
    required this.selectedShoeId,
  });

  final AppColors colors;
  final List<ShoeGear> shoes;
  final String? selectedShoeId;

  @override
  Widget build(BuildContext context) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 48,
              left: 24,
              right: 24,
            ),
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
                    Text(
                      'Select Gear',
                      style: AppTextStyles.headline(color: colors.textPrimary),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.x, color: colors.textSecondary),
                      onPressed: () => AppNavigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () {
                    context.read<RunTrackerCubit>().setSelectedShoe(null);
                    AppNavigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.prohibit,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'No Shoe',
                          style: AppTextStyles.bodyLarge(
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (selectedShoeId == null)
                          Icon(
                            PhosphorIcons.checkCircleFill,
                            color: colors.accent,
                          ),
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
                            context.read<RunTrackerCubit>().setSelectedShoe(
                              shoe.clientShoeId,
                            );
                            AppNavigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                if (shoe.imageUrl != null)
                                  ShoePhoto(
                                    source: shoe.imageUrl,
                                    size: 24,
                                    color: isSelected
                                        ? colors.accent
                                        : colors.textSecondary,
                                    radius: 4,
                                  )
                                else
                                  Icon(
                                    PhosphorIcons.sneaker,
                                    color: isSelected
                                        ? colors.accent
                                        : colors.textSecondary,
                                  ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shoe.name ?? '',
                                      style: AppTextStyles.bodyLarge(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (shoe.brand != null &&
                                        shoe.brand!.isNotEmpty)
                                      Text(
                                        shoe.brand!,
                                        style: AppTextStyles.label(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    PhosphorIcons.checkCircleFill,
                                    color: colors.accent,
                                  ),
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
                    AppNavigator.pop(context);
                    AppNavigator.push(
                      context,
                      AppNavigator.materialPageRoute(
                        builder: (_) => const ShoeManagementScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Manage Gear',
                    style: AppTextStyles.bodyLargeBold(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

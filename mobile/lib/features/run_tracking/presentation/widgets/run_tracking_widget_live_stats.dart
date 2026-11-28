import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class RunLiveStats extends StatefulWidget {
  const RunLiveStats({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  @override
  State<RunLiveStats> createState() => RunLiveStatsState();
}

class RunLiveStatsState extends State<RunLiveStats> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final useMiles = context.watch<DistanceUnitCubit>().state;
    final unit = RunFormatUtils.getUnitString(useMiles);
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 0 && !_isExpanded) {
          // Swipe down
          setState(() => _isExpanded = true);
        } else if ((details.primaryVelocity ?? 0) < 0 && _isExpanded) {
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
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.35
                      : 0.45,
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
                        _isExpanded
                            ? PhosphorIcons.caretDownBold
                            : PhosphorIcons.caretUpBold,
                        color: widget.colors.textSecondary.withValues(
                          alpha: 0.5,
                        ),
                        size: 24,
                      ),
                    ),
                    AdaptiveColumns(
                      maxColumns: 3,
                      minColumnWidth: 74,
                      spacing: 8,
                      children: [
                        // Time
                        _StatColumn(
                          value: RunFormatUtils.formatDuration(
                            widget.trackerState.durationS,
                          ),
                          label: 'Time',
                          colors: widget.colors,
                        ),

                        // Pace
                        _StatColumn(
                          value:
                              widget.trackerState.currentSplitPaceSPerKm != null
                              ? RunFormatUtils.formatPaceSeconds(
                                  widget.trackerState.currentSplitPaceSPerKm!
                                      .toDouble(),
                                  useMiles: useMiles,
                                )
                              : RunFormatUtils.formatPace(
                                  widget.trackerState.distanceM,
                                  widget.trackerState.durationS,
                                  useMiles,
                                ),
                          label:
                              widget.trackerState.currentSplitPaceSPerKm != null
                              ? 'Split avg. (/$unit)'
                              : 'Pace (/$unit)',
                          colors: widget.colors,
                        ),

                        // Distance
                        _StatColumn(
                          value: RunFormatUtils.formatDistance(
                            widget.trackerState.distanceM,
                            useMiles,
                          ),
                          label: 'Distance ($unit)',
                          colors: widget.colors,
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 24),
                      AdaptiveColumns(
                        maxColumns: 3,
                        minColumnWidth: 74,
                        spacing: 8,
                        children: [
                          // Steps
                          _StatColumn(
                            value: widget.trackerState.stepCount.toString(),
                            label: 'Steps',
                            colors: widget.colors,
                          ),

                          // Cadence
                          _StatColumn(
                            value: widget.trackerState.currentCadence > 0
                                ? widget.trackerState.currentCadence.toString()
                                : '--',
                            label: 'Cadence (spm)',
                            colors: widget.colors,
                          ),

                          // Calories
                          _StatColumn(
                            value: widget.trackerState.caloriesKcal > 0
                                ? widget.trackerState.caloriesKcal.toString()
                                : '--',
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.colors,
  });
  final String value;
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.displayStat(
            color: colors.textPrimary,
          ).copyWith(fontSize: 40),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

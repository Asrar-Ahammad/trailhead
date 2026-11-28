import '../../../history/state_management/history_bloc_route_points.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/static_route_map.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';

class ActivityCard extends StatelessWidget {
  final RunIsar run;
  final int achievementsCount;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;

  const ActivityCard({
    super.key, 
    required this.run, 
    this.achievementsCount = 0,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(run.clientRunId),
    create: (_) => context.read<CreateHistoryRouteBloc>()(run.clientRunId),
    child: Builder(builder: _buildCard),
  );

  Widget _buildCard(BuildContext context) {
    final useMiles = context.watch<DistanceUnitCubit>().state;
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final pointsAsync = context.watch<HistoryRouteBloc>().state;

    String formattedTime = '00:00';
    if (run.startTime != null) {
      final hour = run.startTime!.hour.toString().padLeft(2, '0');
      final minute = run.startTime!.minute.toString().padLeft(2, '0');
      formattedTime = '$hour:$minute';
    }
    final durationMins = ((run.durationS ?? 0) / 60).floor();

    return InkWell(
      onLongPress: onLongPress,
      onTap: () {
        if (isSelectionMode) {
          onSelect?.call();
          return;
        }
        context.read<HapticsCubit>().lightImpact();
        context.read<AudioCubit>().playActivityTap();
        AppNavigator.push(context,
          AppNavigator.materialPageRoute(
            builder: (context) => RunDetailScreen(run: run),
          ),
        );
      },
      child: Container(
        color: isSelected ? retroColors.accent.withOpacity(0.2) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column (Text info)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        run.activityType == 'walk' 
                            ? PhosphorIcons.personSimpleWalk 
                            : PhosphorIcons.personSimpleRun, 
                        size: 16, 
                        color: retroColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: AppTextStyles.label(color: retroColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    RunFormatUtils.getRunTitle(
                      run.title, 
                      run.startTime, 
                      activityType: run.activityType ?? 'run',
                      distanceM: run.distanceM,
                      subjectiveEffort: run.subjectiveEffort,
                      conditions: run.conditions,
                    ),
                    style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  if (achievementsCount > 0)
                    Row(
                      children: [
                        Text(
                          (RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles)) + ' ' + RunFormatUtils.getUnitString(useMiles) + ' in $durationMins min • ',
                          style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                        ),
                        Icon(
                          PhosphorIcons.medalFill,
                          size: 16,
                          color: achievementsCount == 1
                              ? const Color(0xFFFFD700) // Gold
                              : achievementsCount == 2
                                  ? const Color(0xFFC0C0C0) // Silver
                                  : const Color(0xFFCD7F32), // Bronze
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$achievementsCount pts',
                          style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                        ),
                      ],
                    )
                  else
                    Text(
                      (RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles)) + ' ' + RunFormatUtils.getUnitString(useMiles) + ' in $durationMins min',
                      style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Right Column (Thumbnail)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: retroColors.surfaceRaised,
              ),
              clipBehavior: Clip.antiAlias,
              child: pointsAsync.when(
                data: (points) {
                  final validPoints = points.where((p) => p.lat != null && p.lng != null).map((p) => LatLng(p.lat!, p.lng!)).toList();
                  if (validPoints.isNotEmpty) {
                    return Stack(
                      children: [
                        StaticRouteMap(
                          points: validPoints,
                          showBaseMap: false,
                          showMarkers: false,
                          padding: const EdgeInsets.all(16.0),
                        ),
                      ],
                    );
                  }
                  return Icon(PhosphorIcons.personSimpleRunFill, size: 32, color: retroColors.accent);
                },
                loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent, strokeWidth: 2)),
                error: (_, __) => Icon(PhosphorIcons.warning, size: 24, color: retroColors.error),
              ),
            ),
            if (isSelectionMode) ...[
              const SizedBox(width: 16),
              Icon(
                isSelected ? PhosphorIcons.checkCircleFill : PhosphorIcons.circle,
                color: isSelected ? retroColors.accent : retroColors.textSecondary,
                size: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

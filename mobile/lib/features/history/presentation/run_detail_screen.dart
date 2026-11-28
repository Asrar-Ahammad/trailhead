import '../domain/history_use_case_biometrics.dart';
import 'widgets/history_widget_biometrics.dart';
import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'package:trailhead_mobile/shared/widgets/shoe_photo.dart';
import 'package:path/path.dart' as paths;
import '../state_management/history_bloc_route_points.dart';
import '../state_management/history_bloc_activity_actions.dart';
import '../../../shared/state_management/async_value.dart';
import '../../../shared/state_management/global/shoes_cubit_inventory.dart';
import '../../shoes/domain/shoes_repository_inventory.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/static_route_map.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_splits_table.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_charts_section.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/results_section.dart';
import 'package:trailhead_mobile/features/shoes/presentation/shoe_dashboard_screen.dart';
import 'package:trailhead_mobile/features/weather/application/weather_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'share_activity_screen.dart';
import 'run_flyover_screen.dart';

class RunDetailScreen extends StatefulWidget {
  final RunIsar run;

  const RunDetailScreen({super.key, required this.run});

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  late final HistoryRouteBloc _route;
  late final HistoryActionsBloc _actions;

  @override
  void initState() {
    super.initState();
    _route = context.read<CreateHistoryRouteBloc>()(widget.run.clientRunId);
    _actions = context.read<CreateHistoryActionsBloc>()(widget.run, _route);
  }

  @override
  void dispose() {
    _actions.close();
    _route.close();
    super.dispose();
  }

  void _onAction(BuildContext context, HistoryActionState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state.deleted &&
        ModalRoute.of(context)?.isCurrent == true &&
        AppNavigator.canPop(context)) {
      AppNavigator.pop(context, true);
    } else if (state.file case final file?) {
      context.read<HapticsCubit>().mediumImpact();
      context.read<AudioCubit>().playToggleSwitch();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved GPX to Downloads/Trailhead_GPX/:\n${paths.basename(file.path)}',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'SHARE',
            onPressed: () => Share.shareXFiles([XFile(file.path)]),
          ),
        ),
      );
    } else if (state.error case final error?) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _route),
      BlocProvider.value(value: _actions),
    ],
    child: BlocListener<HistoryActionsBloc, HistoryActionState>(
      listener: _onAction,
      child: Builder(builder: _buildDetail),
    ),
  );

  Widget _buildDetail(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final run = widget.run;
    final useMiles = context.watch<DistanceUnitCubit>().state;

    final date = run.startTime != null
        ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(run.startTime!)
        : 'Unknown Date';

    final durationMins = ((run.durationS ?? 0) / 60).floor();
    final durationSecs = ((run.durationS ?? 0) % 60).toString().padLeft(2, '0');

    // Unit-aware distance and pace
    final displayDistance = RunFormatUtils.formatDistance(
      run.distanceM ?? 0,
      useMiles,
    );
    final unitStr = RunFormatUtils.getUnitString(useMiles);

    final pacePerKm = run.avgPaceSPerKm ?? 0;
    final paceSeconds = useMiles
        ? (pacePerKm * 1.60934).round()
        : pacePerKm.round();
    final paceMins = paceSeconds ~/ 60;
    final paceSecs = (paceSeconds % 60).toString().padLeft(2, '0');

    final rawPointsAsync = context.watch<HistoryRouteBloc>().state;
    final pointsAsync = rawPointsAsync.when<AsyncValue<List<LatLng>>>(
      data: (points) => AsyncValue.data(HistoryRouteBloc.coordinates(points)),
      loading: () => const AsyncValue.loading(),
      error: (error, trace) => AsyncValue.error(error, trace),
    );
    final busy = context.select((HistoryActionsBloc bloc) => bloc.state.busy);
    final isDeleting = busy == HistoryAction.delete;
    final isExporting = busy == HistoryAction.exportGpx;

    final activityStr = (run.activityType ?? 'run').toUpperCase();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: retroColors.background,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'ACTIVITY // $activityStr',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: retroColors.textPrimary,
              ),
            ),
            backgroundColor: retroColors.surface.withValues(alpha: 0.8),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: retroColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                PhosphorIcons.arrowLeft,
                color: retroColors.textPrimary,
              ),
              onPressed: () => AppNavigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork,
                  color: retroColors.textPrimary,
                ),
                tooltip: 'Share Activity',
                onPressed: () async {
                  if (run.clientRunId == null) return;
                  List<LatLng> latLngPoints;
                  try {
                    latLngPoints = HistoryRouteBloc.coordinates(
                      await _route.load(),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not load the activity route.'),
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    AppNavigator.push(
                      context,
                      AppNavigator.materialPageRoute(
                        builder: (_) =>
                            ShareActivityScreen(run: run, points: latLngPoints),
                      ),
                    );
                  }
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  PhosphorIcons.dotsThreeVertical,
                  color: retroColors.textPrimary,
                ),
                color: retroColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: retroColors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'download_gpx') {
                    context.read<HapticsCubit>().lightImpact();
                    _actions.add(HistoryAction.exportGpx);
                  } else if (value == 'delete') {
                    final confirm = await AppNavigator.dialog<bool>(
                      context,
                      (context) => AlertDialog(
                        backgroundColor: retroColors.surface,
                        title: Text(
                          'Delete Workout?',
                          style: AppTextStyles.title(
                            color: retroColors.textPrimary,
                          ),
                        ),
                        content: Text(
                          'This workout data will be permanently removed.',
                          style: AppTextStyles.bodyMedium(
                            color: retroColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => AppNavigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.bodyMediumBold(
                                color: retroColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => AppNavigator.pop(context, true),
                            child: Text(
                              'Delete',
                              style: AppTextStyles.bodyMediumBold(
                                color: retroColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted)
                      _actions.add(HistoryAction.delete);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'download_gpx',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.downloadSimple,
                          color: retroColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Download GPX',
                          style: AppTextStyles.bodyMedium(
                            color: retroColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.trash,
                          color: retroColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Run',
                          style: AppTextStyles.bodyMedium(
                            color: retroColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Monochrome Route Map
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: retroColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: retroColors.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: pointsAsync.when(
                      data: (points) => points.isEmpty
                          ? Center(
                              child: Text(
                                'No GPS route recorded',
                                style: AppTextStyles.bodyMedium(
                                  color: retroColors.textSecondary,
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: StaticRouteMap(
                                    points: points,
                                    isMonochrome: true,
                                    showKilometerMarkers: true,
                                    useMiles: useMiles,
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final rawPoints =
                                            rawPointsAsync.valueOrNull ?? [];
                                        if (context.mounted &&
                                            rawPoints.isNotEmpty) {
                                          AppNavigator.push(
                                            context,
                                            AppNavigator.materialPageRoute(
                                              builder: (_) => RunFlyoverScreen(
                                                run: run,
                                                points: rawPoints,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: retroColors.surface.withValues(
                                            alpha: 0.88,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: retroColors.accent
                                                .withValues(alpha: 0.8),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              PhosphorIcons.playFill,
                                              size: 13,
                                              color: retroColors.accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '3D FLYOVER',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                                color: retroColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: retroColors.accent,
                        ),
                      ),
                      error: (_, __) => Center(
                        child: Text(
                          'Map error',
                          style: AppTextStyles.bodyMedium(
                            color: retroColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Header Info: Date, Title & Weather
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: retroColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (run.weatherTemp != null && run.weatherCode != null)
                      Builder(
                        builder: (context) {
                          final isDay = run.startTime != null
                              ? (run.startTime!.hour >= 6 &&
                                    run.startTime!.hour < 19)
                              : true;
                          final code = run.weatherCode!.toInt();
                          final weatherIcon = WeatherUtils.getWeatherIcon(
                            code,
                            isDay: isDay,
                          );
                          final weatherColor = WeatherUtils.getWeatherColor(
                            code,
                            retroColors,
                            isDay: isDay,
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: retroColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: retroColors.border.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  weatherIcon,
                                  color: weatherColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${run.weatherTemp!.toStringAsFixed(0)}°C',
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: retroColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: retroColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Shoe Info Pill (if tracked)
                if (run.clientShoeId != null)
                  context.watch<ShoesCubit>().state.when(
                    data: (inventory) {
                      final shoe = findTrackedShoe(
                        inventory,
                        run.clientShoeId!,
                      );
                      if (shoe == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: InkWell(
                          onTap: () {
                            AppNavigator.push(
                              context,
                              AppNavigator.materialPageRoute(
                                builder: (context) =>
                                    ShoeDashboardScreen(shoe: shoe),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: retroColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: retroColors.border.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShoePhoto(
                                  source: shoe.imageUrl,
                                  size: 36,
                                  color: retroColors.accent,
                                  background: retroColors.surfaceRaised,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        shoe.name ?? 'Unknown Shoe',
                                        style: AppTextStyles.bodyMediumBold(
                                          color: retroColors.textPrimary,
                                        ),
                                      ),
                                      if (shoe.brand != null &&
                                          shoe.brand!.isNotEmpty)
                                        Text(
                                          shoe.brand!.toUpperCase(),
                                          style: AppTextStyles.labelCaps(
                                            color: retroColors.textSecondary,
                                          ).copyWith(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  PhosphorIcons.caretRight,
                                  color: retroColors.textSecondary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                // 4. Hero Primary 3-Metric Panel (Distance, Time, Pace)
                Container(
                  decoration: BoxDecoration(
                    color: retroColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: retroColors.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: AdaptiveColumns(
                    maxColumns: 3,

                    minColumnWidth: 85,

                    children: [
                      // Distance
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'DISTANCE',
                            style: AppTextStyles.labelCaps(
                              color: retroColors.textSecondary,
                            ).copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                displayDistance,
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: retroColors.accent,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                unitStr.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: retroColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Duration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'DURATION',
                            style: AppTextStyles.labelCaps(
                              color: retroColors.textSecondary,
                            ).copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$durationMins:$durationSecs',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: retroColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),

                      // Pace
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'AVG PACE',
                            style: AppTextStyles.labelCaps(
                              color: retroColors.textSecondary,
                            ).copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$paceMins:$paceSecs',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: retroColors.accent,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                useMiles ? '/MI' : '/KM',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: retroColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Secondary Biometrics Grid
                Text(
                  'BIOMETRICS & ELEVATION',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: retroColors.accent,
                  ),
                ),
                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    final route = rawPointsAsync.valueOrNull ?? [];
                    final metrics = activityBiometrics(
                      storedPace: run.avgGapSPerKm,
                      storedElevation: run.elevationGainM,
                      steps: run.stepCount,
                      cadence: run.avgCadenceSpm,
                      duration: run.durationS,
                      route: route
                          .map(
                            (point) => (
                              lat: point.lat,
                              lng: point.lng,
                              elevation: point.elevation,
                              timestamp: point.timestamp,
                              isPaused: point.isPaused,
                            ),
                          )
                          .toList(),
                    );
                    final pace = metrics.pace;
                    final elevation = metrics.elevation;
                    return AdaptiveColumns(
                      maxColumns: 3,
                      minColumnWidth: 98,
                      children: [
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.chartLineUp,
                          'GAP',
                          pace == null
                              ? '—'
                              : '${RunFormatUtils.formatPaceSeconds(pace, useMiles: useMiles)} /$unitStr',
                          tooltipMessage:
                              'Grade-Adjusted Pace estimates your pace on flat terrain.',
                        ),
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.trendUp,
                          'Elevation',
                          elevation == null
                              ? '—'
                              : useMiles
                              ? '${(elevation * 3.28084).round()} ft'
                              : '${elevation.round()} m',
                        ),
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.flame,
                          'Calories',
                          _metricLabel(run.caloriesKcal, 0, 'kcal'),
                        ),
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.footprints,
                          'Cadence',
                          _metricLabel(run.avgCadenceSpm, 0, 'spm'),
                        ),
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.arrowsOutLineHorizontal,
                          'Stride',
                          _metricLabel(run.avgStrideLengthM, 2, 'm'),
                        ),
                        HistoryBiometricTile(
                          retroColors,
                          PhosphorIcons.personSimpleWalk,
                          'Total Steps',
                          metrics.steps?.toString() ?? '—',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 6. Splits Table
                rawPointsAsync.when(
                  data: (points) => RunSplitsTable(points: points),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 7. Results Section (PRs / Records)
                ResultsSection(run: run),

                // 8. Detailed AI Coaching Breakdown
                if (run.aiAnalysis != null && run.aiAnalysis!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'AI // PERFORMANCE ANALYSIS',
                    style: GoogleFonts.pixelifySans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: retroColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: retroColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: retroColors.border.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 40,
                          decoration: BoxDecoration(
                            color: retroColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.sparkleFill,
                                    color: retroColors.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'COACH INTEL',
                                    style: AppTextStyles.labelCaps(
                                      color: retroColors.accent,
                                    ).copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                run.aiAnalysis!,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: retroColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 9. AI Summary (Short)
                if (run.aiSummary != null && run.aiSummary!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: retroColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: retroColors.border.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      run.aiSummary!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: retroColors.textPrimary,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // 10. Interactive Elevation & Pace Charts
                rawPointsAsync.when(
                  data: (points) => RunChartsSection(run: run, points: points),
                  loading: () => Center(
                    child: CircularProgressIndicator(color: retroColors.accent),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        if (isDeleting || isExporting)
          Container(
            color: retroColors.background.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: retroColors.accent),
                  if (isExporting) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Exporting GPX...',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: retroColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _metricLabel(double? value, int decimals, String unit) =>
    value != null && value > 0
    ? '${value.toStringAsFixed(decimals)} $unit'
    : '—';

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/static_route_map.dart';
import 'package:trailhead_mobile/features/stats/application/gap_calculator.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_splits_table.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_charts_section.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/results_section.dart';
import 'package:trailhead_mobile/features/shoes/presentation/shoe_dashboard_screen.dart';
import 'package:trailhead_mobile/features/shoes/application/shoe_service.dart';
import 'package:trailhead_mobile/features/shoes/data/models/shoe_isar.dart';
import 'package:trailhead_mobile/features/weather/application/weather_utils.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';
import 'package:trailhead_mobile/features/stats/application/weekly_stats_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/history/application/gpx_export_util.dart';
import 'share_activity_screen.dart';
import 'run_flyover_screen.dart';

final runRawPointsProvider = FutureProvider.family<List<RunPointIsar>, String>((ref, clientRunId) async {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.getRunPoints(clientRunId);
});

final runShoeProvider = FutureProvider.family<ShoeIsar?, String>((ref, clientShoeId) async {
  final repo = ref.read(shoeRepositoryProvider);
  final shoe = await repo.getShoeByClientId(clientShoeId);
  if (shoe != null) return shoe;
  final dbId = int.tryParse(clientShoeId);
  if (dbId != null) {
    return await repo.getShoeById(dbId);
  }
  return null;
});

final runPointsProvider = FutureProvider.family<List<LatLng>, String>((ref, clientRunId) async {
  final points = await ref.watch(runRawPointsProvider(clientRunId).future);
  return points.map((p) => LatLng(p.lat ?? 0.0, p.lng ?? 0.0)).toList();
});

class RunDetailScreen extends ConsumerStatefulWidget {
  final RunIsar run;

  const RunDetailScreen({super.key, required this.run});

  @override
  ConsumerState<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends ConsumerState<RunDetailScreen> {
  bool _isDeleting = false;
  bool _isExporting = false;

  Future<void> _downloadGpx() async {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final run = widget.run;
    if (run.clientRunId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: retroColors.error,
            content: Text(
              'Cannot export run without a valid ID.',
              style: AppTextStyles.bodyMedium(color: retroColors.background),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      context.read<HapticsCubit>().lightImpact();
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted && !status.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      }

      final repo = ref.read(runHistoryRepositoryProvider);
      final points = await repo.getRunPoints(run.clientRunId!);
      final validPoints = points.where((p) => p.lat != null && p.lng != null).toList();

      if (validPoints.isEmpty) {
        if (mounted) {
          setState(() {
            _isExporting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: retroColors.surface,
              content: Text(
                'No GPS route points found for this activity.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: retroColors.textPrimary,
                ),
              ),
            ),
          );
        }
        return;
      }

      final file = await GpxExportUtil.saveRunGpxToDownloads(run, validPoints);
      if (!mounted) return;
      context.read<HapticsCubit>().mediumImpact();
      context.read<AudioCubit>().playToggleSwitch();

      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        final fileName = file.path.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: retroColors.success,
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                Icon(PhosphorIcons.checkCircleFill, color: retroColors.surface, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved GPX to Downloads/Trailhead_GPX/:\n$fileName',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: retroColors.surface,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'SHARE',
              textColor: retroColors.surface,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: retroColors.error,
            content: Text(
              'Failed to save GPX: $e',
              style: AppTextStyles.bodyMedium(color: retroColors.background),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final run = widget.run;
    final useMiles = context.watch<DistanceUnitCubit>().state;
    
    final date = run.startTime != null 
        ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(run.startTime!)
        : 'Unknown Date';
    
    final durationMins = ((run.durationS ?? 0) / 60).floor();
    final durationSecs = ((run.durationS ?? 0) % 60).toString().padLeft(2, '0');
    
    // Unit-aware distance and pace
    final displayDistance = RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles);
    final unitStr = RunFormatUtils.getUnitString(useMiles);

    final pacePerKm = run.avgPaceSPerKm ?? 0;
    final paceSeconds = useMiles ? (pacePerKm * 1.60934).round() : pacePerKm.round();
    final paceMins = paceSeconds ~/ 60;
    final paceSecs = (paceSeconds % 60).toString().padLeft(2, '0');

    final rawPointsAsync = run.clientRunId != null
        ? ref.watch(runRawPointsProvider(run.clientRunId!))
        : const AsyncValue.data(<RunPointIsar>[]);

    final pointsAsync = run.clientRunId != null 
        ? ref.watch(runPointsProvider(run.clientRunId!)) 
        : const AsyncValue.data(<LatLng>[]);

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
              icon: Icon(PhosphorIcons.arrowLeft, color: retroColors.textPrimary),
              onPressed: () => AppNavigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(PhosphorIcons.shareNetwork, color: retroColors.textPrimary),
                tooltip: 'Share Activity',
                onPressed: () async {
                  if (run.clientRunId == null) return;
                  final repo = ref.read(runHistoryRepositoryProvider);
                  final points = await repo.getRunPoints(run.clientRunId!);
                  if (context.mounted) {
                    final latLngPoints = points
                        .where((p) => p.lat != null && p.lng != null)
                        .map((p) => LatLng(p.lat!, p.lng!))
                        .toList();
                    AppNavigator.push(context,
                      AppNavigator.materialPageRoute(
                        builder: (_) => ShareActivityScreen(
                          run: run,
                          points: latLngPoints,
                        ),
                      ),
                    );
                  }
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(PhosphorIcons.dotsThreeVertical, color: retroColors.textPrimary),
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
                    await _downloadGpx();
                  } else if (value == 'delete') {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: retroColors.surface,
                        title: Text('Delete Workout?', style: AppTextStyles.title(color: retroColors.textPrimary)),
                        content: Text('This workout data will be permanently removed.', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => AppNavigator.pop(context, false),
                            child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => AppNavigator.pop(context, true),
                            child: Text('Delete', style: AppTextStyles.bodyMediumBold(color: retroColors.error)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && mounted) {
                      setState(() {
                        _isDeleting = true;
                      });
                      
                      try {
                        final repo = ref.read(runHistoryRepositoryProvider);
                        await repo.deleteRun(run.id, clientRunId: run.clientRunId);
                        ref.invalidate(historyProvider);
                        ref.invalidate(prsProvider);
                        ref.invalidate(weeklySummaryProvider);
                        if (mounted && AppNavigator.canPop(context)) {
                          AppNavigator.pop(context, true);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isDeleting = false;
                          });
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'download_gpx',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.downloadSimple, color: retroColors.textPrimary, size: 20),
                        const SizedBox(width: 12),
                        Text('Download GPX', style: AppTextStyles.bodyMedium(color: retroColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.trash, color: retroColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete Run', style: AppTextStyles.bodyMedium(color: retroColors.error)),
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
                          ? Center(child: Text('No GPS route recorded', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)))
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
                                        List<RunPointIsar> rawPoints = rawPointsAsync.valueOrNull ?? [];
                                        if (rawPoints.isEmpty && run.clientRunId != null) {
                                          final repo = ref.read(runHistoryRepositoryProvider);
                                          rawPoints = await repo.getRunPoints(run.clientRunId!);
                                        }
                                        if (context.mounted && rawPoints.isNotEmpty) {
                                          AppNavigator.push(context,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: retroColors.surface.withValues(alpha: 0.88),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: retroColors.accent.withValues(alpha: 0.8),
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
                      loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
                      error: (_, __) => Center(child: Text('Map error', style: AppTextStyles.bodyMedium(color: retroColors.error))),
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
                          final isDay = run.startTime != null ? (run.startTime!.hour >= 6 && run.startTime!.hour < 19) : true;
                          final code = run.weatherCode!.toInt();
                          final weatherIcon = WeatherUtils.getWeatherIcon(code, isDay: isDay);
                          final weatherColor = WeatherUtils.getWeatherColor(code, retroColors, isDay: isDay);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: retroColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: retroColors.border.withValues(alpha: 0.4),
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
                  ref.watch(runShoeProvider(run.clientShoeId!)).when(
                    data: (shoe) {
                      if (shoe == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: InkWell(
                          onTap: () {
                            AppNavigator.push(
                              context,
                              AppNavigator.materialPageRoute(
                                builder: (context) => ShoeDashboardScreen(shoe: shoe),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: retroColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: retroColors.border.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildShoeThumbnail(shoe.imageUrl, retroColors),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      shoe.name ?? 'Unknown Shoe',
                                      style: AppTextStyles.bodyMediumBold(color: retroColors.textPrimary),
                                    ),
                                    if (shoe.brand != null && shoe.brand!.isNotEmpty)
                                      Text(
                                        shoe.brand!.toUpperCase(),
                                        style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(PhosphorIcons.caretRight, color: retroColors.textSecondary, size: 14),
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
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      // Distance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'DISTANCE',
                              style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
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
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 36,
                        color: retroColors.border.withValues(alpha: 0.4),
                      ),

                      // Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'DURATION',
                              style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
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
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 36,
                        color: retroColors.border.withValues(alpha: 0.4),
                      ),

                      // Pace
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'AVG PACE',
                              style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
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
                    final unitSuffix = useMiles ? '/mi' : '/km';

                    String gapStr = '—';
                    if (run.avgGapSPerKm != null && run.avgGapSPerKm! > 0) {
                      gapStr = '${RunFormatUtils.formatPace(1000.0, run.avgGapSPerKm!.round(), useMiles)} $unitSuffix';
                    }

                    String elevationStr = '—';
                    if (run.elevationGainM != null && run.elevationGainM! > 0) {
                      elevationStr = useMiles 
                          ? '${(run.elevationGainM! * 3.28084).toStringAsFixed(0)} ft'
                          : '${run.elevationGainM!.toStringAsFixed(0)} m';
                    }

                    return rawPointsAsync.when(
                      data: (rawPoints) {
                        double? computedElev = run.elevationGainM;
                        if (computedElev == null || computedElev == 0) {
                          computedElev = _computeElevationGainFromPoints(rawPoints);
                        }
                        String dataElevationStr = elevationStr;
                        if (computedElev != null && computedElev > 0) {
                          dataElevationStr = useMiles
                              ? '${(computedElev * 3.28084).toStringAsFixed(0)} ft'
                              : '${computedElev.toStringAsFixed(0)} m';
                        }

                        double? computedGap = run.avgGapSPerKm;
                        if (computedGap == null || computedGap == 0) {
                          computedGap = GapCalculator.computeGap(rawPoints);
                        }
                        String dataGapStr = gapStr;
                        if (computedGap != null && computedGap > 0) {
                          dataGapStr = '${RunFormatUtils.formatPace(1000.0, computedGap.round(), useMiles)} $unitSuffix';
                        }

                        return GridView.count(
                          padding: EdgeInsets.zero,
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                          children: [
                            _buildStatCard(
                              retroColors, 
                              PhosphorIcons.chartLineUp, 
                              'GAP', 
                              dataGapStr,
                              tooltipMessage: 'Grade-Adjusted Pace estimates your pace if the route were completely flat.',
                            ),
                            _buildStatCard(retroColors, PhosphorIcons.trendUp, 'Elevation', dataElevationStr),
                            _buildStatCard(retroColors, PhosphorIcons.flame, 'Calories', run.caloriesKcal != null && run.caloriesKcal! > 0 ? '${run.caloriesKcal!.toStringAsFixed(0)} kcal' : '—'),
                            _buildStatCard(retroColors, PhosphorIcons.footprints, 'Cadence', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${run.avgCadenceSpm!.toStringAsFixed(0)} spm' : '—'),
                            _buildStatCard(retroColors, PhosphorIcons.arrowsOutLineHorizontal, 'Stride', run.avgStrideLengthM != null && run.avgStrideLengthM! > 0 ? '${run.avgStrideLengthM!.toStringAsFixed(2)} m' : '—'),
                            _buildStatCard(retroColors, PhosphorIcons.personSimpleWalk, 'Total Steps', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${(run.avgCadenceSpm! * ((run.durationS ?? 0) / 60)).round()}' : '—'),
                          ],
                        );
                      },
                      loading: () => GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          _buildStatCard(retroColors, PhosphorIcons.chartLineUp, 'GAP', gapStr),
                          _buildStatCard(retroColors, PhosphorIcons.trendUp, 'Elevation', elevationStr),
                          _buildStatCard(retroColors, PhosphorIcons.flame, 'Calories', run.caloriesKcal != null && run.caloriesKcal! > 0 ? '${run.caloriesKcal!.toStringAsFixed(0)} kcal' : '—'),
                          _buildStatCard(retroColors, PhosphorIcons.footprints, 'Cadence', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${run.avgCadenceSpm!.toStringAsFixed(0)} spm' : '—'),
                          _buildStatCard(retroColors, PhosphorIcons.arrowsOutLineHorizontal, 'Stride', run.avgStrideLengthM != null && run.avgStrideLengthM! > 0 ? '${run.avgStrideLengthM!.toStringAsFixed(2)} m' : '—'),
                          _buildStatCard(retroColors, PhosphorIcons.personSimpleWalk, 'Total Steps', '—'),
                        ],
                      ),
                      error: (_, __) => const SizedBox.shrink(),
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
                                  Icon(PhosphorIcons.sparkleFill, color: retroColors.accent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'COACH INTEL',
                                    style: AppTextStyles.labelCaps(color: retroColors.accent).copyWith(fontSize: 11),
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
                  loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        if (_isDeleting || _isExporting)
          Container(
            color: retroColors.background.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: retroColors.accent),
                  if (_isExporting) ...[
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

  Widget _buildShoeThumbnail(String? imageUrl, AppColors colors) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final trimmed = imageUrl.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            color: colors.surfaceRaised,
            child: CachedNetworkImage(
              imageUrl: trimmed,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              placeholder: (_, __) => Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                ),
              ),
              errorWidget: (_, __, ___) => Icon(PhosphorIcons.sneaker, color: colors.textSecondary, size: 20),
            ),
          ),
        );
      } else {
        try {
          final cleanPath = trimmed.startsWith('file://') ? Uri.parse(trimmed).toFilePath() : trimmed;
          final file = File(cleanPath);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                color: colors.surfaceRaised,
                child: Image.file(
                  file,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(PhosphorIcons.sneaker, color: colors.textSecondary, size: 20),
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Failed to load local shoe photo: $e');
        }
      }
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Icon(PhosphorIcons.sneaker, color: colors.accent, size: 20),
    );
  }

  double? _computeElevationGainFromPoints(List<RunPointIsar> points) {
    if (points.length < 3) return null;
    double gain = 0.0;
    for (int i = 2; i < points.length; i++) {
      final alt0 = points[i - 2].elevation ?? 0.0;
      final alt1 = points[i - 1].elevation ?? 0.0;
      final alt2 = points[i].elevation ?? 0.0;
      final smoothedPrev = (alt0 + alt1) / 2.0;
      final smoothedCurr = (alt1 + alt2) / 2.0;
      final diff = smoothedCurr - smoothedPrev;
      if (diff > 0.3) {
        gain += diff;
      }
    }
    return gain > 0 ? gain : null;
  }

  Widget _buildStatCard(
    AppColors colors, 
    IconData icon, 
    String label, 
    String value, {
    String? tooltipMessage,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tooltipMessage != null) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: tooltipMessage,
                  triggerMode: TooltipTriggerMode.tap,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  textStyle: AppTextStyles.bodyMedium(color: colors.textPrimary),
                  child: Icon(PhosphorIcons.info, color: colors.textSecondary, size: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

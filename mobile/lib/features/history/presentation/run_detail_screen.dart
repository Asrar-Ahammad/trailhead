import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/static_route_map.dart';
import '../../../shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_splits_table.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_charts_section.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import '../application/gpx_export_util.dart';
import '../application/share_image_generator.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/results_section.dart';
import 'package:intl/intl.dart';

final runRawPointsProvider = FutureProvider.family<List<RunPointIsar>, String>((ref, clientRunId) async {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.getRunPoints(clientRunId);
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

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final run = widget.run;
    
    final date = run.startTime != null 
        ? DateFormat('MMMM d, yyyy • h:mm a').format(run.startTime!)
        : 'Unknown Date';
    
    final distanceKm = (run.distanceM ?? 0) / 1000;
    final durationMins = ((run.durationS ?? 0) / 60).floor();
    final durationSecs = ((run.durationS ?? 0) % 60).toString().padLeft(2, '0');
    final paceMins = ((run.avgPaceSPerKm ?? 0) / 60).floor();
    final paceSecs = ((run.avgPaceSPerKm ?? 0) % 60).floor().toString().padLeft(2, '0');

    final rawPointsAsync = run.clientRunId != null
        ? ref.watch(runRawPointsProvider(run.clientRunId!))
        : const AsyncValue.data(<RunPointIsar>[]);

    final pointsAsync = run.clientRunId != null 
        ? ref.watch(runPointsProvider(run.clientRunId!)) 
        : const AsyncValue.data(<LatLng>[]);

    final activityStr = (run.activityType ?? 'run').toUpperCase();
    final titleText = '$activityStr DETAILS';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: retroColors.background,
          appBar: AppBar(
        title: Text(titleText, style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 24)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.shareNetwork(), color: retroColors.textPrimary),
            tooltip: 'Share Activity Image',
            onPressed: () async {
              if (run.clientRunId == null) return;
              final repo = ref.read(runHistoryRepositoryProvider);
              final points = await repo.getRunPoints(run.clientRunId!);
              if (points.isNotEmpty && context.mounted) {
                try {
                  final latLngPoints = points.map((p) => LatLng(p.lat ?? 0.0, p.lng ?? 0.0)).toList();
                  await ShareImageGenerator.generateAndShareImage(run, latLngPoints);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to share image: $e')),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.download(), color: retroColors.textPrimary),
            tooltip: 'Export GPX',
            onPressed: () async {
              if (run.clientRunId == null) return;
              final repo = ref.read(runHistoryRepositoryProvider);
              final points = await repo.getRunPoints(run.clientRunId!);
              if (points.isNotEmpty && context.mounted) {
                try {
                  await GpxExportUtil.exportAndShareRun(run, points);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to export GPX: $e')),
                    );
                  }
                }
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical(), color: retroColors.textPrimary),
            color: retroColors.surface,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: retroColors.surface,
                          title: Text('Delete Run?', style: AppTextStyles.title(color: retroColors.textPrimary)),
                          content: Text('This action cannot be undone.', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
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
                          await repo.deleteRun(run.id);
                          ref.invalidate(historyProvider);
                          ref.invalidate(prsProvider);
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isDeleting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.trash(), color: retroColors.error, size: 20),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Static Route Map
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: retroColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: retroColors.border, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: pointsAsync.when(
                  data: (points) => points.isEmpty
                      ? Center(child: Text('No route data', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)))
                      : StaticRouteMap(points: points),
                  loading: () => const Center(child: RetroLoadingIndicator(text: 'LOADING MAP')),
                  error: (_, __) => Center(child: Text('Map error', style: AppTextStyles.bodyMedium(color: retroColors.error))),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header Stats
            Text(
              date,
              style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              RunFormatUtils.getRunTitle(
                run.title, 
                run.startTime, 
                activityType: run.activityType ?? 'run',
                distanceM: run.distanceM,
                subjectiveEffort: run.subjectiveEffort,
                conditions: run.conditions,
              ),
              style: AppTextStyles.headline(color: retroColors.textPrimary).copyWith(fontSize: 32),
            ),
            const SizedBox(height: 24),
            
            // Stat Grid
            rawPointsAsync.when(
              data: (rawPoints) {
                // Compute elevation gain from raw points as fallback
                double? elevationGain = (run.elevationGainM != null && run.elevationGainM! > 0)
                    ? run.elevationGainM
                    : _computeElevationGainFromPoints(rawPoints);
                final String elevationStr = (elevationGain != null && elevationGain > 0)
                    ? '${elevationGain.toStringAsFixed(0)} m'
                    : '—';
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _buildStatCard(retroColors, PhosphorIcons.ruler(), 'Distance', '${distanceKm.toStringAsFixed(2)} km'),
                    _buildStatCard(retroColors, PhosphorIcons.timer(), 'Duration', '${durationMins}:${durationSecs}'),
                    _buildStatCard(retroColors, PhosphorIcons.sneaker(), 'Avg Pace', '${paceMins}:${paceSecs} /km'),
                    _buildStatCard(retroColors, PhosphorIcons.flame(), 'Calories', run.caloriesKcal != null && run.caloriesKcal! > 0 ? '${run.caloriesKcal!.toStringAsFixed(0)} kcal (est)' : '—'),
                    _buildStatCard(retroColors, PhosphorIcons.trendUp(), 'Elevation', elevationStr),
                    _buildStatCard(retroColors, PhosphorIcons.footprints(), 'Cadence', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${run.avgCadenceSpm!.toStringAsFixed(0)} spm' : '—'),
                    _buildStatCard(retroColors, PhosphorIcons.arrowsOutLineHorizontal(), 'Stride', run.avgStrideLengthM != null && run.avgStrideLengthM! > 0 ? '${run.avgStrideLengthM!.toStringAsFixed(2)} m' : '—'),
                    _buildStatCard(retroColors, PhosphorIcons.personSimpleWalk(), 'Total Steps', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${(run.avgCadenceSpm! * ((run.durationS ?? 0) / 60)).round()}' : '—'),
                  ],
                );
              },
              loading: () => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildStatCard(retroColors, PhosphorIcons.ruler(), 'Distance', '${distanceKm.toStringAsFixed(2)} km'),
                  _buildStatCard(retroColors, PhosphorIcons.timer(), 'Duration', '${durationMins}:${durationSecs}'),
                  _buildStatCard(retroColors, PhosphorIcons.sneaker(), 'Avg Pace', '${paceMins}:${paceSecs} /km'),
                  _buildStatCard(retroColors, PhosphorIcons.flame(), 'Calories', run.caloriesKcal != null && run.caloriesKcal! > 0 ? '${run.caloriesKcal!.toStringAsFixed(0)} kcal (est)' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.trendUp(), 'Elevation', run.elevationGainM != null && run.elevationGainM! > 0 ? '${run.elevationGainM!.toStringAsFixed(0)} m' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.footprints(), 'Cadence', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${run.avgCadenceSpm!.toStringAsFixed(0)} spm' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.arrowsOutLineHorizontal(), 'Stride', run.avgStrideLengthM != null && run.avgStrideLengthM! > 0 ? '${run.avgStrideLengthM!.toStringAsFixed(2)} m' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.personSimpleWalk(), 'Total Steps', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${(run.avgCadenceSpm! * ((run.durationS ?? 0) / 60)).round()}' : '—'),
                ],
              ),
              error: (_, __) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildStatCard(retroColors, PhosphorIcons.ruler(), 'Distance', '${distanceKm.toStringAsFixed(2)} km'),
                  _buildStatCard(retroColors, PhosphorIcons.timer(), 'Duration', '${durationMins}:${durationSecs}'),
                  _buildStatCard(retroColors, PhosphorIcons.sneaker(), 'Avg Pace', '${paceMins}:${paceSecs} /km'),
                  _buildStatCard(retroColors, PhosphorIcons.flame(), 'Calories', run.caloriesKcal != null && run.caloriesKcal! > 0 ? '${run.caloriesKcal!.toStringAsFixed(0)} kcal (est)' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.trendUp(), 'Elevation', run.elevationGainM != null && run.elevationGainM! > 0 ? '${run.elevationGainM!.toStringAsFixed(0)} m' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.footprints(), 'Cadence', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${run.avgCadenceSpm!.toStringAsFixed(0)} spm' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.arrowsOutLineHorizontal(), 'Stride', run.avgStrideLengthM != null && run.avgStrideLengthM! > 0 ? '${run.avgStrideLengthM!.toStringAsFixed(2)} m' : '—'),
                  _buildStatCard(retroColors, PhosphorIcons.personSimpleWalk(), 'Total Steps', run.avgCadenceSpm != null && run.avgCadenceSpm! > 0 ? '${(run.avgCadenceSpm! * ((run.durationS ?? 0) / 60)).round()}' : '—'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Splits Table
            rawPointsAsync.when(
              data: (points) => RunSplitsTable(points: points),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 32),

            // Results Section
            ResultsSection(run: run),

            const SizedBox(height: 32),
            
            // AI Summary
            if (run.aiSummary != null && run.aiSummary!.isNotEmpty) ...[
              Text('AI COACH SUMMARY', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: retroColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: retroColors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  run.aiSummary!,
                  style: AppTextStyles.bodyLarge(color: retroColors.textPrimary),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Charts Section
            rawPointsAsync.when(
              data: (points) => RunChartsSection(run: run, points: points),
              loading: () => const Center(child: RetroLoadingIndicator(text: 'LOADING LOGS')),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    if (_isDeleting)
      Container(
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: RetroLoadingIndicator(text: 'DELETING RUN'),
        ),
      ),
  ],
);
  }

  /// Computes elevation gain from raw GPS points using a 3-point smoothing
  /// window — mirrors the algorithm used during live tracking.
  double? _computeElevationGainFromPoints(List<RunPointIsar> points) {
    final elevPoints = points.where((p) => p.elevation != null && !p.isPaused).toList();
    if (elevPoints.length < 3) return null;

    double gain = 0.0;
    final List<double> buffer = [];
    double? lastSmoothed;

    for (final point in elevPoints) {
      buffer.add(point.elevation!);
      if (buffer.length > 3) buffer.removeAt(0);
      if (buffer.length == 3) {
        final smoothed = buffer.reduce((a, b) => a + b) / 3.0;
        if (lastSmoothed != null) {
          final delta = smoothed - lastSmoothed;
          if (delta > 0) gain += delta;
        }
        lastSmoothed = smoothed;
      }
    }
    return gain > 0 ? gain : null;
  }

  Widget _buildStatCard(AppColors colors, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                Text(value, style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

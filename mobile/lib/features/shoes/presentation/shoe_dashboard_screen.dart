import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:isar/isar.dart';
import '../data/models/shoe_isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../../main.dart'; // isarInstance
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';

final shoeRunsProvider = FutureProvider.family<List<RunIsar>, String>((ref, shoeId) async {
  return await isarInstance!.runIsars
      .filter()
      .clientShoeIdEqualTo(shoeId)
      .statusEqualTo('completed')
      .sortByStartTimeDesc()
      .findAll();
});

class ShoeDashboardScreen extends ConsumerWidget {
  final ShoeIsar shoe;

  const ShoeDashboardScreen({super.key, required this.shoe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final runsAsync = ref.watch(shoeRunsProvider(shoe.clientShoeId!));
    final useMiles = ref.watch(distanceUnitProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(shoe.name ?? 'Gear Stats', style: AppTextStyles.headline(color: colors.textPrimary)),
      ),
      body: runsAsync.when(
        data: (runs) {
          int totalRuns = runs.length;
          double maxDistanceM = 0;
          double totalDurationS = 0;
          
          for (final run in runs) {
            if (run.distanceM != null && run.distanceM! > maxDistanceM) {
              maxDistanceM = run.distanceM!;
            }
            if (run.durationS != null) {
              totalDurationS += run.durationS!;
            }
          }
          
          final distanceKm = shoe.distanceM / 1000.0;
          final distanceMi = distanceKm * 0.621371;
          final displayDistance = useMiles ? distanceMi : distanceKm;
          final distUnit = useMiles ? 'mi' : 'km';
          
          final maxDistKm = maxDistanceM / 1000.0;
          final displayMaxDist = useMiles ? (maxDistKm * 0.621371) : maxDistKm;
          
          final avgPaceSPerKm = (shoe.distanceM > 0) ? (totalDurationS / (shoe.distanceM / 1000.0)) : 0.0;
          final formattedAvgPace = avgPaceSPerKm > 0 
              ? RunFormatUtils.formatPace(shoe.distanceM, totalDurationS.toInt(), useMiles)
              : '--:--';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorIcons.sneaker(), color: colors.accent, size: 64),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    shoe.name ?? 'Unknown Shoe',
                    style: AppTextStyles.displayMedium(color: colors.textPrimary),
                  ),
                ),
                if (shoe.brand != null && shoe.brand!.isNotEmpty)
                  Center(
                    child: Text(
                      shoe.brand!,
                      style: AppTextStyles.bodyLarge(color: colors.textSecondary),
                    ),
                  ),
                  
                const SizedBox(height: 32),
                
                // Stat Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(colors, 'TOTAL DISTANCE', '${displayDistance.toStringAsFixed(1)} $distUnit'),
                    _buildStatCard(colors, 'TOTAL RUNS', '$totalRuns'),
                    _buildStatCard(colors, 'AVERAGE PACE', '$formattedAvgPace / $distUnit'),
                    _buildStatCard(colors, 'LONGEST RUN', '${displayMaxDist.toStringAsFixed(1)} $distUnit'),
                  ],
                ),
                
                const SizedBox(height: 32),
                Text('RECENT ACTIVITY', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
                const SizedBox(height: 16),
                
                if (runs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No runs tracked with this gear yet.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                    ),
                  )
                else
                  ...runs.take(5).map((run) {
                    final runDistKm = (run.distanceM ?? 0) / 1000.0;
                    final runDisplayDist = useMiles ? (runDistKm * 0.621371) : runDistKm;
                    
                    final dateStr = run.startTime != null 
                        ? '${run.startTime!.year}-${run.startTime!.month.toString().padLeft(2, '0')}-${run.startTime!.day.toString().padLeft(2, '0')}'
                        : 'Unknown Date';
                        
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        leading: Icon(PhosphorIcons.personSimpleRun(), color: colors.accent),
                        title: Text(run.title ?? 'Run', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
                        subtitle: Text(dateStr, style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                        trailing: Text('${runDisplayDist.toStringAsFixed(2)} $distUnit', style: AppTextStyles.title(color: colors.textPrimary)),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading stats: $err', style: TextStyle(color: colors.error))),
      ),
    );
  }
  
  Widget _buildStatCard(AppColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.label(color: colors.textSecondary)),
          const Spacer(),
          Text(value, style: AppTextStyles.headline(color: colors.textPrimary)),
        ],
      ),
    );
  }
}

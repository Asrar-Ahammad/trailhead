import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/stats/application/pr_engine.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class ResultsSection extends ConsumerWidget {
  final RunIsar run;

  const ResultsSection({super.key, required this.run});

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  Color _getMedalColor(int rank, AppColors colors) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return colors.accent;
    }
  }

  String _formatValue(String category, double value) {
    if (category == 'longest_run') {
      return '${(value / 1000).toStringAsFixed(2)} km';
    } else if (category == 'max_elevation') {
      return '${value.toStringAsFixed(0)} m';
    }

    final mins = (value / 60).floor();
    final secs = (value % 60).floor();
    if (mins >= 60) {
      final hours = (mins / 60).floor();
      final remainingMins = mins % 60;
      return '${hours}:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
  
  String _formatPace(String category, double value) {
    // For distance based categories, calculate pace
    double distanceM = 0;
    if (category == '100m') distanceM = 100;
    else if (category == '400m') distanceM = 400;
    else if (category == '1k') distanceM = 1000;
    else if (category == '1 mile') distanceM = 1609.34;
    else if (category == '5k') distanceM = 5000;
    else if (category == '10k') distanceM = 10000;
    else if (category == 'half') distanceM = 21097.5;
    else if (category == 'marathon') distanceM = 42195;
    
    if (distanceM > 0) {
      final paceSPerKm = value / (distanceM / 1000);
      final paceMins = (paceSPerKm / 60).floor();
      final paceSecs = (paceSPerKm % 60).floor().toString().padLeft(2, '0');
      return '$paceMins:$paceSecs /km';
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final prsAsync = ref.watch(prsProvider);

    return prsAsync.when(
      data: (group) {
        final runPrs = group.bestEffort.where((pr) => pr.runId == run.clientRunId).toList();
        
        if (runPrs.isEmpty) return const SizedBox.shrink();

        // Sort by category distance/order ideally, but sorting by rank or name for now
        runPrs.sort((a, b) => a.category.compareTo(b.category));

        final achievementsCount = runPrs.where((pr) => pr.rank <= 3).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results', style: AppTextStyles.headline(color: retroColors.textPrimary).copyWith(fontSize: 24)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Best Efforts', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('${runPrs.length}', style: AppTextStyles.headline(color: retroColors.textPrimary).copyWith(fontSize: 24)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Achievements', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('$achievementsCount', style: AppTextStyles.headline(color: retroColors.textPrimary).copyWith(fontSize: 24)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ...runPrs.map((pr) {
              final formattedTitle = pr.category.toUpperCase();
              final timeStr = _formatValue(pr.category, pr.value);
              final paceStr = _formatPace(pr.category, pr.value);
              final isTop3 = pr.rank <= 3 && pr.rank > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTop3)
                      Icon(PhosphorIcons.medal(PhosphorIconsStyle.fill), color: _getMedalColor(pr.rank, retroColors), size: 40)
                    else
                      Icon(PhosphorIcons.sneaker(PhosphorIconsStyle.regular), color: retroColors.textSecondary, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedTitle, style: AppTextStyles.bodyLarge(color: retroColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(timeStr, style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                              if (paceStr.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text(paceStr, style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                              ],
                            ],
                          ),
                          if (isTop3) ...[
                            const SizedBox(height: 4),
                            Text(
                              'New ${_getOrdinal(pr.rank)} best of ${pr.achievedAt.year}!',
                              style: AppTextStyles.bodyMedium(color: retroColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

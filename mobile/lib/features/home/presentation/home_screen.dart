import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/stats/application/weekly_stats_provider.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';

import '../../haptics/application/haptics_service.dart';
import '../../navigation/presentation/main_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final summaryAsync = ref.watch(weeklySummaryProvider);
    
    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('TRAILHEAD', style: AppTextStyles.retroLabel(color: retroColors.textPrimary).copyWith(fontSize: 20)),
        backgroundColor: retroColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryAsync.when(
              data: (summary) => _buildContent(context, ref, retroColors, summary),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: \$err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppColors retroColors, WeeklySummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('WEEKLY SUMMARY', style: AppTextStyles.headline(color: retroColors.textPrimary).copyWith(fontSize: 26)),
            if (summary.streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: retroColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: retroColors.accent),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.flame(PhosphorIconsStyle.fill), color: retroColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('${summary.streakDays} Day Streak', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Stat Cards Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'DISTANCE',
                value: summary.distanceKm.toStringAsFixed(1),
                unit: 'KM',
                icon: PhosphorIcons.ruler(),
                colors: retroColors,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                title: 'RUNS',
                value: summary.runCount.toString(),
                unit: '',
                icon: PhosphorIcons.sneaker(),
                colors: retroColors,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
            
            Text('DISTANCE OVER TIME', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.md),
            
            // Chart Container
            Container(
              height: 250,
              padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: retroColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: retroColors.border),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()], 
                              style: AppTextStyles.retroLabel(color: retroColors.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min || value == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()} km',
                              style: AppTextStyles.retroLabel(color: retroColors.textSecondary),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: retroColors.border,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return _buildBar(index, summary.chartData[index], retroColors);
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('QUICK START', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: retroColors.accent,
                      foregroundColor: retroColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(PhosphorIcons.play()),
                    label: Text('START RUN', style: AppTextStyles.bodyLargeBold()),
                    onPressed: () {
                      ref.read(hapticsServiceProvider).lightImpact();
                      ref.read(navigationProvider.notifier).state = 1; // Jump to record tab
                    },
                  ),
                ),
              ],
            ),
            
            if (summary.mostRecentRun != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('MOST RECENT RUN', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
              const SizedBox(height: AppSpacing.md),
              Card(
                color: retroColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RunDetailScreen(run: summary.mostRecentRun!),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: retroColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill), color: retroColors.accent),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.mostRecentRun!.title ?? 'Morning Run',
                                style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${((summary.mostRecentRun!.distanceM ?? 0) / 1000).toStringAsFixed(2)} km',
                                style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(PhosphorIcons.caretRight(), color: retroColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
  }

  BarChartGroupData _buildBar(int x, double y, AppColors colors) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: colors.accent,
          width: 16,
          borderRadius: BorderRadius.zero, // Sharp 8-bit aesthetic
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final AppColors colors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.retroLabel(color: colors.textSecondary)),
              Icon(icon, color: colors.textDisabled, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.displayMedium(color: colors.textPrimary)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(unit, style: AppTextStyles.retroLabel(color: colors.textSecondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

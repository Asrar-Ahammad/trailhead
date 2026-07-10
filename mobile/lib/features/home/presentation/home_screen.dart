import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/stats/application/weekly_stats_provider.dart';
import 'package:trailhead_mobile/features/stats/application/ai_coach_provider.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import '../../run_tracking/application/run_format_utils.dart';

import '../../haptics/application/haptics_service.dart';
import '../../navigation/presentation/main_scaffold.dart';
import '../../audio/application/sound_service.dart';

import 'package:trailhead_mobile/features/chat/presentation/chat_screen.dart';
import 'package:trailhead_mobile/features/weather/presentation/weather_pace_card.dart';
import 'package:trailhead_mobile/features/weather/application/weather_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final aiCoachAsync = ref.watch(aiCoachProvider);
    
    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('HOME', style: AppTextStyles.retroLabel(color: retroColors.textPrimary).copyWith(fontSize: 32)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        actions: [
          ref.watch(weatherPacingProvider).maybeWhen(
            data: (data) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  (data['city'] as String).toUpperCase(),
                  style: AppTextStyles.retroLabel(color: retroColors.textSecondary).copyWith(fontSize: 14),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          top: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 240.0, // extra padding so content scrolls past FAB
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryAsync.when(
              data: (summary) => _buildContent(context, ref, retroColors, summary, aiCoachAsync),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: \$err')),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0, right: 8.0),
        child: FloatingActionButton(
          heroTag: 'chat_fab',
          elevation: 0,
          highlightElevation: 0,
          onPressed: () {
            ref.read(hapticsServiceProvider).mediumImpact();
            ref.read(soundServiceProvider).playButtonTap();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
          },
          backgroundColor: retroColors.accent,
          child: Icon(PhosphorIcons.chat(PhosphorIconsStyle.fill), color: retroColors.background),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppColors retroColors, WeeklySummary summary, AsyncValue<AiCoachData> aiCoachAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('WEEKLY SUMMARY', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 26, letterSpacing: 2.0)),
            if (summary.streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: retroColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
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
                title: 'ACTIVITIES',
                value: summary.runCount.toString(),
                unit: '',
                icon: PhosphorIcons.sneakerMove(),
                colors: retroColors,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        aiCoachAsync.when(
          data: (coachData) {
            final hasFlag = coachData.fatigueFlag != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('AI COACH', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: retroColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hasFlag ? retroColors.error : retroColors.accent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasFlag) ...[
                        Row(
                          children: [
                            Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), color: retroColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(coachData.fatigueFlag!, style: AppTextStyles.bodyMediumBold(color: retroColors.error))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(PhosphorIcons.robot(PhosphorIconsStyle.fill), color: retroColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              coachData.coachingFeedback,
                              style: AppTextStyles.bodyMedium(color: retroColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
            
        Text('DISTANCE OVER TIME', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.md),
            
            // Chart Container
            Container(
              height: 250,
              padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.sm),
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
                        reservedSize: 32,
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

            const WeatherPaceCard(),
            const SizedBox(height: AppSpacing.xl),

            Text('QUICK START', style: AppTextStyles.retroLabel(color: retroColors.accent).copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: retroColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('START RUN / WALK', style: AppTextStyles.bodyLargeBold(color: Colors.white)),
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: retroColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    ref.read(soundServiceProvider).playActivityTap();
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
                                RunFormatUtils.getRunTitle(summary.mostRecentRun!.title, summary.mostRecentRun!.startTime, activityType: summary.mostRecentRun!.activityType ?? 'run'),
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

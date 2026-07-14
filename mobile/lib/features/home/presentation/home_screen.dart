import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
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

import 'package:trailhead_mobile/features/shoes/presentation/shoe_management_screen.dart';
import 'package:trailhead_mobile/features/home/presentation/widgets/goals_progress_card.dart';
import 'package:trailhead_mobile/features/chat/presentation/chat_screen.dart';
import 'package:trailhead_mobile/features/weather/presentation/weather_pace_card.dart';
import 'package:trailhead_mobile/features/weather/application/weather_service.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';

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
        title: Text('HOME', style: AppTextStyles.headline(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        actions: [
          ref.watch(weatherPacingProvider).maybeWhen(
            data: (data) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  (data['city'] as String).toUpperCase(),
                  style: AppTextStyles.label(color: retroColors.textSecondary),
                ),
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: RetroButtonLoadingIndicator(color: retroColors.textSecondary),
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
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: RetroLoadingIndicator(text: 'FETCHING RUNS'),
              ),
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
          child: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: retroColors.background),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppColors retroColors, WeeklySummary summary, AsyncValue<AiCoachData> aiCoachAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SmoothFadeIn(
          delayMs: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY SUMMARY', style: AppTextStyles.title(color: retroColors.textPrimary)),
              if (summary.streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: retroColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: retroColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.flame(PhosphorIconsStyle.fill), color: retroColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text('${summary.streakDays} Day Streak', style: AppTextStyles.label(color: retroColors.accent)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Stat Cards Row
        SmoothFadeIn(
          delayMs: 100,
          child: Row(
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
        ),
        const SizedBox(height: AppSpacing.xl),

        SmoothFadeIn(
          delayMs: 200,
          child: aiCoachAsync.when(
            data: (coachData) {
              final hasFlag = coachData.fatigueFlag != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('AI COACH', style: AppTextStyles.label(color: retroColors.accent)),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: retroColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: retroColors.border.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
              child: RetroLoadingIndicator(text: 'COACH IS ANALYZING'),
            ),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ),
            
        SmoothFadeIn(
          delayMs: 250,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: GoalsProgressCard(retroColors: retroColors),
          ),
        ),

        SmoothFadeIn(
          delayMs: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('DISTANCE OVER TIME', style: AppTextStyles.label(color: retroColors.accent)),
              const SizedBox(height: AppSpacing.md),
              
              // Chart Container
              SizedBox(
                height: 250,
                child: Container(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: retroColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: retroColors.border.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
                                style: AppTextStyles.label(color: retroColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56, // Increased to prevent wrapping
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max || value == meta.min || value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '${RunFormatUtils.formatDistance(value * 1000, ref.watch(distanceUnitProvider))} ${RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))}',
                                style: AppTextStyles.label(color: retroColors.textSecondary),
                                textAlign: TextAlign.right,
                                maxLines: 1,
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
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SmoothFadeIn(delayMs: 400, child: WeatherPaceCard()),
        const SizedBox(height: AppSpacing.xl),

        SmoothFadeIn(
          delayMs: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('QUICK START', style: AppTextStyles.label(color: retroColors.accent)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: retroColors.accent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: retroColors.accent.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            ref.read(hapticsServiceProvider).lightImpact();
                            ref.read(soundServiceProvider).playButtonTap();
                            ref.read(navigationProvider.notifier).state = 1; // Jump to record tab
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('START RUN / WALK', style: AppTextStyles.title(color: retroColors.background)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (summary.mostRecentRun != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SmoothFadeIn(
            delayMs: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MOST RECENT RUN', style: AppTextStyles.label(color: retroColors.accent)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: retroColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: retroColors.border.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
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
                                color: retroColors.accent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill), color: retroColors.accent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    RunFormatUtils.getRunTitle(
                                      summary.mostRecentRun!.title, 
                                      summary.mostRecentRun!.startTime, 
                                      activityType: summary.mostRecentRun!.activityType ?? 'run',
                                      distanceM: summary.mostRecentRun!.distanceM,
                                      subjectiveEffort: summary.mostRecentRun!.subjectiveEffort,
                                      conditions: summary.mostRecentRun!.conditions,
                                    ),
                                    style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    RunFormatUtils.formatDistance(summary.mostRecentRun!.distanceM ?? 0, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider)),
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
                ),
              ],
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
          width: 12,
          borderRadius: BorderRadius.circular(6),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.label(color: colors.textSecondary)),
              Icon(icon, color: colors.textPrimary, size: 16),
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
                Text(unit, style: AppTextStyles.label(color: colors.textSecondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SmoothFadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  
  const SmoothFadeIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<SmoothFadeIn> createState() => _SmoothFadeInState();
}

class _SmoothFadeInState extends State<SmoothFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint)
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint)
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint)
    );

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

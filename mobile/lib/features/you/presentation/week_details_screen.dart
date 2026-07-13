import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import 'package:trailhead_mobile/features/you/presentation/weekly_activities_screen.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';

class WeekDetailsScreen extends ConsumerStatefulWidget {
  final WeeklyReportModel report;

  const WeekDetailsScreen({super.key, required this.report});

  @override
  ConsumerState<WeekDetailsScreen> createState() => _WeekDetailsScreenState();
}

class _WeekDetailsScreenState extends ConsumerState<WeekDetailsScreen> {
  int? _touchedPaceSpotIndex;
  int? _touchedCadenceSpotIndex;

  @override
  Widget build(BuildContext context) {
    
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('WEEK ${widget.report.weekNumber}, ${widget.report.year}', style: AppTextStyles.title(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotalDistanceHeader(retroColors),
            const SizedBox(height: 24),
            Text('WEEKLY STATS', style: AppTextStyles.labelCaps(color: retroColors.accent)),
            const SizedBox(height: 16),
            _buildStatsGrid(retroColors),
            const SizedBox(height: 32),
            Text('DAILY AVERAGES', style: AppTextStyles.labelCaps(color: retroColors.accent)),
            const SizedBox(height: 16),
            _buildPaceChart(retroColors),
            const SizedBox(height: 24),
            _buildCadenceChart(retroColors),
            const SizedBox(height: 24),
            _buildActivitiesCard(context, retroColors),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDistanceHeader(AppColors retroColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('TOTAL DISTANCE', style: AppTextStyles.label(color: retroColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            RunFormatUtils.formatDistance(widget.report.totalDistanceM, ref.watch(distanceUnitProvider)) + ' ${RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))}',
            style: AppTextStyles.displayHero(color: retroColors.textPrimary).copyWith(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill(retroColors, PhosphorIcons.personSimpleRun(), '${widget.report.runCount} Runs'),
              const SizedBox(width: 12),
              _buildPill(retroColors, PhosphorIcons.personSimpleWalk(), '${widget.report.walkCount} Walks'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPill(AppColors retroColors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: retroColors.surfaceRaised,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: retroColors.accent, size: 16),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.bodyMediumBold(color: retroColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppColors retroColors) {
    final workoutTime = RunFormatUtils.formatDuration(widget.report.totalDurationS);
    final avgPace = RunFormatUtils.formatPace(widget.report.totalDistanceM, widget.report.totalDurationS, ref.watch(distanceUnitProvider));
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.fire(), 'Calories', '${widget.report.totalCalories.round()} kcal')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.sneaker(), 'Steps', '${widget.report.totalSteps}')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.timer(), 'Duration', workoutTime)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.lightning(), 'Avg Pace', '$avgPace/km')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.chartLine(), 'Avg Cadence', '${widget.report.avgCadenceSpm.round()} spm')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.ruler(), 'Avg Stride', '${widget.report.avgStrideLengthM.toStringAsFixed(2)} m')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(AppColors retroColors, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: retroColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.label(color: retroColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.headline(color: retroColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActivitiesCard(BuildContext context, AppColors retroColors) {
    return Container(
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            ref.read(soundServiceProvider).playActivitiesCardTap();
            ref.read(hapticsServiceProvider).lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyActivitiesScreen(report: widget.report)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(PhosphorIcons.listBullets(PhosphorIconsStyle.fill), color: retroColors.accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activities', style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'View workouts for this week',
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
    );
  }

  Widget _buildPaceChart(AppColors retroColors) {
    // We want to show a bar chart of avg pace per day. Pace is in seconds/km.
    // Lower pace is better (faster). So maybe we flip the Y axis or just show it as is.
    
    // Sort dailyStats to be Mon (0) to Sun (6)
    final sortedStats = List.from(widget.report.dailyStats)..sort((a, b) => (a as DailyStat).day.compareTo((b as DailyStat).day));
    
    double maxY = 0;
    for (DailyStat stat in sortedStats) {
      final paceMin = stat.avgPace / 60;
      if (paceMin > maxY) maxY = paceMin;
    }
    
    if (maxY == 0) maxY = 10;
    
    return _buildChartContainer(
      retroColors,
      title: 'Pace (min/km)',
      icon: PhosphorIcons.lightning(),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxY * 1.2,
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (touchResponse != null && touchResponse.lineBarSpots != null && touchResponse.lineBarSpots!.isNotEmpty) {
                final index = touchResponse.lineBarSpots![0].spotIndex;
                if (_touchedPaceSpotIndex != index) {
                  _touchedPaceSpotIndex = index;
                  ref.read(hapticsServiceProvider).lightImpact();
                }
              } else if (event is FlPanEndEvent || event is FlPanCancelEvent || (event is FlPointerHoverEvent && touchResponse?.lineBarSpots == null)) {
                _touchedPaceSpotIndex = null;
              }
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.blue, strokeWidth: 2),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.blue, strokeWidth: 0),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              showOnTopOfTheChartBoxArea: true,
              tooltipMargin: 8,
              getTooltipColor: (touchedSpot) => Colors.blue,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final mins = spot.y.floor();
                  final secs = ((spot.y - mins) * 60).round();
                  return LineTooltipItem(
                    '${mins}:${secs.toString().padLeft(2, '0')} /km',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < 0 || value.toInt() >= 7) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()], 
                      style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  final mins = value.floor();
                  final secs = ((value - mins) * 60).round();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${mins}:${secs.toString().padLeft(2, '0')}',
                      style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
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
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(7, (index) {
                final stat = sortedStats.firstWhere((s) => (s as DailyStat).day == index, orElse: () => DailyStat(day: index, avgPace: 0, avgCadence: 0)) as DailyStat;
                return FlSpot(index.toDouble(), stat.avgPace / 60);
              }).where((spot) => spot.y > 0).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadenceChart(AppColors retroColors) {
    final sortedStats = List.from(widget.report.dailyStats)..sort((a, b) => (a as DailyStat).day.compareTo((b as DailyStat).day));
    
    double maxY = 0;
    for (DailyStat stat in sortedStats) {
      if (stat.avgCadence > maxY) maxY = stat.avgCadence;
    }
    
    if (maxY == 0) maxY = 180;
    
    return _buildChartContainer(
      retroColors,
      title: 'Cadence (spm)',
      icon: PhosphorIcons.chartLine(),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxY * 1.2,
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (touchResponse != null && touchResponse.lineBarSpots != null && touchResponse.lineBarSpots!.isNotEmpty) {
                final index = touchResponse.lineBarSpots![0].spotIndex;
                if (_touchedCadenceSpotIndex != index) {
                  _touchedCadenceSpotIndex = index;
                  ref.read(hapticsServiceProvider).lightImpact();
                }
              } else if (event is FlPanEndEvent || event is FlPanCancelEvent || (event is FlPointerHoverEvent && touchResponse?.lineBarSpots == null)) {
                _touchedCadenceSpotIndex = null;
              }
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.pink, strokeWidth: 2),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.pink, strokeWidth: 0),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              showOnTopOfTheChartBoxArea: true,
              tooltipMargin: 8,
              getTooltipColor: (touchedSpot) => Colors.pink,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.round()} spm',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < 0 || value.toInt() >= 7) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()], 
                      style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
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
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(7, (index) {
                final stat = sortedStats.firstWhere((s) => (s as DailyStat).day == index, orElse: () => DailyStat(day: index, avgPace: 0, avgCadence: 0)) as DailyStat;
                return FlSpot(index.toDouble(), stat.avgCadence);
              }).where((spot) => spot.y > 0).toList(),
              isCurved: true,
              color: Colors.pink,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.pink.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(AppColors retroColors, {required String title, required IconData icon, required Widget child}) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: retroColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.label(color: retroColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

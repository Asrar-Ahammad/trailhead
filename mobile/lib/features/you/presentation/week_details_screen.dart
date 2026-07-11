import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import 'package:trailhead_mobile/features/you/presentation/weekly_activities_screen.dart';

class WeekDetailsScreen extends StatelessWidget {
  final WeeklyReportModel report;

  const WeekDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('WEEK ${report.weekNumber}, ${report.year}', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 22)),
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
            Text('WEEKLY STATS', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
            const SizedBox(height: 16),
            _buildStatsGrid(retroColors),
            const SizedBox(height: 32),
            Text('DAILY AVERAGES', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: retroColors.accent.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text('TOTAL DISTANCE', style: AppTextStyles.label(color: retroColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            RunFormatUtils.formatDistanceKm(report.totalDistanceM) + ' km',
            style: AppTextStyles.displayHero(color: retroColors.textPrimary).copyWith(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill(retroColors, PhosphorIcons.personSimpleRun(), '${report.runCount} Runs'),
              const SizedBox(width: 12),
              _buildPill(retroColors, PhosphorIcons.personSimpleWalk(), '${report.walkCount} Walks'),
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
        borderRadius: BorderRadius.circular(20),
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
    final workoutTime = RunFormatUtils.formatDuration(report.totalDurationS);
    final avgPace = RunFormatUtils.formatPace(report.totalDistanceM, report.totalDurationS); // Using total for weighted average
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.fire(), 'Calories', '${report.totalCalories.round()} kcal')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.sneaker(), 'Steps', '${report.totalSteps}')),
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
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.chartLine(), 'Avg Cadence', '${report.avgCadenceSpm.round()} spm')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(retroColors, PhosphorIcons.ruler(), 'Avg Stride', '${report.avgStrideLengthM.toStringAsFixed(2)} m')),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: retroColors.border),
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
    return Card(
      color: retroColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: retroColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyActivitiesScreen(report: report)));
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
    );
  }

  Widget _buildPaceChart(AppColors retroColors) {
    // We want to show a bar chart of avg pace per day. Pace is in seconds/km.
    // Lower pace is better (faster). So maybe we flip the Y axis or just show it as is.
    
    // Sort dailyStats to be Mon (0) to Sun (6)
    final sortedStats = List.from(report.dailyStats)..sort((a, b) => (a as DailyStat).day.compareTo((b as DailyStat).day));
    
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
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: retroColors.textPrimary, strokeWidth: 2),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: retroColors.textPrimary, strokeWidth: 0),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              showOnTopOfTheChartBoxArea: true,
              tooltipMargin: 8,
              getTooltipColor: (touchedSpot) => retroColors.surfaceRaised,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final mins = spot.y.floor();
                  final secs = ((spot.y - mins) * 60).round();
                  return LineTooltipItem(
                    '${mins}:${secs.toString().padLeft(2, '0')} /km',
                    TextStyle(color: retroColors.accent, fontWeight: FontWeight.bold),
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
              color: retroColors.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: retroColors.accent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadenceChart(AppColors retroColors) {
    final sortedStats = List.from(report.dailyStats)..sort((a, b) => (a as DailyStat).day.compareTo((b as DailyStat).day));
    
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
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: retroColors.textPrimary, strokeWidth: 2),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: retroColors.textPrimary, strokeWidth: 0),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              showOnTopOfTheChartBoxArea: true,
              tooltipMargin: 8,
              getTooltipColor: (touchedSpot) => retroColors.surfaceRaised,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.round()} spm',
                    TextStyle(color: retroColors.accent, fontWeight: FontWeight.bold),
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
              color: retroColors.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: retroColors.accent.withOpacity(0.2),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: retroColors.border),
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

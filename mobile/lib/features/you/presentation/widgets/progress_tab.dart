import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/daily_activities_screen.dart';

class ProgressTab extends StatelessWidget {
  final List<RunIsar> runs;

  const ProgressTab({super.key, required this.runs});

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('12-WEEK PROGRESS', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
          const SizedBox(height: 16),
          _build12WeekChart(retroColors),
          
          const SizedBox(height: 32),
          
          Text('THIS MONTH', style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
          const SizedBox(height: 16),
          _buildMonthlyCalendar(context, retroColors),
        ],
      ),
    );
  }

  Widget _build12WeekChart(AppColors retroColors) {
    // Generate 12 weeks of data
    final chartData = List.filled(12, 0.0);
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    for (final run in runs) {
      if (run.startTime == null) continue;
      final actualWeeksAgo = run.startTime!.isAfter(startOfThisWeek) ? 0 : ((startOfThisWeek.difference(run.startTime!).inDays) ~/ 7) + 1;

      if (actualWeeksAgo < 12) {
        chartData[11 - actualWeeksAgo] += (run.distanceM ?? 0) / 1000.0;
      }
    }

    double maxY = 10;
    for (final val in chartData) {
      if (val > maxY) maxY = val + 5;
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: retroColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 3 != 0) return const SizedBox.shrink(); // Show every 3rd week label
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'W${12 - value.toInt()}', 
                      style: AppTextStyles.label(color: retroColors.textSecondary),
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
          barGroups: List.generate(12, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: chartData[index],
                  color: retroColors.accent,
                  width: 12,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar(BuildContext context, AppColors retroColors) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    final runDays = <int>{};
    for (final run in runs) {
      if (run.startTime != null && run.startTime!.year == now.year && run.startTime!.month == now.month) {
        runDays.add(run.startTime!.day);
      }
    }

    // Build grid cells
    final cells = <Widget>[];
    
    // Day headers
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (final day in weekDays) {
      cells.add(
        Center(child: Text(day, style: AppTextStyles.label(color: retroColors.textSecondary))),
      );
    }
    
    // Empty cells before start of month
    for (var i = 1; i < startingWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    
    // Days of month
    for (var day = 1; day <= daysInMonth; day++) {
      final hasRun = runDays.contains(day);
      final isToday = day == now.day;
      
      final dayRuns = runs.where((r) => r.startTime != null && r.startTime!.year == now.year && r.startTime!.month == now.month && r.startTime!.day == day).toList();
      
      cells.add(
        GestureDetector(
          onTap: hasRun ? () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DailyActivitiesScreen(
                  date: DateTime(now.year, now.month, day),
                  runs: dayRuns,
                ),
              ),
            );
          } : null,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasRun ? retroColors.accent.withOpacity(0.2) : retroColors.surfaceRaised,
              border: Border.all(
                color: hasRun ? retroColors.accent : (isToday ? retroColors.textSecondary : Colors.transparent),
                width: isToday ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: AppTextStyles.bodyMediumBold(
                  color: hasRun ? retroColors.accent : retroColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: retroColors.border),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }
}

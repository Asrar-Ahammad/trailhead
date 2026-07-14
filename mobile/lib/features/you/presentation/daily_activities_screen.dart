import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';

class DailyActivitiesScreen extends StatelessWidget {
  final DateTime date;
  final List<RunIsar> runs;

  const DailyActivitiesScreen({
    super.key,
    required this.date,
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; 
    final dateStr = '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';

    // Calculate steps per hour
    final List<double> stepsPerHour = List.filled(24, 0.0);
    double maxSteps = 0;
    
    for (final run in runs) {
      if (run.startTime != null && run.stepCount != null) {
        final hour = run.startTime!.hour;
        stepsPerHour[hour] += run.stepCount!.toDouble();
        if (stepsPerHour[hour] > maxSteps) {
          maxSteps = stepsPerHour[hour];
        }
      }
    }
    
    if (maxSteps == 0) maxSteps = 1000;

    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text(dateStr, style: AppTextStyles.title(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16.0, bottom: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('STEPS PER HOUR', style: AppTextStyles.label(color: retroColors.accent)),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 200,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
              decoration: BoxDecoration(
                color: retroColors.surfaceRaised,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: retroColors.border.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSteps * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 6 == 0) { // show every 6 hours to avoid crowding
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: AppTextStyles.labelCaps(color: retroColors.textSecondary),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: stepsPerHour[i],
                          color: retroColors.accent,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('ACTIVITIES', style: AppTextStyles.label(color: retroColors.accent)),
            ),
            const SizedBox(height: 16),
            if (runs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No activities recorded', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                ),
              )
            else
              ...runs.map((run) => ActivityCard(run: run)),
          ],
        ),
      ),
    );
  }
}

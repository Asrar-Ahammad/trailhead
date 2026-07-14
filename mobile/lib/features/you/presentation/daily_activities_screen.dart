import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';
import 'package:trailhead_mobile/features/run_tracking/application/daily_steps_provider.dart';

class DailyActivitiesScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final List<RunIsar> runs;

  const DailyActivitiesScreen({
    super.key,
    required this.date,
    required this.runs,
  });

  @override
  ConsumerState<DailyActivitiesScreen> createState() => _DailyActivitiesScreenState();
}

class _DailyActivitiesScreenState extends ConsumerState<DailyActivitiesScreen> {
  int? _touchedSpotIndex;

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; 
    final dateStr = '${days[widget.date.weekday - 1]}, ${widget.date.day} ${months[widget.date.month - 1]} ${widget.date.year}';

    // Get background steps for this date
    final dateKey = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
    final backgroundStepsAsync = ref.watch(dailyStepsForDateProvider(dateKey));
    final backgroundSteps = backgroundStepsAsync.valueOrNull ?? 0;

    // Calculate steps per hour from runs
    final List<double> stepsPerHour = List.filled(24, 0.0);
    double maxSteps = 0;
    
    for (final run in widget.runs) {
      if (run.startTime != null && run.stepCount != null) {
        final hour = run.startTime!.hour;
        stepsPerHour[hour] += run.stepCount!.toDouble();
        if (stepsPerHour[hour] > maxSteps) {
          maxSteps = stepsPerHour[hour];
        }
      }
    }
    if (maxSteps == 0) maxSteps = 1000;
    
    final int runSteps = stepsPerHour.fold(0.0, (sum, val) => sum + val).toInt();
    final int totalSteps = runSteps + backgroundSteps;

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
              padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 8),
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
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                      if (touchResponse != null && touchResponse.spot != null) {
                        final index = touchResponse.spot!.touchedBarGroupIndex;
                        if (_touchedSpotIndex != index) {
                          _touchedSpotIndex = index;
                          ref.read(hapticsServiceProvider).lightImpact();
                        }
                      } else if (event is FlPanEndEvent || event is FlPanCancelEvent || (event is FlPointerHoverEvent && touchResponse?.spot == null)) {
                        _touchedSpotIndex = null;
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => retroColors.surface,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} steps',
                          AppTextStyles.label(color: retroColors.textPrimary),
                        );
                      },
                    ),
                  ),
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min || value == 0) return const SizedBox.shrink();
                          
                          String text;
                          if (value >= 1000) {
                            text = '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
                          } else {
                            text = value.toInt().toString();
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              text,
                              style: AppTextStyles.labelCaps(color: retroColors.textSecondary),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL STEPS', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                  Text(
                    '$totalSteps',
                    style: AppTextStyles.title(color: retroColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('ACTIVITIES', style: AppTextStyles.label(color: retroColors.accent)),
            ),
            const SizedBox(height: 16),
            if (widget.runs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No activities recorded', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                ),
              )
            else
              ...widget.runs.map((run) => ActivityCard(run: run)),
          ],
        ),
      ),
    );
  }
}

import 'package:trailhead_mobile/shared/widgets/app_bar_backdrop.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import '../domain/you_use_case_daily_steps.dart';
import '../state_management/you_bloc_activity_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';

class DailyActivitiesScreen extends StatefulWidget {
  final DateTime date;
  final List<RunIsar> runs;

  const DailyActivitiesScreen({
    super.key,
    required this.date,
    required this.runs,
  });

  @override
  State<DailyActivitiesScreen> createState() => _DailyActivitiesScreenState();
}

class _DailyActivitiesScreenState extends State<DailyActivitiesScreen> {
  int? _touchedSpotIndex;
  late final DailyStepsBloc _steps;
  late final PeriodActivitiesBloc _activities;

  @override
  void initState() {
    super.initState();
    final date = widget.date;
    _steps = context.read<CreateDailyStepsBloc>()(date);
    _activities = context.read<CreatePeriodActivitiesBloc>()(
      DateTime(date.year, date.month, date.day), DateTime(date.year, date.month, date.day + 1),
    );
  }

  @override
  void dispose() {
    _steps.close();
    _activities.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [BlocProvider.value(value: _steps), BlocProvider.value(value: _activities)],
    child: Builder(builder: _buildScreen),
  );

  Widget _buildScreen(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; 
    final dateStr = '${days[widget.date.weekday - 1]}, ${widget.date.day} ${months[widget.date.month - 1]} ${widget.date.year}';

    final backgroundStepsRecord = context.watch<DailyStepsBloc>().state.valueOrNull;

    final runs = context.watch<PeriodActivitiesBloc>().state.valueOrNull ?? widget.runs;
    final (hours: stepsPerHour, :maxSteps, :totalSteps) = summarizeDailySteps(
      backgroundTotal: backgroundStepsRecord?.steps ?? 0,
      backgroundHours: backgroundStepsRecord?.hourlySteps ?? const [],
      activities: runs.where((run) => run.startTime != null).map(
        (run) => (hour: run.startTime!.hour, steps: run.stepCount ?? 0),
      ),
    );

    return Scaffold(
      backgroundColor: retroColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(dateStr, style: AppTextStyles.title(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: const AppBarBackdrop(),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, color: retroColors.textPrimary),
          onPressed: () => AppNavigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
          bottom: 120.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STEPS PER HOUR', style: AppTextStyles.label(color: retroColors.accent)),
                  if (_touchedSpotIndex != null)
                    Text(
                      '${_touchedSpotIndex.toString().padLeft(2, '0')}:00 • ${stepsPerHour[_touchedSpotIndex!].toInt()} steps',
                      style: AppTextStyles.labelCaps(color: retroColors.accent),
                    ),
                ],
              ),
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
                      setState(() {
                        if (touchResponse != null && touchResponse.spot != null) {
                          final index = touchResponse.spot!.touchedBarGroupIndex;
                          if (_touchedSpotIndex != index) {
                            _touchedSpotIndex = index;
                            context.read<HapticsCubit>().lightImpact();
                          }
                        } else if (event is FlTapUpEvent ||
                            event is FlPanEndEvent ||
                            event is FlPanCancelEvent ||
                            (event is FlPointerHoverEvent && touchResponse?.spot == null)) {
                          _touchedSpotIndex = null;
                        }
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => retroColors.accent.withValues(alpha: 0.15),
                      tooltipMargin: 6,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      fitInsideHorizontally: true,
                      fitInsideVertically: false,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final steps = rod.toY.toInt();
                        if (steps == 0) return null;
                        return BarTooltipItem(
                          '$steps',
                          AppTextStyles.labelCaps(color: retroColors.accent),
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
                    final isTouched = i == _touchedSpotIndex;
                    final stepCount = stepsPerHour[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: stepCount,
                          color: isTouched ? retroColors.accent : retroColors.accent.withValues(alpha: 0.5),
                          width: isTouched ? 10 : 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          rodStackItems: [],
                          backDrawRodData: BackgroundBarChartRodData(
                            show: isTouched,
                            toY: maxSteps * 1.2,
                            color: retroColors.accent.withValues(alpha: 0.07),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: isTouched && stepCount > 0 ? [0] : [],
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
            if (runs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No activities recorded', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                ),
              )
            else
              ...runs.map((run) => ActivityCard(key: ValueKey(run.id), run: run)),
          ],
        ),
      ),
    );
  }
}

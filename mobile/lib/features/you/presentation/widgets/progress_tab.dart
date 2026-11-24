import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/daily_activities_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/weekly_reports_list_screen.dart';
import 'package:trailhead_mobile/features/predictions/presentation/prediction_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressTab extends ConsumerStatefulWidget {
  final List<RunIsar> runs;

  const ProgressTab({super.key, required this.runs});

  @override
  ConsumerState<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends ConsumerState<ProgressTab> {
  late DateTime _selectedMonth;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    ref.read(hapticsServiceProvider).lightImpact();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    ref.read(hapticsServiceProvider).lightImpact();
    setState(() {
      _selectedMonth = next;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final useMiles = ref.watch(distanceUnitProvider);
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + kTextTabBarHeight;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 180,
        top: topInset - 70,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 12-Week Chart ──────────────────────────────────────────────
          Text('12-WEEK PROGRESS', style: AppTextStyles.labelCaps(color: retroColors.accent)),
          const SizedBox(height: 16),
          _build12WeekChart(retroColors, useMiles),

          const SizedBox(height: 32),

          // ── Month header with navigation ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthNames[_selectedMonth.month - 1].toUpperCase()} ${_selectedMonth.year}',
                  style: AppTextStyles.labelCaps(color: retroColors.accent),
                ),
              ),
              _NavButton(
                icon: PhosphorIcons.caretLeft,
                onTap: _previousMonth,
                colors: retroColors,
              ),
              const SizedBox(width: 8),
              _NavButton(
                icon: PhosphorIcons.caretRight,
                onTap: _isCurrentMonth ? null : _nextMonth,
                colors: retroColors,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMonthlyCalendar(context, ref, retroColors, _selectedMonth),

          const SizedBox(height: 32),

          // ── Reports ────────────────────────────────────────────────────
          Text('REPORTS', style: AppTextStyles.labelCaps(color: retroColors.accent)),
          const SizedBox(height: 16),
          _buildNavCard(
            retroColors: retroColors,
            icon: PhosphorIcons.chartBarFill,
            title: 'Weekly Reports',
            subtitle: 'Historical week-by-week summaries',
            onTap: () {
              ref.read(soundServiceProvider).playWeeklyReportsTap();
              ref.read(hapticsServiceProvider).lightImpact();
              AppNavigator.push(context, AppNavigator.materialPageRoute(builder: (_) => const WeeklyReportsListScreen()));
            },
          ),

          const SizedBox(height: 32),

          // ── Tools ──────────────────────────────────────────────────────
          Text('TOOLS', style: AppTextStyles.labelCaps(color: retroColors.accent)),
          const SizedBox(height: 16),
          _buildNavCard(
            retroColors: retroColors,
            icon: PhosphorIcons.timerFill,
            title: 'Race Predictor',
            subtitle: 'AI-powered finishing times',
            onTap: () {
              ref.read(soundServiceProvider).playRacePredictorTap();
              ref.read(hapticsServiceProvider).lightImpact();
              AppNavigator.push(context, AppNavigator.materialPageRoute(builder: (_) => const PredictionScreen()));
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Reusable nav card ────────────────────────────────────────────────────
  Widget _buildNavCard({
    required AppColors retroColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: retroColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: retroColors.accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(PhosphorIcons.caretRight, color: retroColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 12-Week bar chart ────────────────────────────────────────────────────
  Widget _build12WeekChart(AppColors retroColors, bool useMiles) {
    final chartData = List.filled(12, 0.0);
    final now = DateTime.now();
    final startOfThisWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    for (final run in widget.runs) {
      if (run.startTime == null) continue;
      final weeksAgo = run.startTime!.isAfter(startOfThisWeek)
          ? 0
          : ((startOfThisWeek.difference(run.startTime!).inDays) ~/ 7) + 1;
      if (weeksAgo < 12) {
        chartData[11 - weeksAgo] += (run.distanceM ?? 0) / 1000.0;
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: retroColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
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
                  if (value % 3 != 0) return const SizedBox.shrink();
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
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min || value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${RunFormatUtils.formatDistance(value * 1000, useMiles)} ${RunFormatUtils.getUnitString(useMiles)}',
                      style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
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
          barGroups: List.generate(12, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: chartData[index],
                  color: retroColors.accent,
                  width: 12,
                  borderRadius: BorderRadius.circular(100),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Monthly calendar ─────────────────────────────────────────────────────
  Widget _buildMonthlyCalendar(
    BuildContext context,
    WidgetRef ref,
    AppColors retroColors,
    DateTime month,
  ) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;

    final runDays = <int>{};
    for (final run in widget.runs) {
      if (run.startTime != null &&
          run.startTime!.year == month.year &&
          run.startTime!.month == month.month) {
        runDays.add(run.startTime!.day);
      }
    }

    final cells = <Widget>[];

    // Day-of-week headers
    for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
      cells.add(Center(
        child: Text(day, style: AppTextStyles.label(color: retroColors.textSecondary)),
      ));
    }

    // Leading empty cells
    for (var i = 1; i < startingWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final hasRun = runDays.contains(day);
      final isToday = month.year == now.year && month.month == now.month && day == now.day;
      final isFuture = month.year == now.year && month.month == now.month && day > now.day;

      final dayRuns = widget.runs
          .where((r) =>
              r.startTime != null &&
              r.startTime!.year == month.year &&
              r.startTime!.month == month.month &&
              r.startTime!.day == day)
          .toList();

      cells.add(GestureDetector(
        onTap: isFuture
            ? null
            : () {
                ref.read(soundServiceProvider).playCalendarDayTap();
                ref.read(hapticsServiceProvider).lightImpact();
                AppNavigator.push(context, AppNavigator.materialPageRoute(
                  builder: (_) => DailyActivitiesScreen(
                    date: DateTime(month.year, month.month, day),
                    runs: dayRuns,
                  ),
                ));
              },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hasRun
                ? retroColors.accent.withValues(alpha: 0.2)
                : retroColors.surfaceRaised,
            border: Border.all(
              color: hasRun
                  ? retroColors.accent
                  : (isToday ? retroColors.textSecondary : Colors.transparent),
              width: isToday ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(100),
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
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: retroColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }
}

// ── Nav button widget ───────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final AppColors colors;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? colors.accent.withValues(alpha: 0.12)
              : colors.surfaceRaised,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? colors.accent
              : colors.textSecondary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

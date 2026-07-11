import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/stats/data/weekly_report_api_client.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/week_details_screen.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';

class WeeklyReportsListScreen extends ConsumerWidget {
  const WeeklyReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final reportsAsync = ref.watch(weeklyReportsProvider);

    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('WEEKLY REPORTS', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: retroColors.accent,
        backgroundColor: retroColors.surface,
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(weeklyReportsProvider);
        },
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Center(
                child: Text('No weekly reports yet.', style: AppTextStyles.bodyLarge(color: retroColors.textSecondary)),
              );
            }

            // Group by year, then by month
            final Map<int, Map<int, List<WeeklyReportModel>>> grouped = {};
            for (final r in reports) {
              final year = r.year;
              final month = r.startDate.month;
              
              if (!grouped.containsKey(year)) {
                grouped[year] = {};
              }
              if (!grouped[year]!.containsKey(month)) {
                grouped[year]![month] = [];
              }
              grouped[year]![month]!.add(r);
            }

            final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedYears.length,
              itemBuilder: (context, index) {
                final year = sortedYears[index];
                final yearMonths = grouped[year]!;
                final sortedMonths = yearMonths.keys.toList()..sort((a, b) => b.compareTo(a));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(year.toString(), style: AppTextStyles.headline(color: retroColors.textPrimary)),
                    ),
                    ...sortedMonths.map((month) {
                      final monthReports = yearMonths[month]!;
                      return _buildMonthSection(context, ref, retroColors, month, monthReports);
                    }),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: RetroLoadingIndicator(text: 'FETCHING REPORTS')),
          error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
        ),
      ),
    );
  }

  Widget _buildMonthSection(BuildContext context, WidgetRef ref, AppColors retroColors, int month, List<WeeklyReportModel> monthReports) {
    int totalSteps = 0;
    double totalDistanceM = 0;
    int totalDurationS = 0;

    for (final r in monthReports) {
      totalSteps += r.totalSteps;
      totalDistanceM += r.totalDistanceM;
      totalDurationS += r.totalDurationS;
    }

    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = monthNames[month - 1];
    
    final hours = totalDurationS ~/ 3600;
    final mins = (totalDurationS % 3600) ~/ 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: retroColors.accent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: retroColors.accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthName.toUpperCase(), style: AppTextStyles.headline(color: retroColors.background)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMonthStat(retroColors, PhosphorIcons.sneaker(), '$totalSteps Steps', isSolidCard: true),
                  _buildMonthStat(retroColors, PhosphorIcons.mapPin(), '${(totalDistanceM / 1000).toStringAsFixed(1)} km', isSolidCard: true),
                  _buildMonthStat(retroColors, PhosphorIcons.timer(), timeStr, isSolidCard: true),
                ],
              ),
            ],
          ),
        ),
        ...monthReports.map((report) => _buildWeekCard(context, ref, retroColors, report)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMonthStat(AppColors retroColors, IconData icon, String text, {bool isSolidCard = false}) {
    final color = isSolidCard ? retroColors.background : retroColors.accent;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.label(color: color)),
      ],
    );
  }

  Widget _buildWeekCard(BuildContext context, WidgetRef ref, AppColors retroColors, WeeklyReportModel report) {
    final startStr = '${report.startDate.day}/${report.startDate.month}';
    final endStr = '${report.endDate.day}/${report.endDate.month}';

    return Card(
      color: retroColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: retroColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(soundServiceProvider).playWeekCardTap();
          ref.read(hapticsServiceProvider).lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailsScreen(report: report)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week ${report.weekNumber}', style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$startStr - $endStr', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        RunFormatUtils.formatDistanceKm(report.totalDistanceM) + ' km',
                        style: AppTextStyles.bodyLargeBold(color: retroColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.runCount} runs, ${report.walkCount} walks',
                        style: AppTextStyles.label(color: retroColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Icon(PhosphorIcons.caretRight(), color: retroColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

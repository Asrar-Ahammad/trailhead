import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/stats/data/weekly_report_api_client.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/week_details_screen.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';

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

            // Group by year
            final Map<int, List<WeeklyReportModel>> grouped = {};
            for (final r in reports) {
              if (!grouped.containsKey(r.year)) {
                grouped[r.year] = [];
              }
              grouped[r.year]!.add(r);
            }

            final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedYears.length,
              itemBuilder: (context, index) {
                final year = sortedYears[index];
                final yearReports = grouped[year]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(year.toString(), style: AppTextStyles.headline(color: retroColors.textPrimary)),
                    ),
                    ...yearReports.map((report) => _buildWeekCard(context, retroColors, report)),
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

  Widget _buildWeekCard(BuildContext context, AppColors retroColors, WeeklyReportModel report) {
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';

final weeklyRunsProvider = StreamProvider.family<List<RunIsar>, WeeklyReportModel>((ref, report) {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.watchCompletedRuns().map((runs) {
    return runs.where((r) {
      if (r.startTime == null) return false;
      return r.startTime!.isAfter(report.startDate.subtract(const Duration(seconds: 1))) && 
             r.startTime!.isBefore(report.endDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.startTime!.compareTo(a.startTime!)); // newest first
  });
});

class WeeklyActivitiesScreen extends ConsumerWidget {
  final WeeklyReportModel report;

  const WeeklyActivitiesScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final runsAsync = ref.watch(weeklyRunsProvider(report));

    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text('Week ${report.weekNumber} Activities', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 20)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: runsAsync.when(
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Text('No activities recorded this week.', style: AppTextStyles.bodyLargeBold(color: retroColors.textSecondary)),
            );
          }

          // Group by date (day)
          final Map<String, List<RunIsar>> grouped = {};
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

          for (final run in runs) {
            final st = run.startTime!;
            final dateStr = '${days[st.weekday - 1]}, ${st.day} ${months[st.month - 1]}';
            if (!grouped.containsKey(dateStr)) {
              grouped[dateStr] = [];
            }
            grouped[dateStr]!.add(run);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateStr = grouped.keys.elementAt(index);
              final dayRuns = grouped[dateStr]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(dateStr, style: AppTextStyles.retroLabelLarge(color: retroColors.accent)),
                  ),
                  ...dayRuns.map((r) => ActivityCard(run: r)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: RetroLoadingIndicator()),
        error: (e, st) => Center(child: Text('Error loading activities: $e', style: AppTextStyles.bodyMedium(color: Colors.red))),
      ),
    );
  }
}

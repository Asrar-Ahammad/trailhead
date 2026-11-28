import 'package:trailhead_mobile/shared/widgets/app_bar_backdrop.dart';
import '../../run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state_management/you_bloc_activity_period.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';

class WeeklyActivitiesScreen extends StatelessWidget {
  final WeeklyReportModel report;

  const WeeklyActivitiesScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final last = report.endDate;
    return BlocProvider(
      create: (_) => context.read<CreatePeriodActivitiesBloc>()(
        report.startDate, DateTime(last.year, last.month, last.day + 1),
      ),
      child: Builder(builder: _buildScreen),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final runsAsync = context.watch<PeriodActivitiesBloc>().state;

    return Scaffold(
      backgroundColor: retroColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Week ${report.weekNumber} Activities', style: AppTextStyles.title(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: const AppBarBackdrop(),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, color: retroColors.textPrimary),
          onPressed: () => AppNavigator.pop(context),
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateStr = grouped.keys.elementAt(index);
              final dayRuns = grouped[dateStr]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(dateStr, style: AppTextStyles.labelCaps(color: retroColors.accent)),
                  ),
                  ...dayRuns.map((r) => ActivityCard(key: ValueKey(r.id), run: r)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (e, st) => Center(child: Text('Error loading activities: $e', style: AppTextStyles.bodyMedium(color: Colors.red))),
      ),
    );
  }
}

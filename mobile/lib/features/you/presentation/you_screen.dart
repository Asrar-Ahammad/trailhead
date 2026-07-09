import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/stats/application/pr_engine.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import 'package:trailhead_mobile/features/profile/presentation/settings_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/progress_tab.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

final historyProvider = FutureProvider<List<RunIsar>>((ref) async {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.getCompletedRuns();
});

final prsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  final engine = ref.read(prEngineProvider);
  return engine.calculatePRs();
});

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final historyAsync = ref.watch(historyProvider);
    final prsAsync = ref.watch(prsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: retroColors.background,
        appBar: AppBar(
          title: Text('YOU', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          backgroundColor: retroColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.gearSix(), color: retroColors.textPrimary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: retroColors.accent,
            labelColor: retroColors.accent,
            unselectedLabelColor: retroColors.textSecondary,
            labelStyle: AppTextStyles.retroLabelLarge().copyWith(fontSize: 16),
            tabs: const [
              Tab(text: 'ACTIVITIES'),
              Tab(text: 'RECORDS'),
              Tab(text: 'PROGRESS'),
            ],
          ),
        ),
        body: historyAsync.when(
          data: (runs) {
          if (runs.isEmpty) {
            return TabBarView(
              children: [
                _buildEmptyState(retroColors),
                _buildEmptyState(retroColors),
                _buildEmptyState(retroColors),
              ],
            );
          }

          return TabBarView(
            children: [
              _buildActivitiesTab(retroColors, runs, prsAsync, ref),
              _buildRecordsTab(retroColors, prsAsync, ref),
              ProgressTab(runs: runs),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
      ),
    ));
  }

  Widget _buildEmptyState(AppColors retroColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.personSimpleRun(PhosphorIconsStyle.regular), size: 64, color: retroColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No runs yet!',
            style: AppTextStyles.headline(color: retroColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Head to the Record tab to get started.',
            style: AppTextStyles.bodyLarge(color: retroColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(AppColors retroColors, AsyncValue<List<PersonalRecord>> prsAsync, WidgetRef ref) {
    return RefreshIndicator(
      color: retroColors.accent,
      backgroundColor: retroColors.surface,
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(prsProvider);
      },
      child: prsAsync.when(
        data: (prs) {
          if (prs.isEmpty) return _buildEmptyState(retroColors);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prs.length,
            itemBuilder: (context, index) {
              final pr = prs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: retroColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: retroColors.accent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill), color: retroColors.accent, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pr.title, style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(pr.value, style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
      ),
    );
  }

  Widget _buildActivitiesTab(AppColors retroColors, List<RunIsar> runs, AsyncValue<List<PersonalRecord>> prsAsync, WidgetRef ref) {
    final List<dynamic> listItems = [];
    String? currentGroupDate;
    final now = DateTime.now();

    for (var run in runs) {
      if (run.startTime == null) {
        listItems.add(run);
        continue;
      }
      final date = DateTime(run.startTime!.year, run.startTime!.month, run.startTime!.day);
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      String headerText;
      if (date == today) {
        headerText = 'Today';
      } else if (date == yesterday) {
        headerText = 'Yesterday';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; 
        headerText = '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
      }

      if (currentGroupDate != headerText) {
        listItems.add(headerText);
        currentGroupDate = headerText;
      }
      listItems.add(run);
    }

    return RefreshIndicator(
      color: retroColors.accent,
      backgroundColor: retroColors.surface,
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(historyProvider);
        // ignore: unused_result
        ref.refresh(prsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 120),
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          final item = listItems[index];
          
          if (item is String) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) Divider(color: retroColors.surface, height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    item,
                    style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary),
                  ),
                ),
              ],
            );
          } else if (item is RunIsar) {
            final achievementsCount = prsAsync.maybeWhen(
              data: (prs) => prs.where((pr) => pr.run.id == item.id).length,
              orElse: () => 0,
            );
            return ActivityCard(run: item, achievementsCount: achievementsCount);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

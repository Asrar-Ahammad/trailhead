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
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/history/presentation/manual_entry_screen.dart';

final historyProvider = StreamProvider<List<RunIsar>>((ref) {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.watchCompletedRuns();
});

final prsProvider = FutureProvider<RecordGroup>((ref) async {
  final engine = ref.read(prEngineProvider);
  return engine.getRecords();
});

final selectedActivitiesProvider = StateProvider<Set<int>>((ref) => {});
final isDeletingProvider = StateProvider<bool>((ref) => false);
final recordsModeProvider = StateProvider<String>((ref) => 'best_effort');

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final historyAsync = ref.watch(historyProvider);
    final prsAsync = ref.watch(prsProvider);

    final selectedIds = ref.watch(selectedActivitiesProvider);
    final isDeleting = ref.watch(isDeletingProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: retroColors.background,
        appBar: selectedIds.isNotEmpty
            ? AppBar(
                title: Text('${selectedIds.length} Selected', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 20)),
                backgroundColor: retroColors.surfaceRaised,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(PhosphorIcons.x(), color: retroColors.textPrimary),
                  onPressed: isDeleting ? null : () {
                    ref.read(selectedActivitiesProvider.notifier).state = {};
                  },
                ),
                actions: [
                  if (isDeleting)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: retroColors.error, strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(PhosphorIcons.trash(), color: retroColors.error),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: retroColors.surface,
                            title: Text('Delete Activities?', style: AppTextStyles.headline(color: retroColors.textPrimary)),
                            content: Text('Are you sure you want to delete ${selectedIds.length} activities?', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Delete', style: AppTextStyles.bodyMediumBold(color: retroColors.error)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          ref.read(isDeletingProvider.notifier).state = true;
                          try {
                            final repo = ref.read(runHistoryRepositoryProvider);
                            for (final id in selectedIds) {
                              await repo.deleteRun(id);
                            }
                          } finally {
                            ref.read(isDeletingProvider.notifier).state = false;
                            ref.read(selectedActivitiesProvider.notifier).state = {};
                            ref.refresh(historyProvider);
                            ref.refresh(prsProvider);
                          }
                        }
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
              )
            : AppBar(
                title: Text('YOU', style: AppTextStyles.retroLabelLarge(color: retroColors.textPrimary).copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
                backgroundColor: retroColors.surface,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(PhosphorIcons.gearSix(), color: retroColors.textPrimary),
                    onPressed: () {
                      ref.read(soundServiceProvider).playSettingsTap();
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
              _buildRecordsTab(retroColors, prsAsync, ref, context),
              ProgressTab(runs: runs),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(hapticsServiceProvider).mediumImpact();
          ref.read(soundServiceProvider).playFabAddRun();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
        },
        backgroundColor: retroColors.accent,
        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: retroColors.background),
      ),
        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: retroColors.background),
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

  String formatValue(String category, double value) {
    if (['longest_run', 'max_elevation'].contains(category)) {
      if (category == 'longest_run') return '${(value / 1000).toStringAsFixed(2)} km';
      return '${value.toStringAsFixed(0)} m';
    }
    // Time format
    final mins = (value / 60).floor();
    final secs = (value % 60).floor();
    if (mins >= 60) {
      final hours = (mins / 60).floor();
      final remainingMins = mins % 60;
      return '${hours}:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordsTab(AppColors retroColors, AsyncValue<RecordGroup> prsAsync, WidgetRef ref, BuildContext context) {
    final mode = ref.watch(recordsModeProvider);
    return RefreshIndicator(
      color: retroColors.accent,
      backgroundColor: retroColors.surface,
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(prsProvider);
      },
      child: prsAsync.when(
        data: (group) {
          final list = mode == 'best_effort' ? group.bestEffort : group.manual;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text('Best Efforts', style: AppTextStyles.label(color: mode == 'best_effort' ? retroColors.surface : retroColors.textPrimary)),
                      selected: mode == 'best_effort',
                      selectedColor: retroColors.accent,
                      showCheckmark: false,
                      onSelected: (val) {
                        if(val) {
                          ref.read(hapticsServiceProvider).lightImpact();
                          ref.read(soundServiceProvider).playTabBestEfforts();
                          ref.read(recordsModeProvider.notifier).state = 'best_effort';
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text('All-Time PRs', style: AppTextStyles.label(color: mode == 'manual' ? retroColors.surface : retroColors.textPrimary)),
                      selected: mode == 'manual',
                      selectedColor: retroColors.accent,
                      showCheckmark: false,
                      onSelected: (val) {
                        if(val) {
                          ref.read(hapticsServiceProvider).lightImpact();
                          ref.read(soundServiceProvider).playTabAllTime();
                          ref.read(recordsModeProvider.notifier).state = 'manual';
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty 
                  ? _buildEmptyState(retroColors)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final pr = list[index];
                        final formattedTitle = pr.category.toUpperCase();
                        final formattedValue = formatValue(pr.category, pr.value);

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
                                    Text(formattedTitle, style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(formattedValue, style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary)),
                                    if (pr.rank > 0 && mode == 'best_effort')
                                      Text('Rank ${pr.rank}', style: AppTextStyles.label(color: retroColors.textSecondary)),
                                    if (pr.proofUrl != null)
                                      Text(pr.proofUrl!, style: AppTextStyles.label(color: retroColors.accent)),
                                  ],
                                ),
                              ),
                              if (mode == 'manual')
                                IconButton(
                                  icon: Icon(PhosphorIcons.trash(), color: retroColors.error),
                                  onPressed: () async {
                                    try {
                                      await ref.read(prEngineProvider).deleteManualRecord(pr.id);
                                      // ignore: unused_result
                                      ref.refresh(prsProvider);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete PR')));
                                    }
                                  },
                                )
                            ],
                          ),
                        );
                      },
                    ),
              ),
              if (mode == 'manual')
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(hapticsServiceProvider).lightImpact();
                      _showAddPRDialog(context, retroColors, ref);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: retroColors.accent),
                    child: Text('Add PR', style: AppTextStyles.bodyMediumBold(color: retroColors.surface)),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
      ),
    );
  }

  void _showAddPRDialog(BuildContext context, AppColors retroColors, WidgetRef ref) {
    final categoryController = TextEditingController(text: '5k');
    final valueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: retroColors.surface,
        title: Text('Add Manual PR', style: AppTextStyles.headline(color: retroColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Category (e.g. 5k, 10k)', labelStyle: TextStyle(color: retroColors.textSecondary)),
              style: TextStyle(color: retroColors.textPrimary),
            ),
            TextField(
              controller: valueController,
              decoration: InputDecoration(labelText: 'Value (seconds/meters)', labelStyle: TextStyle(color: retroColors.textSecondary)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: retroColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(prEngineProvider).addManualRecord(
                  categoryController.text,
                  double.parse(valueController.text),
                  DateTime.now(),
                  null
                );
                Navigator.pop(ctx);
                // ignore: unused_result
                ref.refresh(prsProvider);
              } catch (e) {
                // Ignore parsing errors for now
              }
            },
            child: Text('Save', style: AppTextStyles.bodyMediumBold(color: retroColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(AppColors retroColors, List<RunIsar> runs, AsyncValue<RecordGroup> prsAsync, WidgetRef ref) {
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
              data: (group) => group.bestEffort.where((pr) => pr.runId == item.clientRunId).length,
              orElse: () => 0,
            );
            
            final isSelectionMode = ref.watch(selectedActivitiesProvider).isNotEmpty;
            final isSelected = ref.watch(selectedActivitiesProvider).contains(item.id);

            return ActivityCard(
              run: item, 
              achievementsCount: achievementsCount,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onSelect: () {
                final currentSelection = Set<int>.from(ref.read(selectedActivitiesProvider));
                if (isSelected) {
                  currentSelection.remove(item.id);
                } else {
                  currentSelection.add(item.id);
                }
                ref.read(selectedActivitiesProvider.notifier).state = currentSelection;
                ref.read(soundServiceProvider).playToggleSwitch(); // Audio feedback for toggle
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  ref.read(selectedActivitiesProvider.notifier).state = {item.id};
                  ref.read(soundServiceProvider).playToggleSwitch(); // Audio feedback for toggle
                  ref.read(hapticsServiceProvider).lightImpact();
                }
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

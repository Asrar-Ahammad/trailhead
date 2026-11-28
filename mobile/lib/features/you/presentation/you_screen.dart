import 'dart:ui';
import '../state_management/you_bloc_activity_actions.dart';
import '../../../shared/state_management/async_value.dart';
import '../../../shared/state_management/global/history_cubit_activities.dart';
import '../../../shared/state_management/global/stats_cubit_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_repository_personal_records.dart';
import 'package:trailhead_mobile/features/profile/presentation/settings_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/progress_tab.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/records_tab.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateYouBloc>()(),
    child: const _YouContent(),
  );
}

class _YouContent extends StatefulWidget {
  const _YouContent();
  @override
  State<_YouContent> createState() => _YouScreenState();
}

class _YouScreenState extends State<_YouContent> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _lastSoundIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to the raw animation value instead of the settled index.
    // This fires the sound the instant the swipe crosses the 50% midpoint
    // (animation.value.round() changes) — same responsiveness as a tap.
    _tabController.animation!.addListener(_onAnimationChanged);
  }

  void _onAnimationChanged() {
    final anim = _tabController.animation;
    if (anim == null) return;

    // .round() flips to the new integer exactly when crossing the midpoint —
    // no waiting for the spring animation to fully settle.
    final perceivedIndex = anim.value.round().clamp(0, 2);
    if (perceivedIndex == _lastSoundIndex) return;
    _lastSoundIndex = perceivedIndex;

    context.read<HapticsCubit>().lightImpact();
    final soundService = context.read<AudioCubit>();
    switch (perceivedIndex) {
      case 0:
        soundService.playTabActivities();
        break;
      case 1:
        soundService.playTabRecords();
        break;
      case 2:
        soundService.playTabProgress();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.animation!.removeListener(_onAnimationChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = context.watch<HistoryActivitiesCubit>().state;
    final prsAsync = context.watch<StatsRecordsCubit>().state;

    final selectedIds = context.watch<YouBloc>().state.selected;
    final isDeleting = context.watch<YouBloc>().state.deleting;

    return BlocListener<YouBloc, YouState>(
      listener: (context, state) {
        if (state.error case final error?) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: _buildScreen(context, retroColors, isDarkMode, historyAsync, prsAsync, selectedIds, isDeleting),
    );
  }

  Widget _buildScreen(BuildContext context, AppColors retroColors, bool isDarkMode,
      AsyncValue<List<RunIsar>> historyAsync, AsyncValue<RecordGroup> prsAsync, Set<int> selectedIds, bool isDeleting) {
    return Scaffold(
        backgroundColor: retroColors.background,
        extendBodyBehindAppBar: true,
        appBar: selectedIds.isNotEmpty
            ? AppBar(
                title: Text('${selectedIds.length} Selected', style: AppTextStyles.title(color: retroColors.textPrimary)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      color: retroColors.surfaceRaised.withValues(alpha: isDarkMode ? 0.35 : 0.45),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Icon(PhosphorIcons.x, color: retroColors.textPrimary),
                  onPressed: isDeleting ? null : () {
                    context.read<YouBloc>().add(const ClearActivitySelection());
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
                      icon: Icon(PhosphorIcons.trash, color: retroColors.error),
                      onPressed: () async {
                        final confirmed = await AppNavigator.dialog<bool>(
                          context,
                          (ctx) => AlertDialog(
                            backgroundColor: retroColors.surface,
                            title: Text('Delete Activities?', style: AppTextStyles.headline(color: retroColors.textPrimary)),
                            content: Text('Are you sure you want to delete ${selectedIds.length} activities?', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => AppNavigator.pop(ctx, false),
                                child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => AppNavigator.pop(ctx, true),
                                child: Text('Delete', style: AppTextStyles.bodyMediumBold(color: retroColors.error)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          context.read<YouBloc>().add(const DeleteSelectedActivities());
                        }
                      },
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: retroColors.accent,
                  labelColor: retroColors.accent,
                  unselectedLabelColor: retroColors.textSecondary,
                  labelStyle: AppTextStyles.labelCaps(),
                  tabs: const [
                    Tab(text: 'ACTIVITIES'),
                    Tab(text: 'RECORDS'),
                    Tab(text: 'PROGRESS'),
                  ],
                ),
              )
            : AppBar(
                title: Text('YOU', style: AppTextStyles.headline(color: retroColors.textPrimary)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      color: retroColors.surface.withValues(alpha: isDarkMode ? 0.35 : 0.45),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(PhosphorIcons.gearSix, color: retroColors.textPrimary),
                    onPressed: () {
                      context.read<HapticsCubit>().lightImpact();
                      context.read<AudioCubit>().playSettingsTap();
                      AppNavigator.push(context,
                        AppNavigator.materialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: retroColors.accent,
            labelColor: retroColors.accent,
            unselectedLabelColor: retroColors.textSecondary,
            labelStyle: AppTextStyles.labelCaps(),
            tabs: const [
              Tab(text: 'ACTIVITIES'),
              Tab(text: 'RECORDS'),
              Tab(text: 'PROGRESS'),
            ],
          ),
        ),
        body: () {
          // Use valueOrNull so we never block the whole body on stream loading.
          // The stream fires immediately (fireImmediately: true) but on first
          // cold open there can be a brief loading state that would hide all
          // three tabs. Instead we fall back to an empty list and let each
          // individual card/tab manage its own loading state.
          final runs = historyAsync.valueOrNull ?? [];
          final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + kTextTabBarHeight;

          Widget emptyRefreshable() => RefreshIndicator(
            color: retroColors.accent,
            backgroundColor: retroColors.surface,
            edgeOffset: topInset,
            onRefresh: context.read<HistoryActivitiesCubit>().refresh,
            child: historyAsync.isLoading && !historyAsync.hasValue
                ? Center(child: CircularProgressIndicator(color: retroColors.accent))
                : _buildEmptyState(retroColors),
          );

          return TabBarView(
            controller: _tabController,
            children: [
              runs.isEmpty ? emptyRefreshable() : _buildActivitiesTab(context, retroColors, runs, prsAsync),
              const RecordsTab(),
              ProgressTab(runs: runs),
            ],
          );
        }(),
    );
  }

  Widget _buildEmptyState(AppColors retroColors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.personSimpleRun, size: 64, color: retroColors.textSecondary),
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
            ),
          ),
        );
      },
    );
  }



  Widget _buildActivitiesTab(BuildContext context, AppColors retroColors, List<RunIsar> runs, AsyncValue<RecordGroup> prsAsync) {
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

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + kTextTabBarHeight;
    return RefreshIndicator(
      color: retroColors.accent,
      backgroundColor: retroColors.surface,
      edgeOffset: topInset,
      onRefresh: context.read<HistoryActivitiesCubit>().refresh,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: topInset + 2,
          bottom: 200,
        ),
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
            
            final isSelectionMode = context.watch<YouBloc>().state.selected.isNotEmpty;
            final isSelected = context.watch<YouBloc>().state.selected.contains(item.id);

            return ActivityCard(
              key: ValueKey(item.id),
              run: item, 
              achievementsCount: achievementsCount,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onSelect: () {
                context.read<YouBloc>().add(ToggleActivitySelection(item.id));
                context.read<AudioCubit>().playToggleSwitch(); // Audio feedback for toggle
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  context.read<YouBloc>().add(ToggleActivitySelection(item.id));
                  context.read<AudioCubit>().playToggleSwitch(); // Audio feedback for toggle
                  context.read<HapticsCubit>().lightImpact();
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

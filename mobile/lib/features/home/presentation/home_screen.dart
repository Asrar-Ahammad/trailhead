import 'widgets/home_widget_weather_details.dart';
import 'widgets/home_widget_fade_in.dart';
import 'widgets/home_widget_weekly_summary.dart';
import 'widgets/home_widget_coach_card.dart';
import 'widgets/home_widget_distance_chart.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'dart:ui';
import '../data/home_repository_implementation_dashboard.dart';
import '../state_management/home_bloc_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/state_management/global/navigation_cubit_main_tab.dart';
import 'package:trailhead_mobile/features/navigation/domain/navigation_entity_main_tab.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:trailhead_mobile/features/stats/application/ai_coach_service.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import '../../run_tracking/application/run_format_utils.dart';
import '../../../shared/state_management/async_value.dart' as StateAsync;

import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';

import 'package:trailhead_mobile/features/home/presentation/widgets/goals_progress_card.dart';
import 'package:trailhead_mobile/features/chat/presentation/chat_screen_coach_conversation.dart';
import 'package:trailhead_mobile/features/weather/presentation/weather_pace_card.dart';
import 'package:trailhead_mobile/features/weather/state_management/weather_bloc_pacing.dart';
import 'package:trailhead_mobile/features/weather/application/weather_utils.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/home/presentation/widgets/aurora_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => context.read<CreateWeatherBloc>()()),
      BlocProvider(create: (_) => context.read<CreateHomeBloc>()()),
    ],
    child: const _HomeDashboard(),
  );
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();
  @override
  State<_HomeDashboard> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeDashboard> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final isScrolled =
          _scrollController.hasClients && _scrollController.offset > 10;
      if (isScrolled != _isScrolled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isScrolled = isScrolled;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final dashboard = context.watch<HomeBloc>().state;
    final summaryAsync = dashboard.week;
    final aiCoachAsync = dashboard.coach;
    final trendMessageAsync = dashboard.trend;
    return Scaffold(
      backgroundColor: retroColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.lg,
        toolbarHeight: 66,
        backgroundColor: _isScrolled
            ? retroColors.surface.withValues(alpha: 0.45)
            : Colors.transparent,
        elevation: 0,
        flexibleSpace: _isScrolled
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: retroColors.surface.withValues(alpha: 0.45),
                      border: Border(
                        bottom: BorderSide(
                          color: retroColors.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TRAILHEAD',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: retroColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getFormattedDate(),
              style: GoogleFonts.pixelifySans(
                fontSize: 12,
                letterSpacing: 1.0,
                color: retroColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: context.watch<WeatherBloc>().state.maybeWhen(
              data: (data) {
                final temp = data.conditions.temperature.round();
                final code = data.conditions.code;
                final isDay = data.conditions.isDay;
                final city = data.conditions.city;
                final shortCity = city.split(',').first.trim().toUpperCase();
                final weatherIcon = WeatherUtils.getWeatherIcon(
                  code,
                  isDay: isDay,
                );
                final weatherColor = WeatherUtils.getWeatherColor(
                  code,
                  retroColors,
                  isDay: isDay,
                );

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.42,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      context.read<HapticsCubit>().lightImpact();
                      AppNavigator.bottomSheet(
                        context,
                        (_) =>
                            HomeWeatherDetails(colors: retroColors, data: data),
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black.withValues(alpha: 0.35),
                        isScrollControlled: true,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: retroColors.surfaceRaised.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: retroColors.border.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(weatherIcon, color: weatherColor, size: 17),
                          const SizedBox(width: 7),
                          Text(
                            '$temp°',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: retroColors.textPrimary,
                            ),
                          ),
                          if (shortCity.isNotEmpty) ...[
                            const SizedBox(width: 7),
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: retroColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                shortCity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: retroColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: retroColors.surfaceRaised.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: retroColors.accent,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: AuroraBackground(
              color1: retroColors.accent,
              color2: retroColors.accentMuted,
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
              right: AppSpacing.lg,
              bottom: 240.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summaryAsync.when(
                  data: (summary) => _buildContent(
                    context,
                    retroColors,
                    summary,
                    aiCoachAsync,
                    trendMessageAsync,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: RetroLoadingIndicator(text: 'FETCHING RUNS'),
                  ),
                  error: (err, stack) => Center(child: Text('Error: \$err')),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0, right: 8.0),
        child: FloatingActionButton(
          heroTag: 'chat_fab',
          elevation: 0,
          highlightElevation: 0,
          onPressed: () {
            context.read<HapticsCubit>().mediumImpact();
            context.read<AudioCubit>().playButtonTap();
            AppNavigator.push(
              context,
              AppNavigator.materialPageRoute(
                builder: (_) => const ChatScreen(),
              ),
            );
          },
          backgroundColor: retroColors.accent,
          child: Icon(PhosphorIcons.sparkleFill, color: retroColors.background),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppColors retroColors,
    HomeWeeklyData week,
    StateAsync.AsyncValue<AiCoachData> aiCoachAsync,
    StateAsync.AsyncValue<String?> trendMessageAsync,
  ) {
    final summary = week.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        trendMessageAsync.when(
          data: (trend) => trend != null && trend.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: HomeFadeIn(
                    delayMs: 0,
                    child: Text(
                      trend,
                      style: AppTextStyles.bodyLarge(
                        color: retroColors.textSecondary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        HomeFadeIn(
          delayMs: 60,
          child: HomeWeeklySummary(
            summary: summary,
            colors: retroColors,
            useMiles: context.watch<DistanceUnitCubit>().state,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        HomeFadeIn(
          delayMs: 120,
          child: Container(
            decoration: BoxDecoration(
              color: retroColors.accent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: retroColors.accent, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  context.read<HapticsCubit>().lightImpact();
                  context.read<AudioCubit>().playButtonTap();
                  context.read<NavigationCubit>().selectTab(
                    MainTab.record,
                  ); // Jump to record tab
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'START RUN / WALK',
                      style: AppTextStyles.title(color: retroColors.background),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        HomeFadeIn(
          delayMs: 200,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: aiCoachAsync.when(
              data: (coachData) =>
                  HomeCoachCard(coachData: coachData, colors: retroColors),
              loading: () =>
                  const RetroLoadingIndicator(text: 'COACH IS ANALYZING'),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),
        ),

        HomeFadeIn(
          delayMs: 250,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: GoalsProgressCard(retroColors: retroColors),
          ),
        ),

        HomeFadeIn(
          delayMs: 300,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: HomeDistanceChart(
              chartData: summary.chartData,
              colors: retroColors,
              useMiles: context.watch<DistanceUnitCubit>().state,
            ),
          ),
        ),

        const HomeFadeIn(delayMs: 400, child: WeatherPaceCard()),
        const SizedBox(height: AppSpacing.xl),

        if (week.mostRecentRun != null) ...[
          const SizedBox(height: AppSpacing.xl),
          HomeFadeIn(
            delayMs: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MOST RECENT RUN',
                  style: AppTextStyles.label(color: retroColors.accent),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
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
                      onTap: () {
                        context.read<HapticsCubit>().lightImpact();
                        context.read<AudioCubit>().playActivityTap();
                        AppNavigator.push(
                          context,
                          AppNavigator.materialPageRoute(
                            builder: (context) =>
                                RunDetailScreen(run: week.mostRecentRun!),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: retroColors.accent.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIcons.mapTrifoldFill,
                                color: retroColors.accent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    RunFormatUtils.getRunTitle(
                                      week.mostRecentRun!.title,
                                      week.mostRecentRun!.startTime,
                                      activityType:
                                          week.mostRecentRun!.activityType ??
                                          'run',
                                      distanceM: week.mostRecentRun!.distanceM,
                                      subjectiveEffort:
                                          week.mostRecentRun!.subjectiveEffort,
                                      conditions:
                                          week.mostRecentRun!.conditions,
                                    ),
                                    style: AppTextStyles.bodyLargeBold(
                                      color: retroColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${RunFormatUtils.formatDistance(week.mostRecentRun!.distanceM ?? 0, context.watch<DistanceUnitCubit>().state)} ${RunFormatUtils.getUnitString(context.watch<DistanceUnitCubit>().state)}',
                                    style: AppTextStyles.bodyMedium(
                                      color: retroColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhosphorIcons.caretRight,
                              color: retroColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

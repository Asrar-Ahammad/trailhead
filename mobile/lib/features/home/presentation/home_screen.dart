import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trailhead_mobile/shared/state_management/global/navigation_cubit_main_tab.dart';
import 'package:trailhead_mobile/features/navigation/domain/navigation_entity_main_tab.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/stats/application/weekly_stats_provider.dart';
import 'package:trailhead_mobile/features/stats/application/ai_coach_service.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import '../../run_tracking/application/run_format_utils.dart';
import '../../../shared/state_management/async_value.dart' as StateAsync;
import '../../../shared/state_management/local/async_resource_bloc.dart';

import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';

import 'package:trailhead_mobile/features/home/presentation/widgets/goals_progress_card.dart';
import 'package:trailhead_mobile/features/chat/presentation/chat_screen_coach_conversation.dart';
import 'package:trailhead_mobile/features/weather/presentation/weather_pace_card.dart';
import 'package:trailhead_mobile/features/weather/application/weather_service.dart';
import 'package:trailhead_mobile/features/weather/application/weather_utils.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/home/presentation/widgets/aurora_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ScrollController _scrollController;
  late AsyncResourceBloc<AiCoachData> _aiCoachBloc;
  late AsyncResourceBloc<String?> _trendMessageBloc;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _aiCoachBloc = AsyncResourceBloc<AiCoachData>()
      ..add(LoadResource(() => GetIt.instance<AiCoachService>().loadCoachData()));
    _trendMessageBloc = AsyncResourceBloc<String?>()
      ..add(LoadResource(_loadTrendMessage));
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final isScrolled = _scrollController.hasClients && _scrollController.offset > 10;
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
    _aiCoachBloc.close();
    _trendMessageBloc.close();
    super.dispose();
  }

  Future<String?> _loadTrendMessage() async {
    final summaryJson = GetIt.instance<SharedPreferences>()
        .getString('user_performance_summary');
    if (summaryJson == null) return null;
    final summary = jsonDecode(summaryJson) as Map<String, dynamic>;
    return summary['trendMessage'] as String?;
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final summaryAsync = ref.watch(weeklySummaryProvider);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _aiCoachBloc),
        BlocProvider.value(value: _trendMessageBloc),
      ],
      child: BlocBuilder<AsyncResourceBloc<AiCoachData>, StateAsync.AsyncValue<AiCoachData>>(
        bloc: _aiCoachBloc,
        builder: (context, aiCoachAsync) =>
            BlocBuilder<AsyncResourceBloc<String?>, StateAsync.AsyncValue<String?>>(
          bloc: _trendMessageBloc,
          builder: (context, trendMessageAsync) => Scaffold(
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
            child: ref.watch(weatherPacingProvider).maybeWhen(
              data: (data) {
                final temp = (data['temperature'] as num).round();
                final code = (data['weatherCode'] as num?)?.toInt() ?? 0;
                final isDay = (data['isDay'] as num?)?.toInt() == 1;
                final city = data['city'] as String? ?? '';
                final shortCity = city.split(',').first.trim().toUpperCase();
                final weatherIcon = WeatherUtils.getWeatherIcon(code, isDay: isDay);
                final weatherColor = WeatherUtils.getWeatherColor(code, retroColors, isDay: isDay);

                return GestureDetector(
                  onTap: () {
                    context.read<HapticsCubit>().lightImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.35),
                      isScrollControlled: true,
                      builder: (ctx) => _WeatherDetailsSheet(colors: retroColors, data: data),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: retroColors.surfaceRaised.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: retroColors.border.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          weatherIcon,
                          color: weatherColor,
                          size: 17,
                        ),
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
                              color: retroColors.textSecondary.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            shortCity,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: retroColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: retroColors.surfaceRaised.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: retroColors.accent),
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
            child: AuroraBackground(color1: retroColors.accent, color2: retroColors.accentMuted),
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
                  data: (summary) => _buildContent(context, ref, retroColors, summary, aiCoachAsync, trendMessageAsync),
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
            AppNavigator.push(context, AppNavigator.materialPageRoute(builder: (_) => const ChatScreen()));
          },
          backgroundColor: retroColors.accent,
          child: Icon(PhosphorIcons.sparkleFill, color: retroColors.background),
        ),
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppColors retroColors, WeeklySummary summary, StateAsync.AsyncValue<AiCoachData> aiCoachAsync, StateAsync.AsyncValue<String?> trendMessageAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        trendMessageAsync.when(
          data: (trend) => trend != null && trend.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: SmoothFadeIn(
                    delayMs: 0,
                    child: Text(
                      trend,
                      style: AppTextStyles.bodyLarge(color: retroColors.textSecondary),
                      textAlign: TextAlign.left,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SmoothFadeIn(
          delayMs: 60,
          child: _WeeklySummaryCard(
            summary: summary,
            colors: retroColors,
            useMiles: context.watch<DistanceUnitCubit>().state,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        SmoothFadeIn(
          delayMs: 120,
          child: Container(
            decoration: BoxDecoration(
              color: retroColors.accent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: retroColors.accent,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  context.read<HapticsCubit>().lightImpact();
                  context.read<AudioCubit>().playButtonTap();
                  context.read<NavigationCubit>().selectTab(MainTab.record); // Jump to record tab
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('START RUN / WALK', style: AppTextStyles.title(color: retroColors.background)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        SmoothFadeIn(
          delayMs: 200,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: aiCoachAsync.when(
              data: (coachData) => _AiCoachCard(
                coachData: coachData,
                colors: retroColors,
              ),
              loading: () => const RetroLoadingIndicator(text: 'COACH IS ANALYZING'),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),
        ),
            
        SmoothFadeIn(
          delayMs: 250,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: GoalsProgressCard(retroColors: retroColors),
          ),
        ),

        SmoothFadeIn(
          delayMs: 300,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _DistanceOverTimeCard(
              chartData: summary.chartData,
              colors: retroColors,
              useMiles: context.watch<DistanceUnitCubit>().state,
            ),
          ),
        ),

        const SmoothFadeIn(delayMs: 400, child: WeatherPaceCard()),
        const SizedBox(height: AppSpacing.xl),

        
        if (summary.mostRecentRun != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SmoothFadeIn(
            delayMs: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MOST RECENT RUN', style: AppTextStyles.label(color: retroColors.accent)),
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
                        AppNavigator.push(context,
                          AppNavigator.materialPageRoute(
                            builder: (context) => RunDetailScreen(run: summary.mostRecentRun!),
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
                                color: retroColors.accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(PhosphorIcons.mapTrifoldFill, color: retroColors.accent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    RunFormatUtils.getRunTitle(
                                      summary.mostRecentRun!.title, 
                                      summary.mostRecentRun!.startTime, 
                                      activityType: summary.mostRecentRun!.activityType ?? 'run',
                                      distanceM: summary.mostRecentRun!.distanceM,
                                      subjectiveEffort: summary.mostRecentRun!.subjectiveEffort,
                                      conditions: summary.mostRecentRun!.conditions,
                                    ),
                                    style: AppTextStyles.bodyLargeBold(color: retroColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${RunFormatUtils.formatDistance(summary.mostRecentRun!.distanceM ?? 0, context.watch<DistanceUnitCubit>().state)} ${RunFormatUtils.getUnitString(context.watch<DistanceUnitCubit>().state)}',
                                    style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(PhosphorIcons.caretRight, color: retroColors.textSecondary),
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

class _DistanceOverTimeCard extends StatefulWidget {
  final List<double> chartData;
  final AppColors colors;
  final bool useMiles;

  const _DistanceOverTimeCard({
    required this.chartData,
    required this.colors,
    required this.useMiles,
  });

  @override
  State<_DistanceOverTimeCard> createState() => _DistanceOverTimeCardState();
}

class _DistanceOverTimeCardState extends State<_DistanceOverTimeCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final useMiles = widget.useMiles;
    final unitStr = useMiles ? 'MI' : 'KM';
    final double conversion = useMiles ? 0.621371 : 1.0;

    final convertedData = widget.chartData.map((d) => d * conversion).toList();
    final double maxVal = convertedData.fold<double>(0.0, (prev, val) => val > prev ? val : prev);
    final double maxY = maxVal > 6.0 ? (maxVal * 1.25) : 8.0;

    final todayWeekday = DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'TRAIL // DAILY MILEAGE',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _touchedIndex != null
                      ? colors.accent.withValues(alpha: 0.15)
                      : colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _touchedIndex != null
                      ? '${weekdays[_touchedIndex!]}: ${convertedData[_touchedIndex!].toStringAsFixed(1)} $unitStr'
                      : (maxVal > 0 ? 'PEAK: ${maxVal.toStringAsFixed(1)} $unitStr' : 'NO RUNS THIS WEEK'),
                  style: AppTextStyles.labelCaps(
                    color: _touchedIndex != null ? colors.accent : colors.textSecondary,
                  ).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart Container
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceRaised,
                    tooltipMargin: 6,
                    fitInsideHorizontally: true,
                    fitInsideVertically: false,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipBorder: BorderSide(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY;
                      return BarTooltipItem(
                        '${weekdays[group.x]}\n',
                        AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 10),
                        children: [
                          TextSpan(
                            text: '${val.toStringAsFixed(1)} $unitStr',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapDownEvent || event is FlPanDownEvent) {
                      if (response != null && response.spot != null) {
                        setState(() {
                          _touchedIndex = response.spot!.touchedBarGroupIndex;
                        });
                      }
                    } else if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _touchedIndex = null;
                          });
                        }
                      });
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) return const SizedBox.shrink();
                        final isToday = index == todayWeekday;
                        final isTouched = index == _touchedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            shortDays[index],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: isToday || isTouched ? FontWeight.bold : FontWeight.w500,
                              color: isToday
                                  ? colors.accent
                                  : (isTouched ? colors.textPrimary : colors.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY > 10 ? (maxY / 3).roundToDouble() : 3,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0 || value >= meta.max) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            '${value.toInt()} $unitStr',
                            style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 9),
                            textAlign: TextAlign.right,
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
                    color: colors.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final val = convertedData[index];
                  final isTouched = index == _touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val > 0
                            ? (isTouched ? colors.textPrimary : colors.accent)
                            : Colors.transparent,
                        width: 14,
                        borderRadius: BorderRadius.circular(7),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: colors.surfaceRaised,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  final AiCoachData coachData;
  final AppColors colors;

  const _AiCoachCard({
    required this.coachData,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlag = coachData.fatigueFlag != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Tag + Load Status Pill + Chat Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'AI // ATHLETE COACH',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasFlag
                          ? colors.warning.withValues(alpha: 0.15)
                          : colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasFlag
                              ? PhosphorIcons.warningFill
                              : (coachData.isAiGenerated ? PhosphorIcons.sparkleFill : PhosphorIcons.robotFill),
                          size: 13,
                          color: hasFlag ? colors.warning : colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coachData.loadStatus,
                          style: AppTextStyles.labelCaps(
                            color: hasFlag ? colors.warning : colors.accent,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      AppNavigator.push(context,
                        AppNavigator.materialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.sparkleFill,
                        color: colors.accent,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Fatigue Warning Banner (if present)
          if (hasFlag) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.warningCircle, color: colors.warning, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coachData.fatigueFlag!,
                      style: AppTextStyles.bodyMedium(color: colors.warning).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Coaching Feedback Body
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    coachData.coachingFeedback,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer info & chat link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    coachData.isAiGenerated ? PhosphorIcons.sparkleFill : PhosphorIcons.robotFill,
                    color: colors.accent,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    coachData.isAiGenerated ? 'LLM ENHANCED' : 'LOCAL INTELLIGENCE',
                    style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 9),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  AppNavigator.push(context,
                    AppNavigator.materialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Ask Coach',
                      style: AppTextStyles.labelCaps(color: colors.accent).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(PhosphorIcons.arrowRight, color: colors.accent, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final AppColors colors;
  final bool useMiles;

  const _WeeklySummaryCard({
    required this.summary,
    required this.colors,
    required this.useMiles,
  });

  @override
  Widget build(BuildContext context) {
    final double displayDistance = useMiles ? summary.distanceKm * 0.621371 : summary.distanceKm;
    final String unitStr = useMiles ? 'MI' : 'KM';
    final int activeDaysCount = summary.chartData.where((d) => d > 0).length;
    final double avgPerRun = summary.runCount > 0 ? (displayDistance / summary.runCount) : 0.0;
    final todayWeekday = DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Badge + Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'TRAIL // WEEKLY VOLUME',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              if (summary.streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.flameFill, color: colors.accent, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.streakDays} DAY STREAK',
                        style: AppTextStyles.labelCaps(color: colors.accent).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'WEEK TO DATE',
                    style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Hero Number & 7-Day Rhythm Capsules
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Big distance hero
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayDistance.toStringAsFixed(1),
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unitStr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.runCount == 0
                        ? 'No runs logged yet this week'
                        : '${summary.runCount} ${summary.runCount == 1 ? 'activity' : 'activities'} logged',
                    style: AppTextStyles.bodyMedium(color: colors.textSecondary).copyWith(fontSize: 13),
                  ),
                ],
              ),

              // 7-day mini weekday dots/bars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (i) {
                    final hasRun = summary.chartData[i] > 0;
                    final isToday = i == todayWeekday;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 18,
                            decoration: BoxDecoration(
                              color: hasRun
                                  ? colors.accent
                                  : colors.textSecondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekdays[i],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday
                                  ? (hasRun ? colors.accent : colors.textPrimary)
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sub-metrics row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubMetric(
                  icon: PhosphorIcons.sneakerMove,
                  label: 'ACTIVITIES',
                  value: summary.runCount.toString(),
                  colors: colors,
                ),
                Container(width: 1, height: 24, color: colors.border.withValues(alpha: 0.4)),
                _buildSubMetric(
                  icon: PhosphorIcons.chartLineUp,
                  label: 'AVG / RUN',
                  value: '${avgPerRun.toStringAsFixed(1)} $unitStr',
                  colors: colors,
                ),
                Container(width: 1, height: 24, color: colors.border.withValues(alpha: 0.4)),
                _buildSubMetric(
                  icon: PhosphorIcons.calendarDots,
                  label: 'ACTIVE DAYS',
                  value: '$activeDaysCount / 7',
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.accent, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class SmoothFadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  
  const SmoothFadeIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<SmoothFadeIn> createState() => _SmoothFadeInState();
}

class _SmoothFadeInState extends State<SmoothFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

class _WeatherDetailsSheet extends StatelessWidget {
  final AppColors colors;
  final Map<String, dynamic> data;

  const _WeatherDetailsSheet({
    required this.colors,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final temp = (data['temperature'] as num).round();
    final wind = (data['windSpeed'] as num).round();
    final advice = data['advice'] as String? ?? 'Great conditions for a run.';
    final city = data['city'] as String? ?? 'Local';
    final isDay = (data['isDay'] as num?)?.toInt() == 1;
    final code = (data['weatherCode'] as num?)?.toInt() ?? 0;
    final weatherIcon = WeatherUtils.getWeatherIcon(code, isDay: isDay);
    final weatherColor = WeatherUtils.getWeatherColor(code, colors, isDay: isDay);
    final weatherDesc = WeatherUtils.getWeatherDescription(code);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.88 : 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 44, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: weatherColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: weatherColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(weatherIcon, color: weatherColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherDesc.toUpperCase(),
                            style: AppTextStyles.headline(color: colors.textPrimary),
                          ),
                          Text(city, style: AppTextStyles.label(color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x, color: colors.textSecondary),
                    onPressed: () => AppNavigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Temperature & Wind metrics row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TEMPERATURE', style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('$temp°C', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WIND SPEED', style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('$wind km/h', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pacing Advice Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.lightningFill, color: colors.accent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('COACH ADVICE', style: AppTextStyles.labelCaps(color: colors.accent).copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            advice,
                            style: AppTextStyles.bodyMedium(color: colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

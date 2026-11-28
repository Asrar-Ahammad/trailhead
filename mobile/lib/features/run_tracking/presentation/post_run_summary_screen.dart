import '../domain/run_tracking_use_case_recap_metrics.dart';
import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'dart:async';
import '../state_management/run_tracking_bloc_post_run_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/state_management/global/navigation_cubit_main_tab.dart';
import 'package:trailhead_mobile/features/navigation/domain/navigation_entity_main_tab.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../data/models/run_isar.dart';
import '../application/run_format_utils.dart';
import 'widgets/static_route_map.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/count_up_text.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import '../../history/presentation/share_activity_screen.dart';
import '../../../shared/state_management/async_value.dart' as StateAsync;

/// The signature post-workout completion screen.
class PostRunSummaryScreen extends StatefulWidget {
  const PostRunSummaryScreen({
    super.key,
    required this.run,
    required this.points,
  });

  final RunIsar run;
  final List<LatLng> points;

  @override
  State<PostRunSummaryScreen> createState() => _PostRunSummaryScreenState();
}

class _PostRunSummaryScreenState extends State<PostRunSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final PostRunSummaryBloc _summaryBloc;
  StreamSubscription<StateAsync.AsyncValue<PostRunSummaryData>>?
  _summarySubscription;

  late final AnimationController _staggerController;
  late final Animation<double> _mapFade;
  late final Animation<double> _mapDraw;
  late final Animation<double> _statsFade;
  late final Animation<double> _prSlide;
  late final Animation<double> _aiFade;

  bool _statsAnimationStarted = false;
  bool _prSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    final haptics = context.read<HapticsCubit>();
    final audio = context.read<AudioCubit>();
    _summaryBloc = context.read<CreatePostRunSummaryBloc>()(widget.run);
    _summarySubscription = _summaryBloc.stream.listen((state) {
      if (mounted &&
          state.valueOrNull?.isNewPr == true &&
          _staggerController.value >= 0.4 &&
          !_prSoundPlayed) {
        audio.playPrNew();
        haptics.heavyImpact();
        _prSoundPlayed = true;
      }
    });
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Map fades in (0-300ms)
    _mapFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.1, curve: Curves.easeOut),
      ),
    );

    // Map polyline draws stroke-by-stroke (0-900ms)
    _mapDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Stats fade in (600-1350ms)
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
      ),
    );

    // PR Banner slides up (1200-1800ms) - using elastic curve
    _prSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.4, 0.6, curve: Curves.elasticOut),
      ),
    );

    // AI summary fades in (1800-2400ms)
    _aiFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _staggerController.addListener(() {
      if (_staggerController.value >= 0.2 && !_statsAnimationStarted) {
        setState(() {
          _statsAnimationStarted = true;
        });
      }
      if (_staggerController.value >= 0.4 && !_prSoundPlayed) {
        if (_summaryBloc.state.valueOrNull?.isNewPr == true) {
          audio.playPrNew();
          haptics.heavyImpact();
          _prSoundPlayed = true;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).disableAnimations) {
        _staggerController.value = 1.0;
        setState(() {
          _statsAnimationStarted = true;
        });
      } else {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _summarySubscription?.cancel();
    _summaryBloc.close();
    super.dispose();
  }

  void _saveRun() {
    context.read<HapticsCubit>().mediumImpact();
    context.read<NavigationCubit>().selectTab(MainTab.home); // Go to home
    AppNavigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final useMiles = context.watch<DistanceUnitCubit>().state;
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocProvider.value(
      value: _summaryBloc,
      child:
          BlocBuilder<
            PostRunSummaryBloc,
            StateAsync.AsyncValue<PostRunSummaryData>
          >(
            bloc: _summaryBloc,
            builder: (context, summaryState) => Scaffold(
              backgroundColor: colors.background,
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 48,
                          ), // Top padding for status bar
                          Center(
                            child: Text(
                              'RUN COMPLETED',
                              style: AppTextStyles.labelCaps(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // 1. Fading/Drawing Map
                          AnimatedBuilder(
                            animation: _staggerController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _mapFade.value,
                                child: SizedBox(
                                  height: 250,
                                  child: StaticRouteMap(
                                    points: widget.points,
                                    animationProgress: _mapDraw.value,
                                    isMonochrome: true,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // 2. Fading/Counting Stats
                          FadeTransition(
                            opacity: _statsFade,
                            child: _buildStatsGrid(colors, useMiles),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // 3. PR Banner (if applicable)
                          if (summaryState.valueOrNull?.isNewPr == true)
                            AnimatedBuilder(
                              animation: _prSlide,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * _prSlide.value),
                                  child: Opacity(
                                    opacity: (1.0 - _prSlide.value).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: AppSpacing.xl,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colors.accent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            PhosphorIcons.trophyFill,
                                            color: colors.accent,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'NEW PERSONAL RECORD!',
                                                  style:
                                                      AppTextStyles.labelCaps(
                                                        color: colors.accent,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'You set a new best!',
                                                  style:
                                                      AppTextStyles.bodyMedium(
                                                        color:
                                                            colors.textPrimary,
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
                              },
                            ),

                          // 4. Fading AI Summary
                          FadeTransition(
                            opacity: _aiFade,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.sparkleFill,
                                        color: colors.accent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'AI COACH',
                                        style: AppTextStyles.labelCaps(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  summaryState.when(
                                    data: (summaryData) => Text(
                                      summaryData.aiSummary,
                                      style: AppTextStyles.bodyLarge(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    loading: () => Column(
                                      children: [
                                        LinearProgressIndicator(
                                          color: colors.accent,
                                          backgroundColor: colors.surfaceRaised,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Generating summary...',
                                          style: AppTextStyles.bodyMedium(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    error: (err, stack) => Text(
                                      'Failed to load summary.',
                                      style: AppTextStyles.bodyMedium(
                                        color: colors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 120,
                          ), // Padding for bottom sheet
                        ],
                      ),
                    ),
                  ),

                  // 5. Save/Discard Bottom Sheet
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () {
                                  AppNavigator.push(
                                    context,
                                    AppNavigator.materialPageRoute(
                                      builder: (_) => ShareActivityScreen(
                                        run: widget.run,
                                        points: widget.points,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  PhosphorIcons.shareNetworkBold,
                                  color: colors.textPrimary,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.surfaceRaised,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: BorderSide(
                                      color: colors.border.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveRun,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: Text(
                                    'SAVE RUN',
                                    style: AppTextStyles.bodyLargeBold(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
          ),
    );
  }

  Widget _buildStatsGrid(AppColors colors, bool useMiles) {
    final distance = widget.run.distanceM ?? 0.0;
    final duration = (widget.run.durationS ?? 0).toDouble();
    final pace = widget.run.avgPaceSPerKm ?? 0.0;

    final metrics = recapMetrics(
      distanceM: distance,
      calories: widget.run.caloriesKcal,
      cadence: widget.run.avgCadenceSpm,
      stride: widget.run.avgStrideLengthM,
    );

    // Staggered durations for counting up
    return Column(
      children: [
        // Big Distance
        if (_statsAnimationStarted)
          CountUpText(
            targetValue: distance,
            duration: const Duration(milliseconds: 1500),
            builder: (ctx, val, _) => Text(
              RunFormatUtils.formatDistance(val, useMiles),
              style: AppTextStyles.displayHero(color: colors.textPrimary),
            ),
          )
        else
          Text(
            '0.00',
            style: AppTextStyles.displayHero(color: colors.textPrimary),
          ),

        Text(
          useMiles ? 'MILES' : 'KILOMETERS',
          style: AppTextStyles.labelCaps(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Time & Pace
        AdaptiveColumns(
          maxColumns: 2,
          minColumnWidth: 100,
          children: [
            _buildStatItem(
              'TIME',
              duration,
              1600,
              (val) => RunFormatUtils.formatDuration(val.toInt()),
              colors,
            ),
            _buildStatItem(
              'PACE /${RunFormatUtils.getUnitStringUpper(useMiles)}',
              pace,
              1700,
              (val) =>
                  RunFormatUtils.formatPaceSeconds(val, useMiles: useMiles),
              colors,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Cadence, Stride, Calories
        AdaptiveColumns(
          maxColumns: 3,
          minColumnWidth: 77,
          children: [
            _buildStatItem(
              'CALORIES',
              metrics.calories,
              1800,
              (val) => val.toInt().toString(),
              colors,
              small: true,
            ),
            _buildStatItem(
              'CADENCE',
              metrics.cadence,
              1900,
              (val) => val.toInt().toString(),
              colors,
              small: true,
            ),
            _buildStatItem(
              'STRIDE (M)',
              metrics.stride,
              2000,
              (val) => val.toStringAsFixed(2),
              colors,
              small: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    double target,
    int durationMs,
    String Function(double) formatter,
    AppColors colors, {
    bool small = false,
  }) {
    return Column(
      children: [
        if (_statsAnimationStarted)
          CountUpText(
            targetValue: target,
            duration: Duration(milliseconds: durationMs),
            builder: (ctx, val, _) => Text(
              formatter(val),
              style: small
                  ? AppTextStyles.displayMedium(color: colors.textPrimary)
                  : AppTextStyles.displayStat(color: colors.textPrimary),
            ),
          )
        else
          Text(
            formatter(0),
            style: small
                ? AppTextStyles.displayMedium(color: colors.textPrimary)
                : AppTextStyles.displayStat(color: colors.textPrimary),
          ),

        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelCaps(
            color: colors.textSecondary,
          ).copyWith(fontSize: small ? 10 : 12),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../data/models/run_isar.dart';
import '../application/run_format_utils.dart';
import '../application/mock_ai_summary_service.dart';
import 'widgets/static_route_map.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/count_up_text.dart';
import '../../history/data/run_history_repository.dart';
import '../../stats/application/pr_engine.dart';
import '../../navigation/presentation/main_scaffold.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'dart:math';

final postRunPRProvider = FutureProvider.family<bool, int>((ref, runId) async {
  final engine = ref.read(prEngineProvider);
  final prs = await engine.calculatePRs();
  return prs.any((pr) => pr.run.id == runId);
});

/// The signature post-workout completion screen.
class PostRunSummaryScreen extends ConsumerStatefulWidget {
  const PostRunSummaryScreen({
    super.key,
    required this.run,
    required this.points,
  });

  final RunIsar run;
  final List<LatLng> points;

  @override
  ConsumerState<PostRunSummaryScreen> createState() => _PostRunSummaryScreenState();
}

class _PostRunSummaryScreenState extends ConsumerState<PostRunSummaryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final Animation<double> _mapFade;
  late final Animation<double> _mapDraw;
  late final Animation<double> _statsFade;
  late final Animation<double> _prSlide;
  late final Animation<double> _aiFade;
  
  bool _statsAnimationStarted = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }



  void _saveRun() {
    ref.read(hapticsServiceProvider).mediumImpact();
    ref.read(navigationProvider.notifier).state = 0; // Go to home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final aiSummaryAsync = ref.watch(mockAiSummaryProvider(widget.run));
    final isNewPrAsync = ref.watch(postRunPRProvider(widget.run.id));

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48), // Top padding for status bar
                  Text('RUN COMPLETED', style: AppTextStyles.labelCaps(color: colors.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),

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
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // 2. Fading/Counting Stats
                  FadeTransition(
                    opacity: _statsFade,
                    child: _buildStatsGrid(colors),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // 3. PR Banner (if applicable)
                  isNewPrAsync.when(
                    data: (isNewPr) {
                      if (!isNewPr) return const SizedBox.shrink();
                      return AnimatedBuilder(
                        animation: _prSlide,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * _prSlide.value),
                            child: Opacity(
                              opacity: (1.0 - _prSlide.value).clamp(0.0, 1.0),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.accent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill), color: colors.accent, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('NEW PERSONAL RECORD!', style: AppTextStyles.labelCaps(color: colors.accent)),
                                          const SizedBox(height: 4),
                                          Text('You set a new best!', style: AppTextStyles.bodyMedium(color: colors.textPrimary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // 4. Fading AI Summary
                  FadeTransition(
                    opacity: _aiFade,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: colors.accent, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text('AI COACH', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          aiSummaryAsync.when(
                            data: (summary) => Text(
                              summary,
                              style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                            ),
                            loading: () => Column(
                              children: [
                                LinearProgressIndicator(color: colors.accent, backgroundColor: colors.surfaceRaised),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Generating summary...', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                              ],
                            ),
                            error: (err, stack) => Text('Failed to load summary.', style: AppTextStyles.bodyMedium(color: colors.error)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Padding for bottom sheet
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('SAVE RUN', style: AppTextStyles.bodyLargeBold(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppColors colors) {
    final distance = widget.run.distanceM ?? 0.0;
    final duration = (widget.run.durationS ?? 0).toDouble();
    final pace = widget.run.avgPaceSPerKm ?? 0.0;
    
    // Derived stats if not present
    final kcal = widget.run.caloriesKcal ?? (distance / 1000.0 * 65.0); // Rough estimate
    final cadence = widget.run.avgCadenceSpm ?? 160.0;
    final stride = widget.run.avgStrideLengthM ?? 1.1;

    // Staggered durations for counting up
    return Column(
      children: [
        // Big Distance
        if (_statsAnimationStarted)
          CountUpText(
            targetValue: distance,
            duration: const Duration(milliseconds: 1500),
            builder: (ctx, val, _) => Text(
              RunFormatUtils.formatDistanceKm(val),
              style: AppTextStyles.displayHero(color: colors.textPrimary),
            ),
          )
        else
          Text('0.00', style: AppTextStyles.displayHero(color: colors.textPrimary)),
        
        Text('KILOMETERS', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        
        // Time & Pace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('TIME', duration, 1600, (val) => RunFormatUtils.formatDuration(val.toInt()), colors),
            Container(height: 40, width: 1, color: colors.border),
            _buildStatItem('PACE /KM', pace, 1700, (val) => RunFormatUtils.formatPace(0, val.toInt()), colors),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Cadence, Stride, Calories
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('CALORIES', kcal, 1800, (val) => val.toInt().toString(), colors, small: true),
            Container(height: 30, width: 1, color: colors.border),
            _buildStatItem('CADENCE', cadence, 1900, (val) => val.toInt().toString(), colors, small: true),
            Container(height: 30, width: 1, color: colors.border),
            _buildStatItem('STRIDE (M)', stride, 2000, (val) => val.toStringAsFixed(2), colors, small: true),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double target, int durationMs, String Function(double) formatter, AppColors colors, {bool small = false}) {
    return Column(
      children: [
        if (_statsAnimationStarted)
          CountUpText(
            targetValue: target,
            duration: Duration(milliseconds: durationMs),
            builder: (ctx, val, _) => Text(
              formatter(val),
              style: small ? AppTextStyles.displayMedium(color: colors.textPrimary) : AppTextStyles.displayStat(color: colors.textPrimary),
            ),
          )
        else
          Text(formatter(0), style: small ? AppTextStyles.displayMedium(color: colors.textPrimary) : AppTextStyles.displayStat(color: colors.textPrimary)),
        
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelCaps(color: colors.textSecondary).copyWith(fontSize: small ? 10 : 12)),
      ],
    );
  }
}

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

/// The signature post-workout completion screen.
/// Implements a staggered animation sequence:
/// 1. Map fades in
/// 2. Stats count up
/// 3. AI summary text fades in last
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
  late final Animation<double> _statsFade;
  late final Animation<double> _aiFade;
  
  bool _statsAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Map fades in over first 800ms
    _mapFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // Stats container fades in starting at 600ms
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
      ),
    );

    // AI summary fades in starting at 2000ms
    _aiFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _staggerController.addListener(() {
      if (_staggerController.value >= 0.2 && !_statsAnimationStarted) {
        setState(() {
          _statsAnimationStarted = true;
        });
      }
    });

    // Start sequence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final aiSummaryAsync = ref.watch(mockAiSummaryProvider(widget.run));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(), // Go back to Home/History
        ),
        title: Text('RUN COMPLETED', style: AppTextStyles.labelCaps(color: colors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Fading Map
              FadeTransition(
                opacity: _mapFade,
                child: SizedBox(
                  height: 250,
                  child: StaticRouteMap(points: widget.points),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // 2. Fading/Counting Stats
              FadeTransition(
                opacity: _statsFade,
                child: _buildStatsGrid(colors),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // 3. Fading AI Summary
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppColors colors) {
    // Only animate the numbers if the timeline has reached this point
    final distance = widget.run.distanceM ?? 0.0;
    final duration = (widget.run.durationS ?? 0).toDouble();

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
            Column(
              children: [
                if (_statsAnimationStarted)
                  CountUpText(
                    targetValue: duration,
                    duration: const Duration(milliseconds: 1500),
                    builder: (ctx, val, _) => Text(
                      RunFormatUtils.formatDuration(val.toInt()),
                      style: AppTextStyles.displayStat(color: colors.textPrimary),
                    ),
                  )
                else
                  Text('00:00', style: AppTextStyles.displayStat(color: colors.textPrimary)),
                
                Text('TIME', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
              ],
            ),
            Container(height: 40, width: 1, color: colors.border),
            Column(
              children: [
                if (_statsAnimationStarted)
                  // For pace, we don't 'count up' the pace string easily, 
                  // but we can compute it from the animated distance and duration.
                  // For simplicity and a satisfying feel, we just show the final pace,
                  // or calculate pace from the current animated values.
                  CountUpText(
                    targetValue: 1.0, // dummy target for animation timing
                    duration: const Duration(milliseconds: 1500),
                    builder: (ctx, val, _) {
                      // Interpolate between 0 and final pace
                      return Text(
                        RunFormatUtils.formatPace(distance, (duration * val).toInt()),
                        style: AppTextStyles.displayStat(color: colors.textPrimary),
                      );
                    }
                  )
                else
                  Text('--:--', style: AppTextStyles.displayStat(color: colors.textPrimary)),
                  
                Text('PACE /KM', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/navigation/presentation/navigation_scaffold_main_tabs.dart';
import 'package:trailhead_mobile/shared/state_management/global/onboarding_cubit.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_tracker_controller.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/pressable_scale.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _requestingPermissions = false;

  final int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    context.read<HapticsCubit>().selectionClick();
  }

  void _nextPage() {
    context.read<AudioCubit>().playNavRecord();
    context.read<HapticsCubit>().lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    context.read<AudioCubit>().playRunStart();
    context.read<HapticsCubit>().mediumImpact();
    await context.read<OnboardingCubit>().completeOnboarding();
    if (!mounted) return;
    AppNavigator.replace(context,
      AppNavigator.materialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _requestingPermissions = true);
    context.read<HapticsCubit>().lightImpact();
    try {
      final notifier = context.read<RunTrackerCubit>();
      await notifier.requestForegroundPermission();
      await notifier.requestBackgroundPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions configured!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _requestingPermissions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.navigationArrowFill,
                          color: colors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TRAILHEAD',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        'SKIP',
                        style: AppTextStyles.labelCaps(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Main PageView Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildSlide(
                    colors: colors,
                    badge: 'TRAILHEAD // ENGINE',
                    title: 'PRECISION GPS & DYNAMICS',
                    description:
                        'Live satellite route rendering, high-accuracy pace splits, cadence sensing, and milestone audio cues engineered for runners.',
                    preview: _buildTrackingPreview(colors),
                  ),
                  _buildSlide(
                    colors: colors,
                    badge: 'GEAR LAB // ROTATION',
                    title: 'TRACK SHOE WEAR',
                    description:
                        'Keep your rotation fresh. Log mileage on every pair, capture gear photos, and receive injury-prevention retirement alerts.',
                    preview: _buildShoePreview(colors),
                  ),
                  _buildSlide(
                    colors: colors,
                    badge: 'INTELLIGENCE // PREDICTOR',
                    title: 'RACE PREDICTIONS',
                    description:
                        'AI-powered finish times for 5K, 10K, Half, and Full Marathons adapted dynamically from your pace and volume curves.',
                    preview: _buildPredictionsPreview(colors),
                  ),
                  _buildSlide(
                    colors: colors,
                    badge: 'LOCAL-FIRST // PRIVATE',
                    title: 'READY TO HIT THE ROAD',
                    description:
                        '100% on-device local database. No mandatory accounts or tracking. Enable background location for seamless run logging.',
                    preview: _buildPermissionsPreview(colors),
                  ),
                ],
              ),
            ),

            // Bottom Navigation & CTA Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.accent
                              : colors.textSecondary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Main Button
                  PressableScale(
                    onTap: _nextPage,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'START RUNNING' : 'CONTINUE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? PhosphorIcons.navigationArrowFill
                                : PhosphorIcons.arrowRightBold,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required AppColors colors,
    required String badge,
    required String title,
    required String description,
    required Widget preview,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Visual Interactive Preview Box
          Expanded(
            flex: 5,
            child: Center(
              child: preview,
            ),
          ),

          const SizedBox(height: 20),

          // Badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                badge,
                style: GoogleFonts.pixelifySans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: colors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview 1: Precision Run Tracking HUD
  // ---------------------------------------------------------------------------
  Widget _buildTrackingPreview(AppColors colors) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GPS ACTIVE',
                    style: AppTextStyles.labelCaps(color: colors.success),
                  ),
                ],
              ),
              Icon(PhosphorIcons.personSimpleRun, color: colors.accent, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Hero Distance
          Center(
            child: Column(
              children: [
                Text(
                  '5.24',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1.0,
                  ),
                ),
                Text(
                  'KILOMETERS',
                  style: AppTextStyles.labelCaps(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Secondary Stats Grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('PACE', '4\'38"', colors),
                Container(width: 1, height: 28, color: colors.border),
                _buildStatItem('TIME', '24:18', colors),
                Container(width: 1, height: 28, color: colors.border),
                _buildStatItem('CADENCE', '174', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.label(color: colors.textSecondary).copyWith(fontSize: 10),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Preview 2: Shoe Rotation Card
  // ---------------------------------------------------------------------------
  Widget _buildShoePreview(AppColors colors) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(PhosphorIcons.sneaker, color: colors.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Endorphin Speed 3',
                      style: AppTextStyles.title(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily Trainer & Tempos',
                      style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HEALTHY',
                  style: AppTextStyles.labelCaps(color: colors.success).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mileage Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '342 km logged',
                style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
              ),
              Text(
                '600 km limit',
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 342 / 600,
              minHeight: 8,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(PhosphorIcons.camera, color: colors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Photo inspection enabled',
                style: AppTextStyles.label(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview 3: AI Race Predictor
  // ---------------------------------------------------------------------------
  Widget _buildPredictionsPreview(AppColors colors) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJECTED FINISH TIMES',
                style: AppTextStyles.labelCaps(color: colors.accent),
              ),
              Icon(PhosphorIcons.chartLineUpFill, color: colors.accent, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          _buildRaceTile('5K ROAD RACE', '21:15', '4:15 /km', colors),
          const SizedBox(height: 8),
          _buildRaceTile('10K CLASSIC', '44:30', '4:27 /km', colors),
          const SizedBox(height: 8),
          _buildRaceTile('HALF MARATHON', '1:38:50', '4:41 /km', colors),
        ],
      ),
    );
  }

  Widget _buildRaceTile(String event, String time, String pace, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event,
                style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
              ),
              Text(
                pace,
                style: AppTextStyles.label(color: colors.textSecondary).copyWith(fontSize: 11),
              ),
            ],
          ),
          Text(
            time,
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview 4: Permissions / Ready
  // ---------------------------------------------------------------------------
  Widget _buildPermissionsPreview(AppColors colors) {
    final trackerState = context.watch<RunTrackerCubit>().state;
    final isGranted = trackerState.permissionsGranted;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? PhosphorIcons.checkCircleFill : PhosphorIcons.shieldCheckBold,
                color: isGranted ? colors.success : colors.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                isGranted ? 'PERMISSIONS READY' : 'QUICK SETUP',
                style: AppTextStyles.labelCaps(
                  color: isGranted ? colors.success : colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPermBullet(
            icon: PhosphorIcons.navigationArrowFill,
            title: 'Location Services',
            desc: 'Map routes & live pace calculation',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _buildPermBullet(
            icon: PhosphorIcons.footprintsFill,
            title: 'Physical Activity',
            desc: 'Step count & cadence metrics',
            colors: colors,
          ),
          const SizedBox(height: 16),
          PressableScale(
            onTap: _requestingPermissions || isGranted ? null : _requestPermissions,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isGranted
                    ? colors.success.withValues(alpha: 0.15)
                    : colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGranted ? colors.success : colors.accent,
                ),
              ),
              alignment: Alignment.center,
              child: _requestingPermissions
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accent,
                      ),
                    )
                  : Text(
                      isGranted ? '✓ PERMISSIONS GRANTED' : 'ENABLE PERMISSIONS NOW',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isGranted ? colors.success : colors.accent,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermBullet({
    required IconData icon,
    required String title,
    required String desc,
    required AppColors colors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: colors.accent, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
              ),
              Text(
                desc,
                style: AppTextStyles.label(color: colors.textSecondary).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

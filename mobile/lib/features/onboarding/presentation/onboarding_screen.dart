import 'widgets/onboarding_widget_slide.dart';
import 'widgets/onboarding_widget_tour_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/navigation/presentation/navigation_scaffold_main_tabs.dart';
import '../state_management/onboarding_bloc_setup.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/pressable_scale.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateOnboardingBloc>()(),
    child: const _OnboardingTour(),
  );
}

class _OnboardingTour extends StatefulWidget {
  const _OnboardingTour();

  @override
  State<_OnboardingTour> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingTour> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  void _finishOnboarding() {
    context.read<AudioCubit>().playRunStart();
    context.read<HapticsCubit>().mediumImpact();
    context.read<OnboardingBloc>().add(OnboardingAction.finish);
  }

  void _requestPermissions() {
    context.read<HapticsCubit>().lightImpact();
    context.read<OnboardingBloc>().add(OnboardingAction.requestPermissions);
  }

  void _onStatusChanged(BuildContext context, OnboardingStatus status) {
    if (status == OnboardingStatus.finished && AppNavigator.canPop(context)) {
      AppNavigator.replace(
        context,
        AppNavigator.materialPageRoute(builder: (_) => const MainScaffold()),
      );
      return;
    }
    final message = switch (status) {
      OnboardingStatus.granted => 'Permissions configured!',
      OnboardingStatus.denied =>
        'Location permissions are incomplete. You can retry or continue.',
      OnboardingStatus.saveFailed =>
        'Could not save the tour. Please try again.',
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isLastPage = _currentPage == _totalPages - 1;

    return BlocListener<OnboardingBloc, OnboardingStatus>(
      listener: _onStatusChanged,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: Logo + Skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          Flexible(
                            child: Text(
                              'TRAILHEAD',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'SKIP',
                          style: AppTextStyles.labelCaps(
                            color: colors.textSecondary,
                          ),
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
                    OnboardingSlide(
                      colors: colors,
                      badge: 'TRAILHEAD // ENGINE',
                      title: 'PRECISION GPS & DYNAMICS',
                      description:
                          'Live satellite route rendering, high-accuracy pace splits, cadence sensing, and milestone audio cues engineered for runners.',
                      preview: onboardingTrackingPreview(colors),
                    ),
                    OnboardingSlide(
                      colors: colors,
                      badge: 'GEAR LAB // ROTATION',
                      title: 'TRACK SHOE WEAR',
                      description:
                          'Keep your rotation fresh. Log mileage on every pair, capture gear photos, and receive injury-prevention retirement alerts.',
                      preview: onboardingShoePreview(colors),
                    ),
                    OnboardingSlide(
                      colors: colors,
                      badge: 'INTELLIGENCE // PREDICTOR',
                      title: 'RACE PREDICTIONS',
                      description:
                          'AI-powered finish times for 5K, 10K, Half, and Full Marathons adapted dynamically from your pace and volume curves.',
                      preview: onboardingPredictionsPreview(colors),
                    ),
                    OnboardingSlide(
                      colors: colors,
                      badge: 'LOCAL-FIRST // PRIVATE',
                      title: 'READY TO HIT THE ROAD',
                      description:
                          '100% on-device local database. No mandatory accounts or tracking. Enable background location for seamless run logging.',
                      preview: onboardingPermissionsPreview(
                        colors,
                        requesting: context.select(
                          (OnboardingBloc bloc) =>
                              bloc.state == OnboardingStatus.requesting,
                        ),
                        isGranted: context.select(
                          (RunTrackerCubit tracker) =>
                              tracker.state.permissionsGranted,
                        ),
                        onRequest: _requestPermissions,
                      ),
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
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                            Flexible(
                              child: Text(
                                isLastPage ? 'START RUNNING' : 'CONTINUE',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
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
      ),
    );
  }
}

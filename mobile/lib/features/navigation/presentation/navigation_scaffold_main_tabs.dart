import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:trailhead_mobile/shared/state_management/global/navigation_cubit_main_tab.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/active_run_screen.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_route_map.dart';
import 'package:trailhead_mobile/features/home/presentation/home_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';
import '../domain/navigation_entity_main_tab.dart';
import '../domain/navigation_use_case_confirm_exit.dart';
import 'navigation_widget_exit_toast.dart';
import 'navigation_widget_main_tab_bar.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _isAtBottom = false;
  final _confirmExit = ConfirmAppExit();
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void dispose() {
    _removeExitToast();
    super.dispose();
  }

  void _removeExitToast() {
    _toastTimer?.cancel();
    final entry = _toastEntry;
    _toastEntry = null;
    entry?.remove();
    entry?.dispose();
  }

  void _showExitToast(BuildContext context) {
    _removeExitToast();
    final colors = Theme.of(context).extension<AppColors>()!;
    final overlayState = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => NavigationExitToast(colors: colors),
    );

    _toastEntry = entry;
    overlayState.insert(entry);

    _toastTimer = Timer(const Duration(milliseconds: 2200), _removeExitToast);
  }

  void _onTabChanged(BuildContext context, MainTab tab) {
    if (_isAtBottom) setState(() => _isAtBottom = false);
    final tracker = context.read<RunTrackerCubit>();
    if (tab == MainTab.record && tracker.state.status == 'idle') {
      context.read<RunRouteMapCubit>().recenter();
      unawaited(tracker.fetchInitialLocation(force: true));
    }
  }

  void _selectTab(MainTab tab) {
    final navigation = context.read<NavigationCubit>();
    if (navigation.state == tab) return;
    context.read<HapticsCubit>().lightImpact();
    final audio = context.read<AudioCubit>();
    switch (tab) {
      case MainTab.home:
        audio.playNavHome();
      case MainTab.record:
        audio.playNavRecord();
      case MainTab.you:
        audio.playNavYou();
    }
    navigation.selectTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<NavigationCubit>().state;
    final isRunning = context.select(
      (RunTrackerCubit tracker) => tracker.state.status != 'idle',
    );
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientOpacity = isDarkMode ? 0.15 : 0.04;

    return BlocListener<NavigationCubit, MainTab>(
      listener: _onTabChanged,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          context.read<AudioCubit>().playSystemBack();
          if (!_confirmExit(DateTime.now())) {
            _showExitToast(context);
            return;
          }

          _removeExitToast();
          await SystemNavigator.pop();
        },
        child: Scaffold(
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                final isAtBottom = notification.metrics.extentAfter < 20.0;
                if (isAtBottom != _isAtBottom) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isAtBottom = isAtBottom;
                      });
                    }
                  });
                }
              }
              return false;
            },
            child: IndexedStack(
              index: tab.index,
              children: const [HomeScreen(), ActiveRunScreen(), YouScreen()],
            ),
          ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0, // Expand/collapse from top
              child: child,
            ),
            child: (isRunning && tab == MainTab.record)
                ? const SizedBox(
                    key: ValueKey('empty_nav'),
                    width: double.infinity,
                    height: 0,
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    key: const ValueKey('nav_bar'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          (_isAtBottom || tab == MainTab.record)
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: gradientOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(72, 0, 72, 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 20.0,
                              sigmaY: 20.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: retroColors.surface.withValues(
                                  alpha: isDarkMode ? 0.35 : 0.45,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: retroColors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: retroColors.border.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: NavigationTabBar(
                                selectedTab: tab,
                                colors: retroColors,
                                onTap: _selectTab,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/active_run_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_tracker_controller.dart';
import 'package:trailhead_mobile/features/home/presentation/home_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';

final navigationProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isAtBottom = false;
  DateTime? _lastBackPressedAt;
  OverlayEntry? _toastEntry;

  void _showExitToast(BuildContext context) {
    _toastEntry?.remove();
    _toastEntry = null;

    final colors = Theme.of(context).extension<AppColors>()!;
    final overlayState = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ExitToastWidget(colors: colors),
    );

    _toastEntry = entry;
    overlayState.insert(entry);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(navigationProvider, (previous, next) {
      if (previous != next && mounted) {
        setState(() {
          _isAtBottom = false;
        });
      }
    });

    final currentIndex = ref.watch(navigationProvider);
    final runState = ref.watch(runTrackerProvider);
    final isRunning = runState.status != 'idle';
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientOpacity = isDarkMode ? 0.9 : 0.1;

    final screens = [
      const HomeScreen(),
      const ActiveRunScreen(),
      const YouScreen(),
    ];

    void onTabTapped(int index) {
      if (currentIndex == index) return;
      ref.read(hapticsServiceProvider).lightImpact();
      final soundService = ref.read(soundServiceProvider);
      if (index == 0) {
        soundService.playNavHome();
      } else if (index == 1) {
        soundService.playNavRecord();
      } else if (index == 2) {
        soundService.playNavYou();
      }
      ref.read(navigationProvider.notifier).state = index;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        const maxDuration = Duration(seconds: 2);
        final isFirstPress = _lastBackPressedAt == null ||
            now.difference(_lastBackPressedAt!) > maxDuration;

        // Play retro back sound on every back press
        ref.read(soundServiceProvider).playSystemBack();

        if (isFirstPress) {
          _lastBackPressedAt = now;
          _showExitToast(context);
          return;
        }

        // Second press within 2 seconds — truly exit the app
        SystemNavigator.pop();
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
          index: currentIndex,
          children: screens,
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
        child: isRunning
            ? const SizedBox(key: ValueKey('empty_nav'), width: double.infinity, height: 0)
            : AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                key: const ValueKey('nav_bar'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (_isAtBottom || currentIndex == 1) ? Colors.transparent : Colors.black.withOpacity(gradientOpacity),
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
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: retroColors.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: retroColors.border.withOpacity(0.4), 
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _AnimatedNavBar(
                            currentIndex: currentIndex,
                            colors: retroColors,
                            onTap: onTabTapped,
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

class _AnimatedNavBar extends StatelessWidget {
  const _AnimatedNavBar({
    required this.currentIndex,
    required this.colors,
    required this.onTap,
  });

  final int currentIndex;
  final AppColors colors;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 3;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'HOME',
                iconRegular: PhosphorIconsRegular.house,
                iconFill: PhosphorIconsFill.house,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(0),
              ),
              _NavBarItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'RECORD',
                iconRegular: PhosphorIconsRegular.personSimpleRun,
                iconFill: PhosphorIconsFill.personSimpleRun,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(1),
              ),
              _NavBarItem(
                index: 2,
                currentIndex: currentIndex,
                label: 'YOU',
                iconRegular: PhosphorIconsRegular.user,
                iconFill: PhosphorIconsFill.user,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(2),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.iconRegular,
    required this.iconFill,
    required this.colors,
    required this.width,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final IconData iconRegular;
  final IconData iconFill;
  final AppColors colors;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: PhosphorIcon(
                isSelected ? iconFill : iconRegular,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? colors.accent : colors.textSecondary,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected 
                ? Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      label, 
                      style: AppTextStyles.labelCaps(color: colors.accent).copyWith(fontSize: 10),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitToastWidget extends StatefulWidget {
  final AppColors colors;
  const _ExitToastWidget({required this.colors});

  @override
  State<_ExitToastWidget> createState() => _ExitToastWidgetState();
}

class _ExitToastWidgetState extends State<_ExitToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Fade out before removal
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Material(
              type: MaterialType.transparency,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.colors.accent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colors.accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Press back again to exit',
                    style: TextStyle(
                      color: widget.colors.background,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
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

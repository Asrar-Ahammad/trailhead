import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/active_run_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_tracker_controller.dart';
import 'package:trailhead_mobile/features/home/presentation/home_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';

final navigationProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final runState = ref.watch(runTrackerProvider);
    final isRunning = runState.status != 'idle';
    final retroColors = Theme.of(context).extension<AppColors>()!;

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

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
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
            : SafeArea(
                key: const ValueKey('nav_bar'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 72, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: retroColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: retroColors.border, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
          final dotLeft = (currentIndex * itemWidth) + (itemWidth / 2) - 2;

          return Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    index: 0,
                    currentIndex: currentIndex,
                    iconRegular: PhosphorIconsRegular.house,
                    iconFill: PhosphorIconsFill.house,
                    colors: colors,
                    width: itemWidth,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    index: 1,
                    currentIndex: currentIndex,
                    iconRegular: PhosphorIconsRegular.personSimpleRun,
                    iconFill: PhosphorIconsFill.personSimpleRun,
                    colors: colors,
                    width: itemWidth,
                    onTap: () => onTap(1),
                  ),
                  _NavBarItem(
                    index: 2,
                    currentIndex: currentIndex,
                    iconRegular: PhosphorIconsRegular.user,
                    iconFill: PhosphorIconsFill.user,
                    colors: colors,
                    width: itemWidth,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: 12,
                left: dotLeft,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.rectangle,
                  ),
                ),
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
    required this.iconRegular,
    required this.iconFill,
    required this.colors,
    required this.width,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Padding(
            key: ValueKey<bool>(isSelected),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: PhosphorIcon(
              isSelected ? iconFill : iconRegular,
              color: isSelected ? colors.accent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

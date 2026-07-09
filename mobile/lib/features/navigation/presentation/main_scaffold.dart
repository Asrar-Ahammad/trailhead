import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/active_run_screen.dart';
import 'package:trailhead_mobile/features/home/presentation/home_screen.dart';
import 'package:trailhead_mobile/features/you/presentation/you_screen.dart';

final navigationProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final retroColors = Theme.of(context).extension<AppColors>()!;

    final screens = [
      const HomeScreen(),
      const ActiveRunScreen(),
      const YouScreen(),
    ];

    void onTabTapped(int index) {
      if (currentIndex == index) return;
      ref.read(hapticsServiceProvider).lightImpact();
      ref.read(soundServiceProvider).playNavBlip();
      ref.read(navigationProvider.notifier).state = index;
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 72, 24),
          child: Container(
            decoration: BoxDecoration(
              color: retroColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: retroColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  elevation: 0,
                  currentIndex: currentIndex,
                  onTap: onTabTapped,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: retroColors.accent,
          unselectedItemColor: retroColors.textSecondary,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 12,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 12,
            height: 1.5,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: PhosphorIcon(PhosphorIconsRegular.house),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsFill.house, color: retroColors.accent),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: retroColors.accent,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
              ),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: PhosphorIcon(PhosphorIconsRegular.personSimpleRun),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsFill.personSimpleRun, color: retroColors.accent),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: retroColors.accent,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
              ),
              label: 'RECORD',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: PhosphorIcon(PhosphorIconsRegular.user),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsFill.user, color: retroColors.accent),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: retroColors.accent,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
              ),
              label: 'YOU',
            ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

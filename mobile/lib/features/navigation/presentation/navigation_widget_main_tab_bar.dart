import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/navigation_entity_main_tab.dart';

class NavigationTabBar extends StatelessWidget {
  const NavigationTabBar({
    super.key,
    required this.selectedTab,
    required this.colors,
    required this.onTap,
  });

  final MainTab selectedTab;
  final AppColors colors;
  final ValueChanged<MainTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / MainTab.values.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                tab: MainTab.home,
                selectedTab: selectedTab,
                label: 'HOME',
                iconRegular: PhosphorIconsRegular.house,
                iconFill: PhosphorIconsFill.house,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(MainTab.home),
              ),
              _NavBarItem(
                tab: MainTab.record,
                selectedTab: selectedTab,
                label: 'RECORD',
                iconRegular: PhosphorIconsRegular.personSimpleRun,
                iconFill: PhosphorIconsFill.personSimpleRun,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(MainTab.record),
              ),
              _NavBarItem(
                tab: MainTab.you,
                selectedTab: selectedTab,
                label: 'YOU',
                iconRegular: PhosphorIconsRegular.user,
                iconFill: PhosphorIconsFill.user,
                colors: colors,
                width: itemWidth,
                onTap: () => onTap(MainTab.you),
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
    required this.tab,
    required this.selectedTab,
    required this.label,
    required this.iconRegular,
    required this.iconFill,
    required this.colors,
    required this.width,
    required this.onTap,
  });

  final MainTab tab;
  final MainTab selectedTab;
  final String label;
  final IconData iconRegular;
  final IconData iconFill;
  final AppColors colors;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = tab == selectedTab;

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
                        style: AppTextStyles.labelCaps(
                          color: colors.accent,
                        ).copyWith(fontSize: 10),
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

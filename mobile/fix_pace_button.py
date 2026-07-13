import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# Replace the onTap for the Pace button
new_on_tap = '''                    onTap: () {
                      if (isIdle) {
                        ref.read(hapticsServiceProvider).lightImpact();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: colors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (ctx) => _TargetPaceSelectorSheet(colors: colors),
                        );
                      }
                    },'''

content = re.sub(
    r"                    onTap: \(\) \{\n                      if \(isIdle\) \{\n                        // Quick way to set target pace\n                        final currentPace = trackerState\.targetPaceSPerKm \?\? 360;\n                        notifier\.setTargetPace\(currentPace - 10\);\n                        ref\.read\(hapticsServiceProvider\)\.lightImpact\(\);\n                      \}\n                    \},",
    new_on_tap,
    content
)

# Append the new _TargetPaceSelectorSheet class at the end of the file
new_sheet_class = '''
class _TargetPaceSelectorSheet extends ConsumerWidget {
  const _TargetPaceSelectorSheet({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(runTrackerProvider);
    final notifier = ref.read(runTrackerProvider.notifier);
    
    final currentPace = trackerState.targetPaceSPerKm;
    final String paceStr = currentPace != null 
        ? '${(currentPace / 60).floor()}:${(currentPace % 60).toString().padLeft(2, '0')}'
        : 'None';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Target Pace',
              style: AppTextStyles.headline(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.minusCircle(PhosphorIconsStyle.fill), color: colors.accent, size: 48),
                  onPressed: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    ref.read(soundServiceProvider).playPaceDown();
                    final newPace = (currentPace ?? 360) + 10;
                    notifier.setTargetPace(newPace);
                  },
                ),
                Text(paceStr, style: AppTextStyles.displayHero(color: colors.textPrimary)),
                IconButton(
                  icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill), color: colors.accent, size: 48),
                  onPressed: () {
                    ref.read(hapticsServiceProvider).lightImpact();
                    ref.read(soundServiceProvider).playPaceUp();
                    final newPace = (currentPace ?? 360) - 10;
                    if (newPace > 0) notifier.setTargetPace(newPace);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                if (currentPace == null) {
                  notifier.setTargetPace(360);
                } else {
                  notifier.setTargetPace(null); // Clear pace
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surfaceRaised,
                foregroundColor: colors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(currentPace == null ? 'Set Default Pace' : 'Clear Target Pace', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
'''

content += new_sheet_class

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)


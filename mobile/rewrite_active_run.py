import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# We need to completely rewrite the build method of ActiveRunScreen
new_build = '''  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(runTrackerProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    if (!trackerState.permissionsGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PermissionGateScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background Map (Full Screen)
          LiveRunMap(
            initialLocation: trackerState.initialPosition != null 
                ? LatLng(trackerState.initialPosition!.latitude, trackerState.initialPosition!.longitude)
                : null,
          ),
          
          // Floating Elements overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top area: GPS warning (if any)
                if (trackerState.gpsWeak)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.warning(PhosphorIconsStyle.bold), color: colors.background, size: 16),
                          const SizedBox(width: 8),
                          Text('NO GPS SIGNAL', style: AppTextStyles.labelCaps(color: colors.background)),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Bottom area: Stats card + Controls sheet
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatPanel(trackerState: trackerState, colors: colors),
                    const SizedBox(height: 16),
                    _RunControls(
                      trackerState: trackerState,
                      colors: colors,
                      onStop: () {
                        ref.read(runTrackerProvider.notifier).pauseRun();
                        _showStopSheet(context, ref, colors, trackerState.activityType);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }'''

content = re.sub(r'  @override\n  Widget build\(BuildContext context, WidgetRef ref\) \{.*?  void _showStopSheet', new_build + '\n\n  void _showStopSheet', content, flags=re.DOTALL)

# Rewrite _StatPanel
new_stat_panel = '''class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.trackerState, required this.colors});

  final RunTrackerState trackerState;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card like the image
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Time
              _StatColumn(
                value: RunFormatUtils.formatDuration(trackerState.durationS),
                label: 'Time',
              ),
              
              // Pace
              _StatColumn(
                value: trackerState.currentSplitPaceSPerKm != null
                    ? '${(trackerState.currentSplitPaceSPerKm! / 60).floor()}:${(trackerState.currentSplitPaceSPerKm! % 60).toString().padLeft(2, '0')}'
                    : RunFormatUtils.formatPace(trackerState.distanceM, trackerState.durationS),
                label: trackerState.currentSplitPaceSPerKm != null ? 'Split avg. (/km)' : 'Pace (/km)',
                isCenter: true,
              ),

              // Distance
              _StatColumn(
                value: RunFormatUtils.formatDistanceKm(trackerState.distanceM),
                label: 'Distance (km)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label, this.isCenter = false});
  final String value;
  final String label;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (isCenter) 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 16, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Container(width: 16, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}'''

content = re.sub(r'class _StatPanel extends StatelessWidget \{.*?class _PaceComparisonBadge', new_stat_panel + '\n\nclass _PaceComparisonBadge', content, flags=re.DOTALL)

# Rewrite _RunControls
new_run_controls = '''class _RunControls extends StatelessWidget {
  const _RunControls({
    required this.trackerState,
    required this.colors,
    required this.onStop,
  });

  final RunTrackerState trackerState;
  final AppColors colors;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final notifier = ref.read(runTrackerProvider.notifier);
        final status = trackerState.status;
        final isIdle = status == 'idle';
        final isPaused = status == 'paused';

        final isRun = trackerState.activityType == 'run';

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Dark sheet color
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 40, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left Action (Activity Toggle or Stop)
                  _CircularAction(
                    icon: isIdle ? (isRun ? PhosphorIcons.personSimpleRun() : PhosphorIcons.personSimpleWalk()) : PhosphorIcons.stop(PhosphorIconsStyle.fill),
                    label: isIdle ? (isRun ? 'Run' : 'Walk') : 'Stop',
                    color: const Color(0xFF2C2C2C),
                    iconColor: isIdle ? colors.accent : colors.error,
                    onTap: () {
                      if (isIdle) {
                        ref.read(hapticsServiceProvider).lightImpact();
                        notifier.setActivityType(isRun ? 'walk' : 'run');
                      } else {
                        onStop();
                      }
                    },
                  ),

                  // Center Action (Start / Pause / Resume)
                  GestureDetector(
                    onTap: () {
                      if (isIdle) {
                        ref.read(soundServiceProvider).playRunStart();
                        notifier.startRun();
                      } else if (isPaused) {
                        ref.read(soundServiceProvider).playPauseResume();
                        notifier.resumeRun();
                      } else {
                        ref.read(soundServiceProvider).playPauseResume();
                        notifier.pauseRun();
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isIdle || isPaused ? PhosphorIcons.play(PhosphorIconsStyle.fill) : PhosphorIcons.pause(PhosphorIconsStyle.fill),
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  // Right Action (Target Pace)
                  _CircularAction(
                    icon: PhosphorIcons.target(),
                    label: 'Pace',
                    color: const Color(0xFF2C2C2C),
                    iconColor: Colors.white,
                    onTap: () {
                      if (isIdle) {
                        // Quick way to set target pace
                        final currentPace = trackerState.targetPaceSPerKm ?? 360;
                        notifier.setTargetPace(currentPace - 10);
                        ref.read(hapticsServiceProvider).lightImpact();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularAction extends StatelessWidget {
  const _CircularAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}'''

content = re.sub(r'class _RunControls extends StatelessWidget \{.*?class _TargetPaceSelector', new_run_controls + '\n\nclass _TargetPaceSelector', content, flags=re.DOTALL)

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)

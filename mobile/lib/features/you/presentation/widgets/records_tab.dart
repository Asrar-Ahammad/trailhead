import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/features/stats/application/pr_engine.dart';
import 'package:trailhead_mobile/features/history/presentation/run_detail_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import '../you_screen.dart';

class RecordsTab extends ConsumerStatefulWidget {
  const RecordsTab({super.key});

  @override
  ConsumerState<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends ConsumerState<RecordsTab> {
  static const Map<String, String> _categoryDisplayNames = {
    '100m': '100 METERS',
    '400m': '400 METERS',
    '1k': '1 KILOMETER',
    '1 mile': '1 MILE',
    '5k': '5 KILOMETERS',
    '10k': '10 KILOMETERS',
    'half': 'HALF MARATHON',
    'marathon': 'FULL MARATHON',
    'longest_run': 'LONGEST DISTANCE',
    'longest_duration': 'LONGEST DURATION',
    'max_elevation': 'MAX ELEVATION',
  };

  String _formatCategoryName(String category) {
    return _categoryDisplayNames[category.toLowerCase()] ?? category.toUpperCase();
  }

  String _formatValue(String category, double value) {
    if (category == 'longest_run') {
      return '${(value / 1000).toStringAsFixed(2)} km';
    }
    if (category == 'max_elevation') {
      return '${value.toStringAsFixed(0)} m';
    }

    final totalSeconds = value.round();
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPace(String category, double value, bool useMiles) {
    double distanceM = 0;
    final cat = category.toLowerCase();
    if (cat == '100m') {
      distanceM = 100;
    } else if (cat == '400m') {
      distanceM = 400;
    } else if (cat == '1k') {
      distanceM = 1000;
    } else if (cat == '1 mile') {
      distanceM = 1609.34;
    } else if (cat == '5k') {
      distanceM = 5000;
    } else if (cat == '10k') {
      distanceM = 10000;
    } else if (cat == 'half') {
      distanceM = 21097.5;
    } else if (cat == 'marathon') {
      distanceM = 42195;
    }

    if (distanceM > 0) {
      final unitSuffix = useMiles ? '/mi' : '/km';
      return '${RunFormatUtils.formatPace(distanceM, value.toInt(), useMiles)} $unitSuffix';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final prsAsync = ref.watch(prsProvider);
    final mode = ref.watch(recordsModeProvider);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + kTextTabBarHeight;
    final useMiles = context.watch<DistanceUnitCubit>().state;

    return RefreshIndicator(
      color: retroColors.accent,
      backgroundColor: retroColors.surface,
      edgeOffset: topInset - 70,
      onRefresh: () async {
        ref.invalidate(prsProvider);
      },
      child: prsAsync.when(
        data: (group) {
          final recordsList = mode == 'best_effort' ? group.bestEffort : group.manual;

          // Group records by category
          Map<String, List<PersonalRecord>> grouped = {};
          for (final pr in recordsList) {
            grouped.putIfAbsent(pr.category.toLowerCase(), () => []).add(pr);
          }

          final standardCategories = [
            '100m',
            '400m',
            '1k',
            '1 mile',
            '5k',
            '10k',
            'half',
            'marathon',
            'longest_run',
            'longest_duration',
            'max_elevation',
          ];

          List<dynamic> items = [];
          for (final cat in standardCategories) {
            if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) {
              items.add(cat);
              items.addAll(grouped[cat]!);
            }
          }

          grouped.forEach((key, val) {
            if (!standardCategories.contains(key) && val.isNotEmpty) {
              items.add(key);
              items.addAll(val);
            }
          });

          return CustomScrollView(
            slivers: [
              // 1. Retro Segmented Mode Switcher (Sliding Animated Pill)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, topInset - 70, 16, 6),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final pillWidth = (constraints.maxWidth - 8) / 2;
                      final isBestEffort = mode == 'best_effort';
                      return Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: retroColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: retroColors.border.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            // ── Sliding Animated Accent Pill ──
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOutCubic,
                              alignment: isBestEffort ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                width: pillWidth,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: retroColors.accent,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            // ── Interactive Labels ──
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (mode != 'best_effort') {
                                        context.read<HapticsCubit>().lightImpact();
                                        context.read<AudioCubit>().playTabBestEfforts();
                                        ref.read(recordsModeProvider.notifier).state = 'best_effort';
                                      }
                                    },
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: isBestEffort ? retroColors.surface : retroColors.textSecondary,
                                        ),
                                        child: const Text('BEST EFFORTS'),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (mode != 'manual') {
                                        context.read<HapticsCubit>().lightImpact();
                                        context.read<AudioCubit>().playTabAllTime();
                                        ref.read(recordsModeProvider.notifier).state = 'manual';
                                      }
                                    },
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: !isBestEffort ? retroColors.surface : retroColors.textSecondary,
                                        ),
                                        child: const Text('ALL-TIME (MANUAL)'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Trophy Info & Action Strip
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: retroColors.surfaceRaised.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: retroColors.border.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.trophyFill, color: retroColors.accent, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${recordsList.length} BENCHMARKS RECORDED',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: retroColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode == 'best_effort'
                                      ? 'Calculated automatically from GPS splits'
                                      : 'Personal records logged manually by you',
                                  style: AppTextStyles.label(color: retroColors.textSecondary).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (mode == 'manual')
                          InkWell(
                            onTap: () {
                              context.read<HapticsCubit>().lightImpact();
                              _showAddPRBottomSheet(context, retroColors);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: retroColors.accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIcons.plusBold, size: 12, color: retroColors.surface),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADD PR',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: retroColors.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Records List or Empty State
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: retroColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: retroColors.border.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(PhosphorIcons.trophy, size: 36, color: retroColors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          mode == 'best_effort' ? 'NO GPS BENCHMARKS YET' : 'NO MANUAL RECORDS LOGGED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: retroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode == 'best_effort'
                              ? 'Complete GPS outdoor runs to automatically compute your fastest 1K, 5K, 10K, and half marathon efforts.'
                              : 'Tap "+ ADD PR" above to manually log your all-time track meets and race results.',
                          style: AppTextStyles.bodyMedium(color: retroColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (mode == 'manual') ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<HapticsCubit>().lightImpact();
                              _showAddPRBottomSheet(context, retroColors);
                            },
                            icon: const Icon(PhosphorIcons.plusBold, size: 16),
                            label: const Text('LOG FIRST RECORD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: retroColors.accent,
                              foregroundColor: retroColors.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        if (item is String) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: retroColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatCategoryName(item),
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: retroColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final pr = item as PersonalRecord;
                        return _buildRecordCard(pr, retroColors, useMiles);
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              // Bottom Padding
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 120),
                sliver: SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: retroColors.accent)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium(color: retroColors.error))),
      ),
    );
  }



  Widget _buildRecordCard(PersonalRecord pr, AppColors retroColors, bool useMiles) {
    final mode = ref.watch(recordsModeProvider);
    final formattedValue = _formatValue(pr.category, pr.value);
    final paceStr = _formatPace(pr.category, pr.value, useMiles);
    final dateStr = DateFormat('MMM d, yyyy').format(pr.achievedAt);

    // Rank styling
    Color rankColor = retroColors.textSecondary;
    String rankLabel = 'PR';
    IconData rankIcon = PhosphorIcons.trophyFill;

    if (pr.rank == 1) {
      rankColor = retroColors.warning; // Gold
      rankLabel = 'GOLD #1';
      rankIcon = PhosphorIcons.trophyFill;
    } else if (pr.rank == 2) {
      rankColor = retroColors.textSecondary; // Silver
      rankLabel = 'SILVER #2';
      rankIcon = PhosphorIcons.medal;
    } else if (pr.rank == 3) {
      rankColor = retroColors.accent; // Bronze / Cyan
      rankLabel = 'BRONZE #3';
      rankIcon = PhosphorIcons.medal;
    } else if (pr.rank > 0) {
      rankLabel = 'RANK #${pr.rank}';
      rankIcon = PhosphorIcons.medal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: retroColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.read<HapticsCubit>().lightImpact();
          if (pr.runId != null) {
            final runs = ref.read(historyProvider).valueOrNull ?? [];
            try {
              final run = runs.firstWhere((r) => r.clientRunId == pr.runId);
              AppNavigator.push(context,
                AppNavigator.materialPageRoute(builder: (_) => RunDetailScreen(run: run)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Run not found or not synced locally.')),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Rank Medal Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rankColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(rankIcon, color: rankColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),

              // Main Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (mode == 'best_effort') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rankLabel,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: rankColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          dateStr.toUpperCase(),
                          style: GoogleFonts.pixelifySans(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            color: retroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formattedValue,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: retroColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        if (paceStr.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: retroColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              paceStr,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: retroColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right Actions: Chevron or Delete
              if (mode == 'manual')
                IconButton(
                  icon: Icon(PhosphorIcons.trash, color: retroColors.error.withValues(alpha: 0.8), size: 18),
                  tooltip: 'Delete Record',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: retroColors.surface,
                        title: Text('Delete PR?', style: AppTextStyles.title(color: retroColors.textPrimary)),
                        content: Text('Remove this manual record from your all-time PRs?', style: AppTextStyles.bodyMedium(color: retroColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => AppNavigator.pop(ctx, false),
                            child: Text('Cancel', style: AppTextStyles.bodyMediumBold(color: retroColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => AppNavigator.pop(ctx, true),
                            child: Text('Delete', style: AppTextStyles.bodyMediumBold(color: retroColors.error)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await ref.read(prEngineProvider).deleteManualRecord(pr.id);
                        ref.invalidate(prsProvider);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to delete PR')),
                          );
                        }
                      }
                    }
                  },
                )
              else if (pr.runId != null)
                Icon(PhosphorIcons.caretRight, color: retroColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPRBottomSheet(BuildContext context, AppColors retroColors) {
    String selectedCategory = '5k';
    final minutesController = TextEditingController(text: '22');
    final secondsController = TextEditingController(text: '30');

    final categories = ['1k', '1 mile', '5k', '10k', 'half', 'marathon'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: retroColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: retroColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: retroColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LOG MANUAL RECORD',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: retroColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIcons.x, color: retroColors.textSecondary, size: 20),
                          onPressed: () => AppNavigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BENCHMARK DISTANCE',
                      style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isChosen = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isChosen ? retroColors.surface : retroColors.textPrimary,
                            ),
                          ),
                          selected: isChosen,
                          selectedColor: retroColors.accent,
                          backgroundColor: retroColors.surfaceRaised,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isChosen ? retroColors.accent : retroColors.border.withValues(alpha: 0.4),
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedCategory = cat;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ACHIEVED TIME',
                      style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minutesController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: retroColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'MINUTES',
                              labelStyle: AppTextStyles.labelCaps(color: retroColors.textSecondary),
                              filled: true,
                              fillColor: retroColors.surfaceRaised,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: retroColors.border.withValues(alpha: 0.4)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: retroColors.border.withValues(alpha: 0.4)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: secondsController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: retroColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'SECONDS',
                              labelStyle: AppTextStyles.labelCaps(color: retroColors.textSecondary),
                              filled: true,
                              fillColor: retroColors.surfaceRaised,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: retroColors.border.withValues(alpha: 0.4)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: retroColors.border.withValues(alpha: 0.4)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final mins = int.tryParse(minutesController.text) ?? 0;
                        final secs = int.tryParse(secondsController.text) ?? 0;
                        final totalSeconds = (mins * 60 + secs).toDouble();
                        if (totalSeconds > 0) {
                          try {
                            await ref.read(prEngineProvider).addManualRecord(
                              selectedCategory,
                              totalSeconds,
                              DateTime.now(),
                              null,
                            );
                            if (ctx.mounted) {
                              AppNavigator.pop(ctx);
                            }
                            ref.invalidate(prsProvider);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed to add PR: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: retroColors.accent,
                        foregroundColor: retroColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'SAVE BENCHMARK',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

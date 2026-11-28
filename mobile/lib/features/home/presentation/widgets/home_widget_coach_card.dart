import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trailhead_mobile/features/stats/application/ai_coach_service.dart';
import 'package:trailhead_mobile/features/chat/presentation/chat_screen_coach_conversation.dart';

class HomeCoachCard extends StatelessWidget {
  final AiCoachData coachData;
  final AppColors colors;

  const HomeCoachCard({required this.coachData, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hasFlag = coachData.fatigueFlag != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Tag + Load Status Pill + Chat Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'AI // ATHLETE COACH',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasFlag
                          ? colors.warning.withValues(alpha: 0.15)
                          : colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasFlag
                              ? PhosphorIcons.warningFill
                              : (coachData.isAiGenerated
                                    ? PhosphorIcons.sparkleFill
                                    : PhosphorIcons.robotFill),
                          size: 13,
                          color: hasFlag ? colors.warning : colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coachData.loadStatus,
                          style: AppTextStyles.labelCaps(
                            color: hasFlag ? colors.warning : colors.accent,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      AppNavigator.push(
                        context,
                        AppNavigator.materialPageRoute(
                          builder: (_) => const ChatScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.sparkleFill,
                        color: colors.accent,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Fatigue Warning Banner (if present)
          if (hasFlag) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIcons.warningCircle,
                    color: colors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coachData.fatigueFlag!,
                      style: AppTextStyles.bodyMedium(
                        color: colors.warning,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Coaching Feedback Body
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    coachData.coachingFeedback,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer info & chat link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    coachData.isAiGenerated
                        ? PhosphorIcons.sparkleFill
                        : PhosphorIcons.robotFill,
                    color: colors.accent,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    coachData.isAiGenerated
                        ? 'LLM ENHANCED'
                        : 'LOCAL INTELLIGENCE',
                    style: AppTextStyles.labelCaps(
                      color: colors.textSecondary,
                    ).copyWith(fontSize: 9),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  AppNavigator.push(
                    context,
                    AppNavigator.materialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Ask Coach',
                      style: AppTextStyles.labelCaps(
                        color: colors.accent,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIcons.arrowRight,
                      color: colors.accent,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

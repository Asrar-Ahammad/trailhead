import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../main.dart'; // import global isarInstance
import '../../run_tracking/data/models/run_isar.dart';
import '../../ai/application/ai_config_provider.dart';
import '../../ai/application/ai_client.dart';

class AiCoachData {
  final String coachingFeedback;
  final String? fatigueFlag;
  final String loadStatus;
  final bool isAiGenerated;

  AiCoachData({
    required this.coachingFeedback,
    this.fatigueFlag,
    this.loadStatus = "OPTIMAL",
    this.isAiGenerated = false,
  });
}

final aiCoachProvider = FutureProvider<AiCoachData>((ref) async {
  final aiConfig = ref.watch(aiConfigProvider);

  try {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final threeWeeksAgo = startOfWeek.subtract(const Duration(days: 21));

    // Fetch runs from the last 4 weeks to compute workload and fatigue
    final recentRuns = await isarInstance.runIsars
        .filter()
        .statusEqualTo('completed')
        .startTimeGreaterThan(threeWeeksAgo)
        .findAll();

    final thisWeekRuns = <RunIsar>[];
    final priorWeeksRuns = <RunIsar>[];

    for (final run in recentRuns) {
      if (run.startTime == null) continue;
      if (!run.startTime!.isBefore(startOfWeek)) {
        thisWeekRuns.add(run);
      } else {
        priorWeeksRuns.add(run);
      }
    }

    double thisWeekDistanceKm = 0.0;
    int thisWeekDurationS = 0;
    for (final run in thisWeekRuns) {
      thisWeekDistanceKm += (run.distanceM ?? 0) / 1000.0;
      thisWeekDurationS += run.durationS ?? 0;
    }

    double priorTotalDistanceKm = 0.0;
    for (final run in priorWeeksRuns) {
      priorTotalDistanceKm += (run.distanceM ?? 0) / 1000.0;
    }
    final priorWeeklyAvgKm = priorTotalDistanceKm / 3.0;

    // Check consecutive active days up to today
    int consecutiveActiveDays = 0;
    for (int i = 0; i < 7; i++) {
      final checkDay = now.subtract(Duration(days: i));
      final hasRunOnDay = recentRuns.any((r) {
        if (r.startTime == null) return false;
        return r.startTime!.year == checkDay.year &&
            r.startTime!.month == checkDay.month &&
            r.startTime!.day == checkDay.day;
      });
      if (hasRunOnDay) {
        consecutiveActiveDays++;
      } else if (i > 0) {
        break;
      }
    }

    // Fatigue & Load Status Evaluation (Local Analytics Engine)
    String? fatigueFlag;
    String loadStatus = "OPTIMAL";

    if (consecutiveActiveDays >= 5) {
      fatigueFlag = "5+ consecutive active days logged. Consider an active recovery or rest day to allow muscle fiber repair.";
      loadStatus = "RECOVERY NEEDED";
    } else if (priorWeeklyAvgKm > 8.0 && thisWeekDistanceKm > priorWeeklyAvgKm * 1.4) {
      final percentOver = ((thisWeekDistanceKm / priorWeeklyAvgKm - 1.0) * 100).toInt();
      fatigueFlag = "Weekly volume is $percentOver% above your 3-week baseline. Keep upcoming sessions at Zone 2 to prevent overuse injury.";
      loadStatus = "HIGH LOAD";
    } else if (thisWeekRuns.length >= 4) {
      loadStatus = "PEAK FLOW";
    } else if (thisWeekRuns.isNotEmpty) {
      loadStatus = "BUILDING";
    } else {
      loadStatus = "READY";
    }

    // Generate intelligent local heuristics feedback
    String localFeedback;
    if (thisWeekRuns.isEmpty) {
      localFeedback = "New week, fresh start! A steady 20-30 minute aerobic run is the perfect way to establish your rhythm and build momentum.";
    } else if (thisWeekRuns.length == 1) {
      localFeedback = "Strong opening workout (${thisWeekDistanceKm.toStringAsFixed(1)} km logged). Keep your next run at an easy conversational pace to build your aerobic base.";
    } else if (thisWeekRuns.length == 2) {
      localFeedback = "Great cadence! You've logged ${thisWeekDistanceKm.toStringAsFixed(1)} km across 2 runs this week. Prioritize hydration and post-run mobility.";
    } else if (consecutiveActiveDays >= 4) {
      localFeedback = "Impressive dedication! You've been active $consecutiveActiveDays days straight. Ensure you balance high volume with nutrient-dense recovery and quality sleep.";
    } else {
      localFeedback = "Phenomenal consistency! ${thisWeekRuns.length} runs and ${thisWeekDistanceKm.toStringAsFixed(1)} km logged this week. Consistency compounds into major endurance breakthroughs.";
    }

    // If external AI is configured, try enriching with LLM
    if (aiConfig.isConfigured) {
      try {
        final prompt = 'Analyze this runner\'s activity for the current week:\n'
            '- Runs logged: ${thisWeekRuns.length}\n'
            '- Current weekly distance: ${thisWeekDistanceKm.toStringAsFixed(1)} km\n'
            '- Total duration: ${(thisWeekDurationS / 60).round()} mins\n'
            '- 3-Week Baseline avg: ${priorWeeklyAvgKm.toStringAsFixed(1)} km/week\n'
            '- Load Status: $loadStatus\n'
            '${fatigueFlag != null ? "- Fatigue flag: $fatigueFlag\n" : ""}\n'
            'Provide 2-3 sentences of motivating, actionable coaching advice in a direct, retro-futuristic athletic coach tone.';

        final aiClient = AiClient(aiConfig);
        final response = await aiClient.chat([
          {'role': 'system', 'content': 'You are a supportive, high-performance running coach who gives concise, direct advice.'},
          {'role': 'user', 'content': prompt}
        ]);

        if (response != null && response.trim().isNotEmpty) {
          return AiCoachData(
            coachingFeedback: response.trim(),
            fatigueFlag: fatigueFlag,
            loadStatus: loadStatus,
            isAiGenerated: true,
          );
        }
      } catch (e) {
        // Fall back to local feedback if API fails
      }
    }

    return AiCoachData(
      coachingFeedback: localFeedback,
      fatigueFlag: fatigueFlag,
      loadStatus: loadStatus,
      isAiGenerated: false,
    );
  } catch (e) {
    return AiCoachData(
      coachingFeedback: "Log your completed workouts to receive personalized weekly coaching insights.",
      loadStatus: "STANDBY",
      isAiGenerated: false,
    );
  }
});

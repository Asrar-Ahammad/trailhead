import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/run_isar.dart';
import 'run_format_utils.dart';

/// Temporary mock service for generating AI summaries until the Next.js API
/// (Phase 9) is fully integrated.
final mockAiSummaryProvider = FutureProvider.family<String, RunIsar>((ref, run) async {
  // Simulate network delay for the OpenAI API call
  await Future.delayed(const Duration(seconds: 2));
  
  final distanceKm = run.distanceM != null ? run.distanceM! / 1000 : 0.0;
  final pace = run.distanceM != null && run.durationS != null && run.durationS! > 0
      ? RunFormatUtils.formatPace(run.distanceM!, run.durationS!)
      : '--:--';
  
  if (distanceKm > 10.0) {
    return 'Epic long run! You crushed ${distanceKm.toStringAsFixed(1)}km and maintained a solid $pace /km pace. '
        'Your endurance is really showing out there. Time to refuel and recover!';
  } else if (distanceKm > 5.0) {
    return 'Great mid-distance effort. Covering ${distanceKm.toStringAsFixed(1)}km at $pace /km '
        'shows excellent consistency. Keep stacking these miles and the speed will follow.';
  } else if (distanceKm > 0.0) {
    return 'Solid quick session today. You knocked out ${distanceKm.toStringAsFixed(1)}km at '
        '$pace /km. Sometimes the hardest part is just getting out the door — well done.';
  } else {
    return 'Looks like a short session or warmup. Every minute on your feet counts towards building that base!';
  }
});

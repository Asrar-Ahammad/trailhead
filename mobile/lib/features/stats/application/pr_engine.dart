import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';

final prEngineProvider = Provider((ref) {
  return PREngine(ref.read(runHistoryRepositoryProvider));
});

class PersonalRecord {
  final String title;
  final String value;
  final RunIsar run;

  PersonalRecord({required this.title, required this.value, required this.run});
}

class PREngine {
  final RunHistoryRepository _repository;

  PREngine(this._repository);

  Future<List<PersonalRecord>> calculatePRs() async {
    final runs = await _repository.getCompletedRuns(limit: 1000); // Fetch all for PR calculation
    
    if (runs.isEmpty) return [];

    List<PersonalRecord> prs = [];

    // 1. Longest Distance
    RunIsar? longestRun;
    for (var run in runs) {
      if (longestRun == null || (run.distanceM ?? 0) > (longestRun.distanceM ?? 0)) {
        longestRun = run;
      }
    }
    
    if (longestRun != null && (longestRun.distanceM ?? 0) > 0) {
      prs.add(PersonalRecord(
        title: 'Longest Run',
        value: '${((longestRun.distanceM ?? 0) / 1000).toStringAsFixed(2)} km',
        run: longestRun,
      ));
    }

    // 2. Fastest 5k (Simple estimation based on overall avg pace if run is >= 5k)
    // For a true sliding window over GPS points, we'd need to load RunPointIsar.
    // For now, if they ran at least 5k, their 5k time is 5 * avgPace.
    RunIsar? fastest5kRun;
    double best5kTimeS = double.infinity;

    for (var run in runs) {
      if ((run.distanceM ?? 0) >= 5000 && (run.avgPaceSPerKm ?? 0) > 0) {
        final estimated5kTime = (run.avgPaceSPerKm!) * 5;
        if (estimated5kTime < best5kTimeS) {
          best5kTimeS = estimated5kTime;
          fastest5kRun = run;
        }
      }
    }

    if (fastest5kRun != null) {
      final mins = (best5kTimeS / 60).floor();
      final secs = (best5kTimeS % 60).floor();
      prs.add(PersonalRecord(
        title: 'Fastest 5K',
        value: '${mins}:${secs.toString().padLeft(2, '0')}',
        run: fastest5kRun,
      ));
    }

    return prs;
  }
}

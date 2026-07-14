import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/daily_steps_isar.dart';
import '../../../main.dart'; // for isarInstance

/// Provides today's background step count as a real-time stream
final todayStepsProvider = StreamProvider.autoDispose<int>((ref) async* {
  final now = DateTime.now();
  final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final query = isarInstance.dailyStepsIsars
      .filter()
      .dateKeyEqualTo(todayKey)
      .build();

  await for (final results in query.watch(fireImmediately: true)) {
    if (results.isNotEmpty) {
      yield results.first.steps;
    } else {
      yield 0;
    }
  }
});

/// Provides the background step count for a specific date
final dailyStepsForDateProvider = FutureProvider.autoDispose.family<int, String>((ref, dateKey) async {
  final record = await isarInstance.dailyStepsIsars
      .filter()
      .dateKeyEqualTo(dateKey)
      .findFirst();
  return record?.steps ?? 0;
});

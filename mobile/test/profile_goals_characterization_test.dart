import 'dart:async';

import 'package:trailhead_mobile/features/goals/domain/goals_use_case_calculate_progress.dart';
import 'package:trailhead_mobile/features/goals/state_management/goals_bloc_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trailhead_mobile/features/goals/domain/goals_repository_targets.dart';
import 'package:trailhead_mobile/features/goals/state_management/goals_bloc_edit_targets.dart';
import 'package:trailhead_mobile/features/profile/data/profile_repository_implementation_settings.dart';
import 'package:trailhead_mobile/features/profile/domain/profile_repository_settings.dart';
import 'package:trailhead_mobile/features/profile/domain/profile_use_case_update_settings.dart';
import 'package:trailhead_mobile/features/profile/state_management/profile_bloc_settings.dart';

class FakeGoalProgressRepository implements GoalProgressRepository {
  final updates = StreamController<GoalProgressData>();

  @override
  Stream<GoalProgressData> watch(GoalMetrics metrics) => updates.stream;
}

void main() {
  test(
    'progress Bloc publishes a step-only change after the first snapshot',
    () async {
      final repository = FakeGoalProgressRepository();
      final bloc = GoalProgressBloc(repository, (
        daily: 'steps',
        monthly: 'distance',
      ));
      addTearDown(() async {
        await bloc.close();
        await repository.updates.close();
      });
      final snapshots = bloc.stream
          .where((state) => state.hasValue)
          .take(2)
          .toList();
      repository.updates
        ..add((dailyProgress: 1000, monthlyProgress: 8))
        ..add((dailyProgress: 1500, monthlyProgress: 8));

      expect(
        (await snapshots).map((state) => state.valueOrNull?.dailyProgress),
        [1000, 1500],
      );
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rest day edits enforce the monthly limit even when queued together',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_rest_days_update': 'invalid old date',
      });
      final repository = ProfileSettingsPreferences(
        await SharedPreferences.getInstance(),
      );
      final bloc = ProfileBloc(
        repository,
        UpdateProfileSettings(
          repository,
          clock: () => DateTime(2026, 5, 18),
          notifyCueFrequency: (_) {},
        ),
      );
      addTearDown(bloc.close);
      final rejected = bloc.stream.firstWhere((state) => state.message != null);
      bloc
        ..add(const EditProfileSetting(ProfileSetting.restDays, '4'))
        ..add(const EditProfileSetting(ProfileSetting.restDays, '5'));
      final state = await rejected;
      expect(state.message, contains('once per month'));
      expect(repository.read().restDays, 4);
      expect(repository.read().lastRestDaysUpdate, DateTime(2026, 5, 18));
    },
  );

  test(
    'invalid weights preserve the stored weight and cue updates notify tracking',
    () async {
      SharedPreferences.setMockInitialValues({'user_weight_kg': 70.5});
      final repository = ProfileSettingsPreferences(
        await SharedPreferences.getInstance(),
      );
      final cues = <double>[];
      final update = UpdateProfileSettings(
        repository,
        notifyCueFrequency: cues.add,
      );
      await expectLater(
        update(ProfileSetting.weight, 'Infinity'),
        throwsFormatException,
      );
      expect(repository.read().weight, 70.5);
      await update(ProfileSetting.cueFrequency, 0.5);
      expect(repository.read().cueFrequency, 0.5);
      expect(cues, [0.5]);
    },
  );

  test(
    'goal editor rejects invalid targets and retries without truncating decimals',
    () async {
      Goals? saved;
      var attempts = 0;
      final bloc = EditGoalsBloc((goals) async {
        if (++attempts == 1) throw StateError('Write failed');
        saved = goals;
      });
      addTearDown(bloc.close);
      final invalid = bloc.stream.firstWhere((state) => state.error != null);
      bloc.add((
        dailyMetric: 'distance',
        daily: 'NaN',
        monthlyMetric: 'distance',
        monthly: '50',
      ));
      expect((await invalid).error, contains('positive'));
      expect(attempts, 0);

      const valid = (
        dailyMetric: 'distance',
        daily: '3.5',
        monthlyMetric: 'distance',
        monthly: '50',
      );
      final failed = bloc.stream.firstWhere((state) => state.error != null);
      bloc.add(valid);
      expect((await failed).saved, isFalse);
      final succeeded = bloc.stream.firstWhere((state) => state.saved);
      bloc.add(valid);
      await succeeded;
      expect(saved?.dailyGoalTarget, 3.5);
      expect(attempts, 2);
    },
  );
}

import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trailhead_mobile/shared/state_management/global/ai_config_cubit.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';

import '../domain/predictions_entity_race_predictions.dart';
import '../domain/predictions_repository_race_predictions.dart';
import 'predictions_request_model_coach_advice.dart';
import 'predictions_service_coach_advice.dart';

class PredictionsRepositoryImplementation implements PredictionsRepository {
  const PredictionsRepositoryImplementation(
    this._isar,
    this._preferences,
    this._aiConfig,
    this._coachAdviceService,
  );

  final Isar _isar;
  final SharedPreferences _preferences;
  final AiConfigCubit _aiConfig;
  final PredictionsCoachAdviceService _coachAdviceService;

  @override
  Future<List<PredictionRun>> loadRecentRuns({required int limit}) async {
    final runs = await _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .sortByStartTimeDesc()
        .limit(limit)
        .findAll();
    return [
      for (final run in runs)
        (
          distanceMeters: run.distanceM ?? 0.0,
          durationSeconds: run.durationS ?? 0,
        ),
    ];
  }

  @override
  Future<String?> loadCoachAdvice(
    PredictionRun baseline,
    List<RaceEstimate> estimates,
  ) async {
    final config = _aiConfig.state;
    if (!config.isConfigured) return null;

    final birthDate = DateTime.tryParse(
      _preferences.getString('user_dob') ?? '',
    );
    final age = birthDate == null
        ? 'Unknown'
        : DateTime.now().year - birthDate.year;
    final gender = _preferences.getString('user_gender') ?? 'Unknown';
    final response = await _coachAdviceService.fetch(
      config,
      PredictionsCoachAdviceRequestModel(
        age: age.toString(),
        gender: gender,
        baseline: baseline,
        estimates: estimates,
      ),
    );
    return response.advice;
  }
}

import 'dart:math' as math;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../ai/application/ai_client.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';

class PredictionService {
  PredictionService({required Isar isar, required SharedPreferences preferences, required AiConfigCubit aiConfigCubit})
      : _isar = isar,
        _preferences = preferences,
        _aiConfigCubit = aiConfigCubit;

  final Isar _isar;
  final SharedPreferences _preferences;
  final AiConfigCubit _aiConfigCubit;
  static const _predictDistances = [
    {'name': '100m', 'd': 100.0},
    {'name': '200m', 'd': 200.0},
    {'name': '400m', 'd': 400.0},
    {'name': '5K', 'd': 5000.0},
    {'name': '10K', 'd': 10000.0},
    {'name': 'Half Marathon', 'd': 21097.5},
    {'name': 'Marathon', 'd': 42195.0},
  ];
  
  Future<Map<String, dynamic>> getPredictions() async {
    final runs = await _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .sortByStartTimeDesc()
        .limit(10)
        .findAll();

    if (runs.isEmpty) {
      throw Exception('Not enough data to predict. Go log some runs first!');
    }

    // Find best baseline run (using the longest run to bias endurance predictions)
    final baselineRun = runs.reduce((prev, current) => ((prev.distanceM ?? 0) > (current.distanceM ?? 0)) ? prev : current);
    final t1 = baselineRun.durationS ?? 0;
    final d1 = baselineRun.distanceM ?? 1.0;

    final predictions = _predictDistances.map((target) {
      final targetD = target['d'] as double;
      // Riegel Formula: T2 = T1 * (D2/D1)^1.06
      final t2 = t1 * math.pow((targetD / d1), 1.06);
      
      final totalSeconds = t2.round();
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      final s = totalSeconds % 60;
      
      var timeStr = '';
      if (h > 0) {
        timeStr = '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      } else {
        timeStr = '$m:${s.toString().padLeft(2, '0')}';
      }

      if (targetD <= 400) {
        timeStr = t2.toStringAsFixed(2) + 's';
      }

      return {
        'distance': target['name'],
        'timeStr': timeStr,
        'seconds': totalSeconds
      };
    }).toList();

    var aiReasoning = 'Keep training to achieve these times!';
    final aiConfig = _aiConfigCubit.state;
    if (aiConfig.isConfigured) {
      try {
        final age = _preferences.getString('user_dob') != null
            ? (DateTime.now().year - DateTime.parse(_preferences.getString('user_dob')!).year).toString()
            : 'Unknown';
        final gender = _preferences.getString('user_gender') ?? 'Unknown';

        final prompt = 'User Context: Age: $age, Gender: $gender. Baseline run used: $d1 meters in $t1 seconds.\n'
            'Predictions: ${predictions.map((p) => '${p['distance']}: ${p['timeStr']}').join(', ')}\n\n'
            'Provide exactly ONE short sentence of personalized reasoning or advice based on their baseline. Keep it under 25 words.';

        final aiClient = AiClient(aiConfig);
        final response = await aiClient.chat([
          {'role': 'system', 'content': 'You are an elite running coach. Be encouraging and concise.'},
          {'role': 'user', 'content': prompt}
        ]);
        if (response != null && response.trim().isNotEmpty) {
          aiReasoning = response.trim();
        }
      } catch (_) {}
    }

    return {
      'baseline': {
        'distanceM': d1,
        'durationS': t1,
      },
      'predictions': predictions,
      'aiReasoning': aiReasoning,
    };
  }
}

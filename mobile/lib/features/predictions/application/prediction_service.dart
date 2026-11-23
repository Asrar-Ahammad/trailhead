import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart'; // import global isarInstance
import '../../run_tracking/data/models/run_isar.dart';
import '../../ai/application/ai_config_provider.dart';
import '../../ai/application/ai_client.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService(ref);
});

final racePredictionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(predictionServiceProvider);
  return await service.getPredictions();
});

class PredictionService {
  final Ref _ref;

  static const _predictDistances = [
    {'name': '100m', 'd': 100.0},
    {'name': '200m', 'd': 200.0},
    {'name': '400m', 'd': 400.0},
    {'name': '5K', 'd': 5000.0},
    {'name': '10K', 'd': 10000.0},
    {'name': 'Half Marathon', 'd': 21097.5},
    {'name': 'Marathon', 'd': 42195.0},
  ];
  
  PredictionService(this._ref);

  Future<Map<String, dynamic>> getPredictions() async {
    final runs = await isarInstance.runIsars
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
    final aiConfig = _ref.read(aiConfigProvider);
    if (aiConfig.isConfigured) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final age = prefs.getString('user_dob') != null
            ? (DateTime.now().year - DateTime.parse(prefs.getString('user_dob')!).year).toString()
            : 'Unknown';
        final gender = prefs.getString('user_gender') ?? 'Unknown';

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

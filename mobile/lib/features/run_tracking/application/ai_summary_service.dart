import '../data/models/run_isar.dart';
import '../../ai/application/ai_client.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';

class AiSummaryService {
  AiSummaryService(this._aiConfigCubit);

  final AiConfigCubit _aiConfigCubit;

  Future<String> summarize(RunIsar run) async {
  final aiConfig = _aiConfigCubit.state;
  if (!aiConfig.isConfigured) {
    return 'Great effort out there! Keep stacking those miles.';
  }

  final aiClient = AiClient(aiConfig);
  try {
    final prompt = 'Summarize this run in one short, engaging sentence for a retro arcade running app:\n'
        'Distance: ${(run.distanceM ?? 0) / 1000} km\n'
        'Duration: ${(run.durationS ?? 0) / 60} mins\n'
        'Avg Pace: ${run.avgPaceSPerKm ?? 0} s/km\n'
        'Calories: ${run.caloriesKcal ?? 0} kcal';

    final systemPrompt = 'You are an encouraging running assistant. Keep summaries under 15 words, exciting and motivational.';

    final reply = await aiClient.chat([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt}
    ]);

    if (reply != null && reply.trim().isNotEmpty) {
      return reply.trim();
    }
  } catch (e) {
    print('Failed to fetch local AI summary: $e');
  }

  return 'Great effort out there! Keep stacking those miles.';
  }
}

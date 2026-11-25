import 'dart:convert';
import '../../history/domain/entities/parsed_run_log.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';
import '../../ai/application/ai_client.dart';

class NlLoggingService {
  NlLoggingService(this._aiConfigCubit);

  final AiConfigCubit _aiConfigCubit;

  Future<ParsedRunLog?> parseLog(String text) async {
    final aiConfig = _aiConfigCubit.state;
    if (!aiConfig.isConfigured) return null;

    final aiClient = AiClient(aiConfig);
    try {
      final prompt = 'Parse this run description into a clean JSON structure. Only return the raw JSON object, no markdown code blocks.\n'
          'Description: "$text"\n\n'
          'JSON Schema:\n'
          '{\n'
          '  "distanceKm": float or null,\n'
          '  "subjectiveEffort": "easy" | "moderate" | "hard" or null,\n'
          '  "conditions": string describing weather/terrain or null,\n'
          '  "timeOfDay": "morning" | "afternoon" | "evening" | "night" or null\n'
          '}';

      final response = await aiClient.chat([
        {'role': 'system', 'content': 'You are a parsing engine. You output ONLY valid JSON.'},
        {'role': 'user', 'content': prompt}
      ]);

      if (response != null && response.isNotEmpty) {
        // Clean JSON formatting if LLM wrapped in markdown blocks
        var cleaned = response.trim();
        if (cleaned.startsWith('```json')) {
          cleaned = cleaned.substring(7);
        }
        if (cleaned.startsWith('```')) {
          cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
        cleaned = cleaned.trim();

        final Map<String, dynamic> decoded = jsonDecode(cleaned);
        return ParsedRunLog.fromJson(decoded);
      }
    } catch (e) {
      print('Local NL parse error: $e');
    }
    return null;
  }
}

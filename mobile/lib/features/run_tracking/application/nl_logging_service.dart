import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/application/ai_config_provider.dart';
import '../../ai/application/ai_client.dart';

class ParsedRunLog {
  final double? distanceKm;
  final String? subjectiveEffort;
  final String? conditions;
  final String? timeOfDay;

  ParsedRunLog({
    this.distanceKm,
    this.subjectiveEffort,
    this.conditions,
    this.timeOfDay,
  });

  factory ParsedRunLog.fromJson(Map<String, dynamic> json) {
    return ParsedRunLog(
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      subjectiveEffort: json['subjectiveEffort'] as String?,
      conditions: json['conditions'] as String?,
      timeOfDay: json['timeOfDay'] as String?,
    );
  }
}

final nlLoggingProvider = Provider((ref) => NlLoggingService(ref));

class NlLoggingService {
  final Ref _ref;
  NlLoggingService(this._ref);

  Future<ParsedRunLog?> parseLog(String text) async {
    final aiConfig = _ref.read(aiConfigProvider);
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

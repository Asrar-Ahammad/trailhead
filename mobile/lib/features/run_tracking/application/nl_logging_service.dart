import '../../sync/data/api_client.dart';

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

class NlLoggingService {
  final ApiClient _apiClient;
  NlLoggingService(this._apiClient);

  Future<ParsedRunLog?> parseLog(String text) async {
    final apiClient = _apiClient;
    try {
      final response = await apiClient.client.post(
        '/runs/parse-log',
        data: {'text': text},
      );
      if (response.statusCode == 200 && response.data != null) {
        return ParsedRunLog.fromJson(response.data);
      }
    } catch (e) {
      print('NL parse error: $e');
    }
    return null;
  }
}

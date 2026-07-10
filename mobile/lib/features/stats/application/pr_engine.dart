import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';

final prEngineProvider = Provider((ref) {
  return PREngine(ref.read(apiClientProvider));
});

class PersonalRecord {
  final String id;
  final String category;
  final double value;
  final DateTime achievedAt;
  final int rank;
  final String source;
  final String? runId;
  final String? proofUrl;

  PersonalRecord({
    required this.id,
    required this.category,
    required this.value,
    required this.achievedAt,
    required this.rank,
    required this.source,
    this.runId,
    this.proofUrl,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'],
      category: json['category'],
      value: (json['value'] as num).toDouble(),
      achievedAt: DateTime.parse(json['achievedAt']),
      rank: json['rank'],
      source: json['source'],
      runId: json['runId'],
      proofUrl: json['proofUrl'],
    );
  }
}

class RecordGroup {
  final List<PersonalRecord> bestEffort;
  final List<PersonalRecord> manual;

  RecordGroup({required this.bestEffort, required this.manual});
}

class PREngine {
  final ApiClient _apiClient;

  PREngine(this._apiClient);

  Future<RecordGroup> getRecords() async {
    final response = await _apiClient.client.get('/records');
    
    final bestEffortRaw = response.data['best_effort'] as List? ?? [];
    final manualRaw = response.data['manual'] as List? ?? [];

    return RecordGroup(
      bestEffort: bestEffortRaw.map((e) => PersonalRecord.fromJson(e)).toList(),
      manual: manualRaw.map((e) => PersonalRecord.fromJson(e)).toList(),
    );
  }

  Future<PersonalRecord> addManualRecord(String category, double value, DateTime date, String? proofUrl) async {
    final response = await _apiClient.client.post('/records/manual', data: {
      'category': category,
      'value': value,
      'achievedAt': date.toIso8601String(),
      'proofUrl': proofUrl,
    });
    return PersonalRecord.fromJson(response.data);
  }

  Future<void> deleteManualRecord(String id) async {
    await _apiClient.client.delete('/records/manual/$id');
  }
}

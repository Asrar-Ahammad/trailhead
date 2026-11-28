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
}

class RecordGroup {
  final List<PersonalRecord> bestEffort;
  final List<PersonalRecord> manual;

  RecordGroup({required this.bestEffort, required this.manual});
}

abstract interface class PersonalRecordsRepository {
  Stream<RecordGroup> watchRecords();
  Future<bool> hasBestEffortForRun(String id);
  Future<PersonalRecord> addManualRecord(
    String category,
    double value,
    DateTime date,
    String? proofUrl,
  );
  Future<void> deleteManualRecord(String id);
}

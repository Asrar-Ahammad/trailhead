import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../main.dart'; // import global isarInstance
import '../data/models/personal_record_isar.dart';

final prEngineProvider = Provider((ref) {
  return PREngine(isarInstance);
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

  factory PersonalRecord.fromIsar(PersonalRecordIsar isar) {
    return PersonalRecord(
      id: isar.id.toString(),
      category: isar.category ?? '',
      value: isar.value ?? 0.0,
      achievedAt: isar.achievedAt ?? DateTime.now(),
      rank: isar.rank ?? 1,
      source: isar.source ?? 'manual',
      runId: isar.runId,
      proofUrl: isar.proofUrl,
    );
  }
}

class RecordGroup {
  final List<PersonalRecord> bestEffort;
  final List<PersonalRecord> manual;

  RecordGroup({required this.bestEffort, required this.manual});
}

class PREngine {
  final Isar _isar;

  PREngine(this._isar);

  Future<RecordGroup> getRecords() async {
    final allRecords = await _isar.personalRecordIsars.where().findAll();
    
    final bestEffort = allRecords
        .where((r) => r.source == 'best_effort')
        .map((r) => PersonalRecord.fromIsar(r))
        .toList();
        
    final manual = allRecords
        .where((r) => r.source == 'manual')
        .map((r) => PersonalRecord.fromIsar(r))
        .toList();

    return RecordGroup(bestEffort: bestEffort, manual: manual);
  }

  Future<PersonalRecord> addManualRecord(String category, double value, DateTime date, String? proofUrl) async {
    final pr = PersonalRecordIsar()
      ..category = category
      ..value = value
      ..achievedAt = date
      ..source = 'manual'
      ..rank = 1
      ..proofUrl = proofUrl;

    await _isar.writeTxn(() async {
      await _isar.personalRecordIsars.put(pr);
    });

    return PersonalRecord.fromIsar(pr);
  }

  Future<void> deleteManualRecord(String id) async {
    final idInt = int.tryParse(id);
    if (idInt != null) {
      await _isar.writeTxn(() async {
        await _isar.personalRecordIsars.delete(idInt);
      });
    }
  }
}

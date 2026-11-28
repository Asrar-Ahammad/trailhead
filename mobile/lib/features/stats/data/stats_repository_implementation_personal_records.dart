import 'package:isar/isar.dart';
import '../domain/stats_repository_personal_records.dart';
import 'models/personal_record_isar.dart';

class PersonalRecordsIsar implements PersonalRecordsRepository {
  final Isar _isar;

  PersonalRecordsIsar(this._isar);

  PersonalRecord _toDomain(PersonalRecordIsar isar) {
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

  @override
  Future<bool> hasBestEffortForRun(String id) => _isar.personalRecordIsars
      .filter()
      .runIdEqualTo(id)
      .sourceEqualTo('best_effort')
      .isNotEmpty();

  @override
  Stream<RecordGroup> watchRecords() => _isar.personalRecordIsars
      .where()
      .watch(fireImmediately: true)
      .map(_group);

  RecordGroup _group(List<PersonalRecordIsar> allRecords) {
    final bestEffort = allRecords
        .where((r) => r.source == 'best_effort')
        .map((r) => _toDomain(r))
        .toList();

    final manual = allRecords
        .where((r) => r.source == 'manual')
        .map((r) => _toDomain(r))
        .toList();

    return RecordGroup(bestEffort: bestEffort, manual: manual);
  }

  @override
  Future<PersonalRecord> addManualRecord(
    String category,
    double value,
    DateTime date,
    String? proofUrl,
  ) async {
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

    return _toDomain(pr);
  }

  @override
  Future<void> deleteManualRecord(String id) async {
    final idInt = int.tryParse(id);
    if (idInt != null) {
      await _isar.writeTxn(() async {
        final record = await _isar.personalRecordIsars.get(idInt);
        if (record?.source == 'manual')
          await _isar.personalRecordIsars.delete(idInt);
      });
    }
  }
}

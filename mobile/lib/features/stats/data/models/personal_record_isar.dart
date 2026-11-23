import 'package:isar/isar.dart';

part 'personal_record_isar.g.dart';

@collection
class PersonalRecordIsar {
  Id id = Isar.autoIncrement;

  String? category; // "100m","1k","5k","10k","half","marathon","longest_run","longest_duration","max_elevation"
  String? runId; // clientRunId
  double? value;
  DateTime? achievedAt;
  int? rank; // 1, 2, or 3
  String? source; // "best_effort" or "manual"
  String? proofUrl;
}

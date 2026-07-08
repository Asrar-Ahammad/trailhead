import 'package:isar/isar.dart';

part 'run_point_isar.g.dart';

@collection
class RunPointIsar {
  Id id = Isar.autoIncrement;

  @Index()
  String? clientRunId; // links to RunIsar.clientRunId

  double? lat;
  double? lng;
  double? elevation;
  DateTime? timestamp;
  double? accuracy;
  double? speed;
  bool isPaused = false;
  int sequence = 0; // order within run
}

import 'package:isar/isar.dart';

part 'run_isar.g.dart';

@collection
class RunIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? clientRunId; // UUID generated on client side

  String? title;
  
  @Index()
  DateTime? startTime;
  
  DateTime? endTime;
  
  double? distanceM;
  
  int? durationS;
  
  double? avgPaceSPerKm;
  
  double? elevationGainM;
  
  int? stepCount;
  
  double? avgStrideLengthM;
  
  double? avgCadenceSpm;
  
  double? caloriesKcal;
  
  String? status; // 'running', 'paused', 'completed'
  
  String? aiSummary;
  
  bool synced = false;
  
  DateTime? lastModifiedAt;
  
  DateTime? syncedAt;
}

class ManualRun {
  const ManualRun({
    required this.clientRunId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.subjectiveEffort,
    required this.conditions,
  });

  final String clientRunId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final String? subjectiveEffort;
  final String? conditions;
}

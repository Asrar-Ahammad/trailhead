class ParsedRunLog {
  const ParsedRunLog({
    this.distanceKm,
    this.subjectiveEffort,
    this.conditions,
    this.timeOfDay,
  });

  final double? distanceKm;
  final String? subjectiveEffort;
  final String? conditions;
  final String? timeOfDay;

  factory ParsedRunLog.fromJson(Map<String, dynamic> json) {
    return ParsedRunLog(
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      subjectiveEffort: json['subjectiveEffort'] as String?,
      conditions: json['conditions'] as String?,
      timeOfDay: json['timeOfDay'] as String?,
    );
  }
}

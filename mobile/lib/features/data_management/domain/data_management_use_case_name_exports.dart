String backupFileName(DateTime date) {
  final day = date.toIso8601String().split('T').first;
  return 'trailhead_backup_${day}_${_twoDigits(date.hour)}${_twoDigits(date.minute)}.json';
}

String routeExportFileName({
  required DateTime? startTime,
  required double? distanceMeters,
  required String? title,
}) {
  final date = startTime == null
      ? 'unknown_date'
      : '${startTime.year}${_twoDigits(startTime.month)}${_twoDigits(startTime.day)}';
  final distanceKm = ((distanceMeters ?? 0) / 1000).toStringAsFixed(1);
  final safeTitle = (title ?? 'run').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return 'trailhead_${safeTitle}_${distanceKm}km_$date.gpx';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

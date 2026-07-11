/// Pure formatting utilities for run tracking display values.
/// No widget dependencies — these are plain Dart functions,
/// keeping build() methods strictly presentational.
abstract final class RunFormatUtils {
  /// Formats [totalSeconds] as MM:SS or H:MM:SS.
  static String formatDuration(int totalSeconds) {
    final int hours   = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns current pace as "MM:SS" per km, or "-:--" if insufficient data.
  static String formatPace(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '-:--';
    final double distanceKm = distanceM / 1000.0;
    final double paceS      = durationS / distanceKm;
    final int paceMin  = (paceS / 60).floor();
    final int paceSec  = (paceS % 60).round();
    return '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}';
  }

  /// Formats [distanceM] as a km string with 2 decimal places.
  static String formatDistanceKm(double distanceM) {
    return (distanceM / 1000.0).toStringAsFixed(2);
  }

  /// Formats [calories] as a rounded integer string, or "--" if null/zero.
  static String formatCalories(double? calories) {
    if (calories == null || calories <= 0) return '--';
    return calories.round().toString();
  }

  /// Returns the run title, or a context-based default (e.g. "Morning 5K", "Evening Easy Run") if null.
  static String getRunTitle(
    String? title, 
    DateTime? startTime, {
    String activityType = 'run',
    double? distanceM,
    String? subjectiveEffort,
    String? conditions,
  }) {
    if (title != null && title.trim().isNotEmpty && title != "Manual Run" && title != "Untitled Run") {
      return title;
    }
    
    // Time of day
    final start = startTime?.toLocal() ?? DateTime.now();
    final hour = start.hour;
    String timeOfDayStr;
    if (hour >= 5 && hour < 12) {
      timeOfDayStr = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDayStr = 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDayStr = 'Evening';
    } else {
      timeOfDayStr = 'Night';
    }

    // Distance
    String? distanceStr;
    if (distanceM != null && distanceM > 0) {
      final km = distanceM / 1000;
      if (km >= 4.8 && km <= 5.2) distanceStr = '5K';
      else if (km >= 9.8 && km <= 10.2) distanceStr = '10K';
      else if (km >= 20.8 && km <= 21.3) distanceStr = 'Half Marathon';
      else if (km >= 41.8 && km <= 42.4) distanceStr = 'Marathon';
      else if (km >= 1.0) distanceStr = '${km.round()}k';
    }

    // Effort
    String effortStr = '';
    if (subjectiveEffort != null && subjectiveEffort.trim().isNotEmpty) {
      // capitalize first letter
      final eff = subjectiveEffort.trim();
      effortStr = ' ${eff[0].toUpperCase()}${eff.substring(1)}';
    }
    
    // Location Type / Conditions (e.g. Trail, Treadmill)
    String locationStr = '';
    if (conditions != null && conditions.trim().isNotEmpty) {
       final lowerCond = conditions.toLowerCase();
       if (lowerCond.contains('trail')) locationStr = ' Trail';
       else if (lowerCond.contains('treadmill') || lowerCond.contains('indoor')) locationStr = ' Treadmill';
       else if (lowerCond.contains('track')) locationStr = ' Track';
    }

    // Activity type
    String activityName = activityType.toLowerCase() == 'walk' ? 'Walk' : 'Run';
    if (distanceStr == 'Half Marathon' || distanceStr == 'Marathon') {
       activityName = ''; // e.g. "Morning Marathon" instead of "Morning Marathon Run"
    }

    if (distanceStr != null && distanceStr.contains('Marathon')) {
       return '$timeOfDayStr$effortStr$locationStr $distanceStr'.trim();
    } else if (distanceStr != null) {
       return '$timeOfDayStr$effortStr$locationStr $distanceStr $activityName'.trim();
    } else {
       return '$timeOfDayStr$effortStr$locationStr $activityName'.trim();
    }
  }
}

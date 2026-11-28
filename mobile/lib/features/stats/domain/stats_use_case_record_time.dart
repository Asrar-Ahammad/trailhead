double parseRecordTime(String minutes, String seconds) {
  final minuteValue = int.tryParse(minutes.trim());
  final secondValue = int.tryParse(seconds.trim());
  if (minuteValue == null ||
      minuteValue < 0 ||
      secondValue == null ||
      secondValue < 0 ||
      secondValue >= 60 ||
      (minuteValue == 0 && secondValue == 0)) {
    throw const FormatException(
      'Enter a positive time with seconds from 0 to 59.',
    );
  }
  return (minuteValue * 60 + secondValue).toDouble();
}

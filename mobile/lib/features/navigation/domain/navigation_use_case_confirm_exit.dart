class ConfirmAppExit {
  DateTime? _lastPress;

  bool call(DateTime now) {
    final previous = _lastPress;
    final elapsed = previous == null ? null : now.difference(previous);
    if (elapsed != null &&
        !elapsed.isNegative &&
        elapsed <= const Duration(seconds: 2)) {
      _lastPress = null;
      return true;
    }
    _lastPress = now;
    return false;
  }
}

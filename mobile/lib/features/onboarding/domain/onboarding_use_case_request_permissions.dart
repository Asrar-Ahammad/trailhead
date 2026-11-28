class RequestOnboardingPermissions {
  const RequestOnboardingPermissions({
    required this.foreground,
    required this.background,
  });
  final Future<bool> Function() foreground;
  final Future<bool> Function() background;

  Future<bool> call() async {
    if (!await foreground()) return false;
    return background();
  }
}

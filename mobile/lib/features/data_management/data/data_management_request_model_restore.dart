class RestoreBackupRequestModel {
  const RestoreBackupRequestModel({
    required this.path,
    required this.overwrite,
  });

  final String path;
  final bool overwrite;
}

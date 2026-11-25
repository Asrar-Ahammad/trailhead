import '../domain/data_management_repository_backups.dart';
import 'data_management_request_model_restore.dart';
import 'data_management_service_export.dart';
import 'data_management_service_restore.dart';

class DataManagementRepositoryImplementation
    implements DataManagementRepository {
  const DataManagementRepositoryImplementation(this._export, this._restore);

  final DataExportService _export;
  final DataImportService _restore;

  @override
  Future<BackupFile> exportBackup(BackupDestination destination) async {
    final file = switch (destination) {
      BackupDestination.downloads => await _export.saveBackupToDownloads(),
      BackupDestination.share => await _export.exportData(),
    };
    return (path: file.path, name: file.uri.pathSegments.last);
  }

  @override
  Future<int> exportRoutes() => _export.exportAllRunsGpxToDownloads();

  @override
  Future<RestoredBackup> restoreBackup(
    String path,
    BackupRestoreMode mode,
  ) async {
    final result = await _restore.restore(
      RestoreBackupRequestModel(
        path: path,
        overwrite: mode == BackupRestoreMode.overwrite,
      ),
    );
    return (runs: result.runs, shoes: result.shoes);
  }
}

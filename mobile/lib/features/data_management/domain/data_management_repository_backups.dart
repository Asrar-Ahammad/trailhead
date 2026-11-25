enum BackupDestination { downloads, share }

enum BackupRestoreMode { merge, overwrite }

typedef BackupFile = ({String path, String name});
typedef RestoredBackup = ({int runs, int shoes});

abstract interface class DataManagementRepository {
  Future<BackupFile> exportBackup(BackupDestination destination);
  Future<int> exportRoutes();
  Future<RestoredBackup> restoreBackup(String path, BackupRestoreMode mode);
}

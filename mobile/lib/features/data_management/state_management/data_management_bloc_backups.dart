import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/data_management_repository_backups.dart';

typedef CreateDataManagementBloc = DataManagementBloc Function();

sealed class DataManagementEvent {
  const DataManagementEvent();
}

final class ExportBackup extends DataManagementEvent {
  const ExportBackup(this.destination);

  final BackupDestination destination;
}

final class ExportRoutes extends DataManagementEvent {
  const ExportRoutes();
}

final class RestoreBackup extends DataManagementEvent {
  const RestoreBackup(this.path, this.mode);

  final String path;
  final BackupRestoreMode mode;
}

sealed class DataManagementState {
  const DataManagementState();
}

final class DataManagementIdle extends DataManagementState {
  const DataManagementIdle();
}

final class DataManagementBusy extends DataManagementState {
  const DataManagementBusy();
}

final class BackupExported extends DataManagementState {
  const BackupExported(this.file, this.destination);

  final BackupFile file;
  final BackupDestination destination;
}

final class RoutesExported extends DataManagementState {
  const RoutesExported(this.count);

  final int count;
}

final class BackupRestored extends DataManagementState {
  const BackupRestored(this.backup);

  final RestoredBackup backup;
}

final class DataManagementFailed extends DataManagementState {
  const DataManagementFailed(this.message);

  final String message;
}

class DataManagementBloc
    extends Bloc<DataManagementEvent, DataManagementState> {
  DataManagementBloc(
    this._repository, {
    required void Function() onPreferencesRestored,
  }) : _onPreferencesRestored = onPreferencesRestored,
       super(const DataManagementIdle()) {
    on<DataManagementEvent>(_runOperation);
  }

  final DataManagementRepository _repository;
  final void Function() _onPreferencesRestored;

  Future<void> _runOperation(
    DataManagementEvent event,
    Emitter<DataManagementState> emit,
  ) async {
    if (state is DataManagementBusy) return;
    emit(const DataManagementBusy());

    try {
      final result = switch (event) {
        ExportBackup(:final destination) => BackupExported(
          await _repository.exportBackup(destination),
          destination,
        ),
        ExportRoutes() => RoutesExported(await _repository.exportRoutes()),
        RestoreBackup(:final path, :final mode) => BackupRestored(
          await _repository.restoreBackup(path, mode),
        ),
      };
      // The restore can finish after Settings and its listener are disposed.
      if (result is BackupRestored) _onPreferencesRestored();
      emit(result);
    } catch (error) {
      emit(DataManagementFailed(error.toString()));
    }
  }
}

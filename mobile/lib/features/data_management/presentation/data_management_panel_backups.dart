import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/navigation/app_navigator.dart';
import '../../../shared/state_management/global/haptics_cubit_feedback.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/data_management_repository_backups.dart';
import '../state_management/data_management_bloc_backups.dart';

class DataManagementPanel extends StatelessWidget {
  const DataManagementPanel({
    super.key,
    required this.onRestored,
    required this.onExportComplete,
  });

  final VoidCallback onRestored;
  final VoidCallback onExportComplete;

  @override
  Widget build(BuildContext context) {
    final createBloc = context.read<CreateDataManagementBloc>();
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocProvider(
      create: (_) => createBloc(),
      child: BlocConsumer<DataManagementBloc, DataManagementState>(
        listener: _showResult,
        builder: (context, state) {
          final busy = state is DataManagementBusy;
          final divider = Divider(
            color: colors.border.withValues(alpha: 0.5),
            height: 1,
            indent: 16,
            endIndent: 16,
          );
          return Column(
            children: [
              if (busy) const LinearProgressIndicator(),
              _tile(
                colors,
                'Save Backup to Downloads',
                'Save a JSON backup to the Downloads folder.',
                PhosphorIcons.download,
                busy
                    ? null
                    : () => _startExport(
                        context,
                        const ExportBackup(BackupDestination.downloads),
                      ),
              ),
              divider,
              _tile(
                colors,
                'Export All Routes (GPX) to Downloads',
                'Save GPS runs as GPX files in Trailhead_GPX.',
                PhosphorIcons.path,
                busy ? null : () => _startExport(context, const ExportRoutes()),
              ),
              divider,
              _tile(
                colors,
                'Share Backup File',
                'Share a JSON backup file.',
                PhosphorIcons.shareNetwork,
                busy
                    ? null
                    : () => context.read<DataManagementBloc>().add(
                        const ExportBackup(BackupDestination.share),
                      ),
              ),
              divider,
              _tile(
                colors,
                'Import Local Data',
                'Restore local data from a JSON backup.',
                PhosphorIcons.upload,
                busy ? null : () => _chooseBackup(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    AppColors colors,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium(color: colors.textSecondary),
      ),
      trailing: Icon(icon, color: colors.textSecondary, size: 22),
      enabled: onTap != null,
      onTap: onTap,
    );
  }

  void _startExport(BuildContext context, DataManagementEvent event) {
    context.read<HapticsCubit>().lightImpact();
    context.read<DataManagementBloc>().add(event);
  }

  Future<void> _chooseBackup(BuildContext context) async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = selection?.files.single.path;
      if (path == null || !context.mounted) return;

      final mode = await showDialog<BackupRestoreMode>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import Option'),
          content: const Text(
            'Merge the backup or overwrite the data it covers?',
          ),
          actions: [
            TextButton(
              onPressed: () => AppNavigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  AppNavigator.pop(dialogContext, BackupRestoreMode.merge),
              child: const Text('Merge'),
            ),
            TextButton(
              onPressed: () =>
                  AppNavigator.pop(dialogContext, BackupRestoreMode.overwrite),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      if (mode == null || !context.mounted) return;
      context.read<DataManagementBloc>().add(RestoreBackup(path, mode));
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not open backup: $error');
      }
    }
  }

  Future<void> _showResult(
    BuildContext context,
    DataManagementState state,
  ) async {
    switch (state) {
      case BackupExported(:final file, :final destination):
        if (destination == BackupDestination.share) {
          await _share(context, file.path);
          return;
        }
        onExportComplete();
        _showMessage(
          context,
          'Saved backup: ${file.name}',
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _share(context, file.path),
          ),
        );
      case RoutesExported(:final count):
        onExportComplete();
        _showMessage(
          context,
          count == 0
              ? 'No completed GPS runs found.'
              : 'Exported $count GPX routes.',
        );
      case BackupRestored(:final backup):
        onRestored();
        _showMessage(
          context,
          'Imported ${backup.runs} runs and ${backup.shoes} shoes.',
        );
      case DataManagementFailed(:final message):
        _showMessage(context, 'Data operation failed: $message');
      case DataManagementIdle() || DataManagementBusy():
        break;
    }
  }

  Future<void> _share(BuildContext context, String path) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Trailhead Data Export'),
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not share backup: $error');
      }
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
  }
}

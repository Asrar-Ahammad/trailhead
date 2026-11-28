import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../application/gpx_export_util.dart';

class RunGpxExportService {
  Future<File> export(RunIsar run, List<RunPointIsar> points) async {
    if (run.clientRunId == null) {
      throw const FormatException('Cannot export run without a valid ID.');
    }
    final valid = points
        .where((point) => point.lat != null && point.lng != null)
        .toList();
    if (valid.isEmpty)
      throw const FormatException(
        'No GPS route points found for this activity.',
      );
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted && !status.isPermanentlyDenied)
        await Permission.storage.request();
    }
    return GpxExportUtil.saveRunGpxToDownloads(run, valid);
  }
}

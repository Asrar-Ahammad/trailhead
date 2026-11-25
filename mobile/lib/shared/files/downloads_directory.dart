import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> resolveDownloadsDirectory() async {
  if (!Platform.isAndroid) {
    return await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  }

  final publicDownloads = Directory('/storage/emulated/0/Download');
  if (await publicDownloads.exists()) return publicDownloads;

  try {
    final directories = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (directories != null && directories.isNotEmpty) return directories.first;
  } catch (_) {
    // Some devices do not expose an app-specific Downloads directory.
  }
  return await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
}

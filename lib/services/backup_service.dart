import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';

class BackupService {
  final DatabaseController dbController = Get.find<DatabaseController>();

  Future<void> createBackup() async {
    try {
      // 1. Get DB Directory from the active store
      final dbPath = dbController.objectBox.store.directoryPath;
      debugPrint('Backup Debug: Store directory path: $dbPath');

      final dbFile = File(p.join(dbPath, 'data.mdb'));

      if (!await dbFile.exists()) {
        Get.snackbar('Error', 'Database file not found at $dbPath');
        return;
      }

      // 2. Create Temp Copy with new name
      final tempDir = await getTemporaryDirectory();
      final backupFileName = 'store_backup_${DateTime.now().toIso8601String().split('T')[0]}.mdb';
      final backupPath = p.join(tempDir.path, backupFileName);

      debugPrint('Backup Debug: Copying DB to $backupPath');

      // Copying the file is sufficient (and safer than zipping seemingly)
      await dbFile.copy(backupPath);
      final backupFile = File(backupPath);

      final fileSize = await backupFile.length();
      debugPrint('Backup Debug: Backup file created. Size: $fileSize bytes');

      // 3. Share
      await Share.shareXFiles([XFile(backupPath)], text: 'Store Management Backup');
    } catch (e) {
      Get.snackbar('Error', 'Backup failed: $e');
      debugPrint('Backup Error: $e');
    }
  }

  Future<void> restoreBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mdb', 'zip'],
    );

    if (result == null) return;

    File pickedFile = File(result.files.single.path!);
    String extension = p.extension(pickedFile.path).toLowerCase();

    // 2. Confirm Update
    bool? confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('Restore Backup'),
      content: const Text('This will overwrite your current data. Are you sure? App will restart.'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('Restore', style: TextStyle(color: Colors.red))),
      ],
    ));

    if (confirm != true) return;

    try {
      // 3. Capture current DB path BEFORE closing
      final dbPath = dbController.objectBox.store.directoryPath;

      // 4. Close DB
      dbController.objectBox.store.close();

      // 5. Restore
      if (extension == '.zip') {
        final bytes = await pickedFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile && filename.endsWith('data.mdb')) {
            final data = file.content as List<int>;
            File(p.join(dbPath, 'data.mdb'))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
      } else {
        // Assume .mdb file
        debugPrint('Restore Debug: Copying mdb file to $dbPath/data.mdb');
        await pickedFile.copy(p.join(dbPath, 'data.mdb'));
      }

      // 6. Restart Helper
      await Get.defaultDialog(
        title: 'Success',
        middleText: 'Backup restored successfully. Please restart the app.',
        barrierDismissible: false,
        confirm: ElevatedButton(onPressed: () => exit(0), child: const Text('Exit App')),
      );
    } catch (e) {
      Get.snackbar('Error', 'Restore failed: $e');
      debugPrint('Restore Error: $e');
    }
  }
}

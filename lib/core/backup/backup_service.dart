import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class BackupService {
  static Future<File> _dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tamirino.sqlite');
  }

  static Future<void> exportBackup() async {
    final dbFile = await _dbFile();
    if (!await dbFile.exists()) throw Exception('فایل دیتابیس یافت نشد');
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final backupPath = '${tempDir.path}/tamirino_backup_$dateStr.sqlite';
    await dbFile.copy(backupPath);
    await Share.shareXFiles([XFile(backupPath)], text: 'فایل پشتیبان تعمیرینو');
  }

  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return false;
    final pickedFile = File(result.files.single.path!);
    final dbFile = await _dbFile();
    await pickedFile.copy(dbFile.path);
    return true;
  }
}

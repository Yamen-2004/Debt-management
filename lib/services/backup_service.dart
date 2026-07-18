import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_model.dart';

/// Handles local JSON backup export and retention.
/// Contains no UI code — only file/storage logic.
///
/// On Android 10+ (API 29+), backups are written into the public
/// `Download/DebtBook/` MediaStore collection via a small native
/// platform channel, so the user can find and open them in the stock
/// Files app — no storage permission is needed for this, since apps
/// can freely insert into (and manage their own rows in) MediaStore's
/// Downloads collection. iOS is unaffected: it keeps using the app's
/// private documents directory, exactly as before.
class BackupService {
  static const _lastBackupKey = 'last_backup_date';
  static const _dueAfter = Duration(days: 1);
  static const _keepCount = 5;
  static const _fileNamePrefix = 'debtbook_backup_';
  static const _fileNameSuffix = '.json';
  static const _androidSubFolder = 'DebtBook';

  static const _channel = MethodChannel('debt_book/backup_storage');

  bool get _useMediaStore => Platform.isAndroid;

  Future<bool> _isBackupDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString(_lastBackupKey);

    if (lastBackupStr == null) {
      return true;
    }

    final lastBackup = DateTime.tryParse(lastBackupStr);
    if (lastBackup == null) {
      return true;
    }

    return DateTime.now().difference(lastBackup) > _dueAfter;
  }

  Future<void> _markBackupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  Map<String, dynamic> _buildBackupJson(List<CustomerModel> customers) {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'customersCount': customers.length,
      'totalDebt': customers.fold(0.0, (sum, c) => sum + c.balance),
      'customers': customers
          .map((c) => {
                'name': c.name,
                'balance': c.balance,
                'createdAt': c.createdAt.toIso8601String(),
                'updatedAt': c.updatedAt.toIso8601String(),
              })
          .toList(),
    };
  }

  String _buildBackupContent(List<CustomerModel> customers) {
    return const JsonEncoder.withIndent('  ')
        .convert(_buildBackupJson(customers));
  }

  String _generateFileName() {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return '$_fileNamePrefix${date}_$time$_fileNameSuffix';
  }

  /// Writes [content] into `Download/DebtBook/[fileName]` via MediaStore.
  /// Returns false (never throws) on anything other than Android 10+, or
  /// if the platform channel call fails for any reason — callers must
  /// fall back to a private-directory write in that case.
  Future<bool> _writeToMediaStore(String fileName, String content) async {
    if (!_useMediaStore) return false;
    try {
      final saved = await _channel.invokeMethod<bool>('saveToDownloads', {
        'fileName': fileName,
        'content': content,
        'subFolder': _androidSubFolder,
      });
      return saved ?? false;
    } catch (e) {
      debugPrint('BackupService: MediaStore save failed: $e');
      return false;
    }
  }

  /// Deletes all but the [_keepCount] most recent backups from the
  /// MediaStore Downloads collection. Non-fatal: failures are logged
  /// and swallowed. Only the rows this app created are ever visible to
  /// (and therefore deletable by) this query — no permission needed.
  Future<void> _cleanupMediaStore() async {
    if (!_useMediaStore) return;
    try {
      await _channel.invokeMethod('cleanupDownloads', {
        'prefix': _fileNamePrefix,
        'suffix': _fileNameSuffix,
        'subFolder': _androidSubFolder,
        'keepCount': _keepCount,
      });
    } catch (e) {
      debugPrint('BackupService: MediaStore cleanup failed: $e');
    }
  }

  Future<File> _writeLocalFile(
    String fileName,
    String content,
    Directory dir,
  ) async {
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content);
    return file;
  }

  bool _isBackupFile(String path) {
    final baseName = path.split(RegExp(r'[\\/]')).last;
    return baseName.startsWith(_fileNamePrefix) &&
        baseName.endsWith(_fileNameSuffix);
  }

  /// Deletes all but the [_keepCount] most recent backup files in [dir].
  /// Non-fatal: any failure is logged and swallowed.
  Future<void> _cleanupLocalBackups(Directory dir) async {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => _isBackupFile(f.path))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      if (files.length > _keepCount) {
        for (final file in files.skip(_keepCount)) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('BackupService: local cleanup failed: $e');
    }
  }

  /// Silently exports a backup if more than a day has passed since the
  /// last one (or none has ever run). On Android 10+ this writes
  /// straight into the public Download/DebtBook MediaStore folder; if
  /// that's unavailable (older Android, or the write failed) it falls
  /// back to the app's private documents directory, same as iOS always
  /// does. Never throws, never blocks the caller with a UI-visible
  /// failure — any error is just logged.
  Future<void> runAutomaticBackupIfDue(List<CustomerModel> customers) async {
    try {
      final due = await _isBackupDue();
      if (!due) return;

      final fileName = _generateFileName();
      final content = _buildBackupContent(customers);

      final savedToMediaStore = await _writeToMediaStore(fileName, content);
      if (savedToMediaStore) {
        await _cleanupMediaStore();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        await _writeLocalFile(fileName, content, dir);
        await _cleanupLocalBackups(dir);
      }

      await _markBackupDone();
    } catch (e) {
      debugPrint('BackupService: automatic backup failed: $e');
    }
  }

  /// Exports a backup on demand and returns a local [File] — the caller
  /// shares this via share_plus exactly as before. On Android 10+, the
  /// same content is also (best-effort) pushed into the public
  /// Download/DebtBook MediaStore folder, so it stays discoverable in
  /// the Files app even without re-sharing; the returned [File] itself
  /// lives in a temporary directory in that case, since it only exists
  /// to hand off to the share sheet. Throws on failure to write the
  /// returned file, so the caller (an explicit user action) can surface
  /// an error.
  Future<File> runManualBackup(List<CustomerModel> customers) async {
    final fileName = _generateFileName();
    final content = _buildBackupContent(customers);

    final dir = _useMediaStore
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final file = await _writeLocalFile(fileName, content, dir);

    final savedToMediaStore = await _writeToMediaStore(fileName, content);
    if (savedToMediaStore) {
      await _cleanupMediaStore();
    } else {
      await _cleanupLocalBackups(dir);
    }

    await _markBackupDone();
    return file;
  }
}

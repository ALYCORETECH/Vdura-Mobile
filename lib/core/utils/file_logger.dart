import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileLogger {
  static final FileLogger _instance = FileLogger._internal();
  factory FileLogger() => _instance;
  FileLogger._internal();

  // Strict cap: the log file never stays above 200MB.
  // When exceeded, the oldest part is dropped and the newest 100MB is kept.
  static const int _maxBytes = 200 * 1024 * 1024;
  static const int _keepBytes = 100 * 1024 * 1024;

  File? _logFile;
  bool _initialized = false;
  bool _trimming = false;
  Future<void>? _initFuture;
  final List<String> _pending = []; // logs written before init finished
  int _writes = 0;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/vanguarde_app_logs.txt');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      await _trimIfNeeded();
      await _deleteOldExports();

      _initialized = true;
      for (final line in _pending) {
        _append(line);
      }
      _pending.clear();
      i("FileLogger initialized at ${_logFile?.path}");
    } catch (e) {
      debugPrint("Failed to initialize FileLogger: $e");
    }
  }

  /// Keeps the newest 100MB when the file passes 200MB.
  Future<void> _trimIfNeeded() async {
    if (_trimming || _logFile == null) return;
    _trimming = true;
    try {
      final len = await _logFile!.length();
      if (len <= _maxBytes) return;

      final tmp = File('${_logFile!.path}.tmp');
      final sink = tmp.openWrite();
      sink.write('--- older logs trimmed (size limit) ---\n');
      await sink.addStream(_logFile!.openRead(len - _keepBytes));
      await sink.flush();
      await sink.close();
      await tmp.rename(_logFile!.path);
    } catch (e) {
      debugPrint('FileLogger trim error: $e');
    } finally {
      _trimming = false;
    }
  }

  void _append(String text) {
    try {
      _logFile!.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('FileLogger write error: $e');
    }
  }

  void _write(String prefix, String message) {
    debugPrint('$prefix $message');

    final timestamp = DateTime.now().toIso8601String();
    final text = '[$timestamp] $prefix $message\n';

    if (!_initialized || _logFile == null) {
      if (_pending.length < 500) _pending.add(text);
      return;
    }

    _append(text);
    if (++_writes % 200 == 0) _trimIfNeeded();
  }

  void d(String message) => _write('[DEBUG]', message);
  void i(String message) => _write('[INFO]', message);
  void w(String message) => _write('[WARN]', message);

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    String fullMessage = message;
    if (error != null) fullMessage += ' | Error: $error';
    if (stackTrace != null) fullMessage += ' | Trace: $stackTrace';
    _write('[ERROR]', fullMessage);
  }

  /// Deletes exports older than 24h. Called only on app start, never while
  /// sharing, so a share target (e.g. WhatsApp) never loses a file it is
  /// still holding a link to.
  Future<void> _deleteOldExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      await for (final entity in tempDir.list()) {
        if (entity is File &&
            entity.uri.pathSegments.last.startsWith('vanguarde_logs_')) {
          try {
            if ((await entity.lastModified()).isBefore(cutoff)) {
              await entity.delete();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Shares the logs. Does NOT delete anything.
  /// Returns the number of bytes exported (pass it to [clearExported] once the
  /// user confirms the share worked), or null if nothing was shared.
  Future<int?> shareLogs() async {
    if (_logFile == null || !await _logFile!.exists()) {
      debugPrint("No log file found to share.");
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();

      // Unique, filesystem-safe name: vanguarde_logs_20261024_123000.txt
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
      final exportFile = File('${tempDir.path}/vanguarde_logs_$stamp.txt');

      // Only this many bytes are exported (and later cleared)
      final snapshotLen = await _logFile!.length();

      // Stream disk to disk, no large strings in memory
      final sink = exportFile.openWrite();
      if (snapshotLen > 0) {
        await sink.addStream(_logFile!.openRead(0, snapshotLen));
      } else {
        sink.write('No logs recorded yet.\n');
      }
      await sink.flush();
      await sink.close();

      final result = await Share.shareXFiles(
        // Not 'text/plain': WhatsApp can treat text/plain shares as a text
        // message and ignore the attached file. As a generic binary file it
        // is always attached as a document.
        [XFile(exportFile.path, mimeType: 'application/octet-stream')],
      );

      if (result.status == ShareResultStatus.dismissed) return null;
      return snapshotLen;
    } catch (err, st) {
      debugPrint('Error sharing logs: $err\n$st');
      return null;
    }
  }

  /// Call only after the user confirms the share worked.
  /// Removes the exported bytes and keeps anything logged since.
  Future<void> clearExported(int snapshotLen) async {
    try {
      if (_logFile == null) return;
      final currentLen = await _logFile!.length();
      if (currentLen <= snapshotLen) {
        await _logFile!.writeAsString('', flush: true);
        return;
      }
      final tmp = File('${_logFile!.path}.tmp');
      final sink = tmp.openWrite();
      await sink.addStream(_logFile!.openRead(snapshotLen));
      await sink.flush();
      await sink.close();
      await tmp.rename(_logFile!.path);
      i('Logs cleared after confirmed share ($snapshotLen bytes)');
    } catch (err) {
      debugPrint('FileLogger clear error: $err');
    }
  }
}

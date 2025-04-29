import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;

  static const String _logFileName = 'app_logs.txt';
  static const int _maxLogFiles = 7; // Keep last 7 days of logs
  static const int _maxFileSize = 2 * 1024 * 1024; // 2MB per file

  File? _logFile;
  final _lock = Lock(); // For thread-safe file operations
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  Logger._internal() {
    _init();
  }

  Future<void> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/$_logFileName');

    // Rotate logs if file is too large
    if (await _logFile?.exists() ?? false) {
      final length = await _logFile?.length() ?? 0;
      if (length > _maxFileSize) {
        await _rotateLogs();
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (!(await _logFile?.exists() ?? false)) {
      await _init();
    }
  }

  Future<void> _rotateLogs() async {
    final directory = await getApplicationDocumentsDirectory();
    final oldLogs = Directory('${directory.path}/logs');

    if (!await oldLogs.exists()) {
      await oldLogs.create();
    }

    // Archive current log
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await _logFile?.copy('${oldLogs.path}/log_$timestamp.txt');

    // Clear current log
    await _logFile?.writeAsString('');

    // Clean up old logs
    final logFiles = await oldLogs.list().toList();
    if (logFiles.length > _maxLogFiles) {
      logFiles.sort((a, b) => b.path.compareTo(a.path));
      for (var i = _maxLogFiles; i < logFiles.length; i++) {
        await logFiles[i].delete();
      }
    }
  }

  Future<void> log(
    String message, {
    dynamic data,
    LogLevel level = LogLevel.info,
    bool printToConsole = true,
    bool saveToFile = true,
  }) async {
    try {
      await _ensureInitialized();
      final timestamp = _dateFormat.format(DateTime.now());
      final levelStr = level.toString().split('.').last.toUpperCase();
      final dataStr = data != null ? '\nDATA: $data' : '';
      final logEntry = '[$timestamp] [$levelStr] $message$dataStr\n';

      if (printToConsole) {
        _printColored(level, logEntry);
      }

      if (saveToFile) {
        await _lock.synchronized(() async {
          await _logFile?.writeAsString(logEntry, mode: FileMode.append);
        });
      }
    } catch (e) {
      print('⚠️ Logger error: $e');
    }
  }

  void _printColored(LogLevel level, String message) {
    const ansiReset = '\x1B[0m';
    const ansiRed = '\x1B[31m';
    const ansiYellow = '\x1B[33m';
    const ansiBlue = '\x1B[34m';

    switch (level) {
      case LogLevel.error:
        print('$ansiRed$message$ansiReset');
        break;
      case LogLevel.warning:
        print('$ansiYellow$message$ansiReset');
        break;
      case LogLevel.info:
        print('$ansiBlue$message$ansiReset');
        break;
      default:
        print(message);
    }
  }

  Future<String> getLogs() async {
    try {
      await _ensureInitialized();

      return await _logFile?.readAsString() ?? '';
    } catch (e) {
      return 'No logs available';
    }
  }

  Future<void> clearLogs() async {
    await _ensureInitialized();

    await _lock.synchronized(() async {
      await _logFile?.writeAsString('');
    });
  }

  Future<String> exportLogs() async {
    await _ensureInitialized();

    final directory =
        await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final exportFile = File(
        '${directory!.path}/exported_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
    await exportFile.writeAsString(await getLogs());
    return exportFile.path;
  }
}

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

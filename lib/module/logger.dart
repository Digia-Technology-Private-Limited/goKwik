import 'package:flutter/services.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;

  static const MethodChannel _channel = MethodChannel('logger');

  Logger._internal();

  Future<bool> log(String? message, String? jsonString) async {
    try {
      final result = await _channel.invokeMethod<bool>('log', {
        'message': message,
        'json': jsonString,
      });
      return result ?? true;
    } catch (e) {
      print('LoggerService.log error: $e');
      return true; // fallback
    }
  }

  Future<String> getLogFilePath() async {
    try {
      final path = await _channel.invokeMethod<String>('getLogFilePath');
      return path ?? '';
    } catch (e) {
      print('LoggerService.getLogFilePath error: $e');
      return '';
    }
  }

  Future<bool> clearLogs() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearLogs');
      return result ?? true;
    } catch (e) {
      print('LoggerService.clearLogs error: $e');
      return true;
    }
  }

  Future<String> downloadLogs() async {
    try {
      final path = await _channel.invokeMethod<String>('downloadLogs');
      return path ?? '';
    } catch (e) {
      print('LoggerService.downloadLogs error: $e');
      return '';
    }
  }
}

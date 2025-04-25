import 'package:gokwik/module/logger.dart';

Future<String> logsDownloader() {
  return Logger().downloadLogs();
}

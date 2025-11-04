import 'dart:io';

import 'get_base_path.dart';

Future<File> getLogFile() async {
  final logFileDir = await getGitExpDocumentsPath();
  final String logFilePath =
      '$logFileDir${Platform.pathSeparator}git_explorer.log';
  final logFile = File(logFilePath);
  if (!logFile.existsSync()) {
    logFile.createSync();
  }
  return logFile;
}
